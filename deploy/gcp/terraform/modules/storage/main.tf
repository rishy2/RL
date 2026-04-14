variable "project_id" { type = string }
variable "region" { type = string }
variable "zone" { type = string }
variable "cluster_name" { type = string }
variable "filestore_capacity_gb" { type = number }
variable "gcs_checkpoint_bucket" { type = string }

# GCS bucket for model checkpoints
resource "google_storage_bucket" "checkpoints" {
  name     = var.gcs_checkpoint_bucket != "" ? var.gcs_checkpoint_bucket : "${var.cluster_name}-checkpoints-${var.project_id}"
  project  = var.project_id
  location = var.region

  # Auto-delete old checkpoints after 30 days to save storage costs
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  # Prevent accidental deletion
  force_destroy = false

  uniform_bucket_level_access = true
}

# Filestore instance for shared dataset storage (NFS)
# All GPU nodes mount this simultaneously for fast data loading
resource "google_filestore_instance" "datasets" {
  name     = "${var.cluster_name}-datasets"
  project  = var.project_id
  location = var.zone
  tier     = "BASIC_HDD"

  file_shares {
    name        = "datasets"
    capacity_gb = var.filestore_capacity_gb
  }

  networks {
    network = "${var.cluster_name}-vpc"
    modes   = ["MODE_IPV4"]
  }
}

output "checkpoint_bucket_name" { value = google_storage_bucket.checkpoints.name }
output "filestore_ip" { value = google_filestore_instance.datasets.networks[0].ip_addresses[0] }
output "filestore_share" { value = google_filestore_instance.datasets.file_shares[0].name }
