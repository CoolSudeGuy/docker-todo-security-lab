output "cluster_name" {
  description = "Name of the Amazon EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Amazon EKS API endpoint."
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "region" {
  description = "AWS deployment region."
  value       = var.aws_region
}

output "configure_kubectl" {
  description = "Command used to configure kubectl."

  value = join(" ", [
    "aws eks update-kubeconfig",
    "--region",
    var.aws_region,
    "--name",
    module.eks.cluster_name
  ])
}
