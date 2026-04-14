variable "project_id" { type = string }
variable "region" { type = string }
variable "zone" { type = string }
variable "cluster_name" { type = string }
variable "gpu_type" { type = string }
variable "gpus_per_node" { type = number }
variable "gpu_machine_type" { type = string }
variable "max_gpu_nodes" { type = number }
variable "use_spot" { type = bool }
variable "service_account_email" { type = string }

# GPU node pool — autoscales from 0 to max_gpu_nodes
resource "google_container_node_pool" "gpu_pool" {
  name     = "gpu-pool"
  project  = var.project_id
  location = var.region
  cluster  = var.cluster_name

  # Start with 0 nodes — autoscaler will add them when jobs are submitted
  initial_node_count = 0

  autoscaling {
    min_node_count = 0
    max_node_count = var.max_gpu_nodes
  }

  # Pin to a specific zone (GPU availability varies by zone)
  node_locations = [var.zone]

  node_config {
    machine_type    = var.gpu_machine_type
    service_account = var.service_account_email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    # GPU configuration
    guest_accelerator {
      type  = var.gpu_type
      count = var.gpus_per_node

      gpu_driver_installation_config {
        gpu_driver_version = "LATEST"
      }
    }

    # Use spot instances for 60-70% cost savings
    spot = var.use_spot

    # Taint GPU nodes so only GPU workloads get scheduled here
    # (prevents random system pods from triggering expensive GPU node creation)
    taint {
      key    = "nvidia.com/gpu"
      value  = "present"
      effect = "NO_SCHEDULE"
    }

    labels = {
      role     = "gpu-worker"
      gpu-type = var.gpu_type
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Larger boot disk for the ~30GB NeMo-RL container image
    disk_size_gb = 200
    disk_type    = "pd-ssd"

    # Shared memory for PyTorch DataLoader workers and NCCL
    # /dev/shm is mounted as a tmpfs inside containers
    # GKE handles this via the machine's RAM
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Don't wait for GPU nodes on initial apply (they start at 0)
  lifecycle {
    ignore_changes = [initial_node_count]
  }
}

output "gpu_pool_name" { value = google_container_node_pool.gpu_pool.name }
