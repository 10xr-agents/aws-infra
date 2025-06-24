# environments/nonprod/outputs.tf

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

# NLB outputs for TURN
output "turn_nlb_dns_name" {
  description = "DNS name of the TURN Network Load Balancer"
  value       = module.nlb.turn_nlb_dns_name
}

output "turn_nlb_arn" {
  description = "ARN of the TURN Network Load Balancer"
  value       = module.nlb.turn_nlb_arn
}

output "turn_target_group_arns" {
  description = "Map of TURN target group ARNs"
  value       = module.nlb.turn_target_group_arns
}

# NLB outputs for SIP
output "sip_nlb_dns_name" {
  description = "DNS name of the SIP Network Load Balancer"
  value       = module.nlb.sip_nlb_dns_name
}

output "sip_nlb_arn" {
  description = "ARN of the SIP Network Load Balancer"
  value       = module.nlb.sip_nlb_arn
}

output "sip_signaling_target_group_arn" {
  description = "ARN of the SIP signaling target group"
  value       = module.nlb.sip_signaling_target_group_arn
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