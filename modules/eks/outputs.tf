# modules/eks/outputs.tf

output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_ca_certificate" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "node_groups" {
  description = "Map of node groups created and their attributes"
  value       = aws_eks_node_group.main
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if `enable_irsa = true`"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

# Output the name of the created key pair
output "eks_nodes_key_pair_name" {
  value       = aws_key_pair.eks_nodes.key_name
  description = "Name of the EKS nodes SSH key pair"
}

# Output the secret ARN where the private key is stored
output "eks_nodes_ssh_private_key_secret_arn" {
  value       = aws_secretsmanager_secret.eks_nodes_ssh_key.arn
  description = "ARN of the secret containing the EKS nodes SSH private key"
}