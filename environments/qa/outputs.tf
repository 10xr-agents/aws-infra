# environments/qa/outputs.tf

# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

# ECS Cluster outputs
output "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.ecs.task_execution_role_arn
}

output "ecs_capacity_providers" {
  description = "List of capacity providers associated with the cluster"
  value       = module.ecs.capacity_providers
}

# EKS Cluster outputs
output "eks_cluster_id" {
  description = "The ID of the EKS cluster"
  value       = var.enable_eks ? module.eks[0].cluster_id : null
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = var.enable_eks ? module.eks[0].cluster_arn : null
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = var.enable_eks ? module.eks[0].cluster_name : null
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = var.enable_eks ? module.eks[0].cluster_endpoint : null
}

output "eks_cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = var.enable_eks ? module.eks[0].cluster_version : null
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = var.enable_eks ? module.eks[0].cluster_certificate_authority_data : null
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = var.enable_eks ? module.eks[0].cluster_security_group_id : null
}

output "eks_node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = var.enable_eks ? module.eks[0].node_group_arn : null
}

output "eks_node_group_status" {
  description = "Status of the EKS Node Group"
  value       = var.enable_eks ? module.eks[0].node_group_status : null
}

output "eks_cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = var.enable_eks ? module.eks[0].cluster_oidc_issuer_url : null
}

# ALB outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.alb_zone_id
}

output "alb_security_group_id" {
  description = "Security group ID of the Application Load Balancer"
  value       = module.alb.alb_security_group_id
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = module.alb.http_listener_arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (if certificate is provided)"
  value       = module.alb.https_listener_arn
}

output "default_target_group_arn" {
  description = "ARN of the default target group"
  value       = module.alb.default_target_group_arn
}

# Service Discovery
output "service_discovery_namespace_id" {
  description = "ID of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.id
}

output "service_discovery_namespace_arn" {
  description = "ARN of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.arn
}

output "service_discovery_namespace_name" {
  description = "Name of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.name
}

# Storage outputs
output "efs_id" {
  description = "ID of the EFS file system"
  value       = module.storage.efs_id
}

output "efs_dns_name" {
  description = "DNS name of the EFS file system"
  value       = module.storage.efs_dns_name
}

output "livekit_access_point_id" {
  description = "ID of the LiveKit EFS access point"
  value       = module.storage.livekit_access_point_id
}

output "recordings_bucket_name" {
  description = "Name of the S3 bucket for recordings"
  value       = module.storage.recordings_bucket_name
}

output "recordings_bucket_arn" {
  description = "ARN of the S3 bucket for recordings"
  value       = module.storage.recordings_bucket_arn
}

output "storage_task_role_arn" {
  description = "ARN of the IAM role for ECS tasks to access storage"
  value       = module.storage.task_role_arn
}

# Conversation Agent outputs
output "conversation_agent_service_name" {
  description = "Name of the conversation agent ECS service"
  value       = module.conversation_agent.service_name
}

output "conversation_agent_service_arn" {
  description = "ARN of the conversation agent ECS service"
  value       = module.conversation_agent.service_arn
}

output "conversation_agent_task_definition_arn" {
  description = "ARN of the conversation agent task definition"
  value       = module.conversation_agent.task_definition_arn
}

output "conversation_agent_target_group_arn" {
  description = "ARN of the conversation agent target group"
  value       = module.conversation_agent.target_group_arn
}

output "conversation_agent_security_group_id" {
  description = "ID of the conversation agent security group"
  value       = module.conversation_agent.security_group_id
}

output "conversation_agent_cloudwatch_log_group_name" {
  description = "Name of the conversation agent CloudWatch log group"
  value       = module.conversation_agent.cloudwatch_log_group_name
}

output "conversation_agent_service_discovery_service_name" {
  description = "Name of the conversation agent service discovery service"
  value       = module.conversation_agent.service_discovery_service_name
}

# Access URLs
output "conversation_agent_url" {
  description = "URL to access the conversation agent service"
  value       = "http://${module.alb.alb_dns_name}/conversation/"
}

output "conversation_agent_internal_url" {
  description = "Internal service discovery URL for the conversation agent"
  value       = module.conversation_agent.service_discovery_service_name != null ? "http://conversation-agent.${aws_service_discovery_private_dns_namespace.main.name}:${var.conversation_agent_port}" : null
}

# Kubectl configuration command (for EKS)
output "kubectl_config_command" {
  description = "Command to configure kubectl for EKS cluster"
  value       = var.enable_eks ? "aws eks update-kubeconfig --region ${var.region} --name ${module.eks[0].cluster_name}" : null
}