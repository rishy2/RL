variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the cluster"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for GPU nodes"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "nemo-rl"
}

variable "gpu_type" {
  description = "GPU accelerator type"
  type        = string
  default     = "nvidia-tesla-a100"
  validation {
    condition     = contains(["nvidia-tesla-a100", "nvidia-a100-80gb", "nvidia-h100-80gb"], var.gpu_type)
    error_message = "gpu_type must be one of: nvidia-tesla-a100, nvidia-a100-80gb, nvidia-h100-80gb"
  }
}

variable "gpus_per_node" {
  description = "Number of GPUs per node"
  type        = number
  default     = 8
}

variable "gpu_machine_type" {
  description = "Machine type for GPU nodes. Must match gpu_type."
  type        = string
  default     = "a2-ultragpu-8g"
}

variable "max_gpu_nodes" {
  description = "Maximum number of GPU nodes the autoscaler can create"
  type        = number
  default     = 4
}

variable "use_spot" {
  description = "Use spot/preemptible instances for GPU nodes (60-70% cheaper, can be interrupted)"
  type        = bool
  default     = true
}

variable "filestore_capacity_gb" {
  description = "Filestore instance capacity in GB (for datasets)"
  type        = number
  default     = 1024
}

variable "gcs_checkpoint_bucket" {
  description = "GCS bucket name for model checkpoints. Must be globally unique."
  type        = string
  default     = ""
}
