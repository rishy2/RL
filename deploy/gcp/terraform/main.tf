terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required GCP APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com", # GKE
    "compute.googleapis.com",   # Compute Engine (VMs, GPUs)
    "file.googleapis.com",      # Filestore
    "storage.googleapis.com",   # GCS
    "iam.googleapis.com",       # IAM
  ])

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}

# 1. IAM — service accounts and permissions (created first, used by other modules)
module "iam" {
  source = "./modules/iam"

  project_id             = var.project_id
  cluster_name           = var.cluster_name
  checkpoint_bucket_name = module.storage.checkpoint_bucket_name

  depends_on = [google_project_service.apis]
}

# 2. Networking — VPC, subnet, firewall for NCCL, Cloud NAT
module "network" {
  source = "./modules/network"

  project_id   = var.project_id
  region       = var.region
  cluster_name = var.cluster_name

  depends_on = [google_project_service.apis]
}

# 3. Storage — GCS bucket for checkpoints, Filestore for datasets
module "storage" {
  source = "./modules/storage"

  project_id            = var.project_id
  region                = var.region
  zone                  = var.zone
  cluster_name          = var.cluster_name
  filestore_capacity_gb = var.filestore_capacity_gb
  gcs_checkpoint_bucket = var.gcs_checkpoint_bucket

  depends_on = [module.network]
}

# 4. GKE cluster — the Kubernetes control plane + CPU node pool
module "gke_cluster" {
  source = "./modules/gke-cluster"

  project_id            = var.project_id
  region                = var.region
  cluster_name          = var.cluster_name
  vpc_id                = module.network.vpc_id
  subnet_name           = module.network.subnet_name
  service_account_email = module.iam.service_account_email

  depends_on = [module.network, module.iam]
}

# 5. GPU node pool — A100/H100 machines that autoscale 0 to N
module "gpu_nodepool" {
  source = "./modules/gpu-nodepool"

  project_id            = var.project_id
  region                = var.region
  zone                  = var.zone
  cluster_name          = module.gke_cluster.cluster_name
  gpu_type              = var.gpu_type
  gpus_per_node         = var.gpus_per_node
  gpu_machine_type      = var.gpu_machine_type
  max_gpu_nodes         = var.max_gpu_nodes
  use_spot              = var.use_spot
  service_account_email = module.iam.service_account_email

  depends_on = [module.gke_cluster]
}
