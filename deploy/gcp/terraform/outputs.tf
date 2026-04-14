output "cluster_name" {
  description = "GKE cluster name"
  value       = module.gke_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "GKE cluster API endpoint"
  value       = module.gke_cluster.cluster_endpoint
  sensitive   = true
}

output "checkpoint_bucket" {
  description = "GCS bucket for model checkpoints"
  value       = module.storage.checkpoint_bucket_name
}

output "filestore_ip" {
  description = "Filestore NFS IP address"
  value       = module.storage.filestore_ip
}

output "gpu_pool_name" {
  description = "GPU node pool name"
  value       = module.gpu_nodepool.gpu_pool_name
}

output "connect_command" {
  description = "Run this to configure kubectl"
  value       = "gcloud container clusters get-credentials ${module.gke_cluster.cluster_name} --region ${var.region} --project ${var.project_id}"
}
