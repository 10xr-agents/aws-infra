# outputs.tf

# EKS Outputs
output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "eks_oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_arn
}

# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

# S3 Bucket Output (assuming you have an S3 module)
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3.bucket_id
}

# ALB Output (assuming you have a networking module with ALB)
output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.networking.alb_dns_name
}

# Global Accelerator Output
# output "global_accelerator_ips" {
#   description = "The static IP addresses of the Global Accelerator"
#   value       = module.networking.global_accelerator_ips
# }

# Output the name of the created key pair
output "eks_nodes_key_pair_name" {
  value       = module.eks.eks_nodes_key_pair_name
  description = "Name of the EKS nodes SSH key pair"
}

# Output the secret ARN where the private key is stored
output "eks_nodes_ssh_private_key_secret_arn" {
  value       = module.eks.eks_nodes_ssh_private_key_secret_arn
  description = "ARN of the secret containing the EKS nodes SSH private key"
}