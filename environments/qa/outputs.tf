# environments/qa/outputs.tf

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

# Voice Agent outputs
output "voice_agent_service_name" {
  description = "Name of the voice agent ECS service"
  value       = module.services.voice_agent_service_name
}

output "voice_agent_service_arn" {
  description = "ARN of the voice agent ECS service"
  value       = module.services.voice_agent_service_arn
}

output "voice_agent_task_definition_arn" {
  description = "ARN of the voice agent task definition"
  value       = module.services.voice_agent_task_definition_arn
}

output "voice_agent_target_group_arn" {
  description = "ARN of the voice agent target group"
  value       = module.services.voice_agent_target_group_arn
}

output "voice_agent_security_group_id" {
  description = "ID of the voice agent security group"
  value       = module.services.voice_agent_security_group_id
}

output "voice_agent_cloudwatch_log_group_name" {
  description = "Name of the voice agent CloudWatch log group"
  value       = module.services.voice_agent_cloudwatch_log_group_name
}

output "voice_agent_service_discovery_service_name" {
  description = "Name of the voice agent service discovery service"
  value       = module.services.voice_agent_service_discovery_service_name
}

# LiveKit Proxy outputs
output "livekit_proxy_service_name" {
  description = "Name of the LiveKit proxy ECS service"
  value       = module.services.livekit_proxy_service_name
}

output "livekit_proxy_service_arn" {
  description = "ARN of the LiveKit proxy ECS service"
  value       = module.services.livekit_proxy_service_arn
}

output "livekit_proxy_task_definition_arn" {
  description = "ARN of the LiveKit proxy task definition"
  value       = module.services.livekit_proxy_task_definition_arn
}

output "livekit_proxy_target_group_arn" {
  description = "ARN of the LiveKit proxy target group"
  value       = module.services.livekit_proxy_target_group_arn
}

output "livekit_proxy_security_group_id" {
  description = "ID of the LiveKit proxy security group"
  value       = module.services.livekit_proxy_security_group_id
}

output "livekit_proxy_cloudwatch_log_group_name" {
  description = "Name of the LiveKit proxy CloudWatch log group"
  value       = module.services.livekit_proxy_cloudwatch_log_group_name
}

output "livekit_proxy_service_discovery_service_name" {
  description = "Name of the LiveKit proxy service discovery service"
  value       = module.services.livekit_proxy_service_discovery_service_name
}

# Access URLs
output "voice_agent_url" {
  description = "URL to access the voice agent service"
  value       = "http://${module.alb.alb_dns_name}/voice/"
}

output "voice_agent_internal_url" {
  description = "Internal service discovery URL for the voice agent"
  value       = module.services.voice_agent_service_discovery_service_name != null ? "http://voice-agent.${aws_service_discovery_private_dns_namespace.main.name}:${var.voice_agent_port}" : null
}

output "livekit_proxy_url" {
  description = "URL to access the LiveKit proxy service"
  value       = "http://${module.alb.alb_dns_name}/proxy/"
}

output "livekit_proxy_internal_url" {
  description = "Internal service discovery URL for the LiveKit proxy"
  value       = module.services.livekit_proxy_service_discovery_service_name != null ? "http://livekit-proxy.${aws_service_discovery_private_dns_namespace.main.name}:${var.livekit_proxy_port}" : null
}

output "livekit_proxy_internal_url" {
  description = "Internal service discovery URL for the LiveKit proxy"
  value       = module.services.livekit_proxy_service_discovery_service_name != null ? "http://livekit-proxy.${aws_service_discovery_private_dns_namespace.main.name}:${var.livekit_proxy_port}" : null
}

# MongoDB outputs
output "mongodb_instance_ids" {
  description = "IDs of the MongoDB EC2 instances"
  value       = module.mongodb.instance_ids
}

output "mongodb_endpoints" {
  description = "List of MongoDB endpoints (ip:port)"
  value       = module.mongodb.endpoints
}

output "mongodb_connection_string" {
  description = "MongoDB connection string"
  value       = module.mongodb.connection_string
  sensitive   = true
}

output "mongodb_srv_connection_string" {
  description = "MongoDB SRV connection string (if DNS is enabled)"
  value       = module.mongodb.srv_connection_string
  sensitive   = true
}

output "mongodb_replica_set_name" {
  description = "Name of the MongoDB replica set"
  value       = module.mongodb.replica_set_name
}

output "mongodb_primary_endpoint" {
  description = "Primary MongoDB endpoint"
  value       = module.mongodb.primary_endpoint
}

output "mongodb_security_group_id" {
  description = "ID of the MongoDB security group"
  value       = module.mongodb.security_group_id
}

output "mongodb_ssm_parameter_name" {
  description = "Name of the SSM parameter containing the MongoDB connection string"
  value       = module.mongodb.ssm_parameter_name
}

output "mongodb_dns_records" {
  description = "Map of DNS records for MongoDB nodes"
  value       = module.mongodb.dns_records
}

output "mongodb_cluster_details" {
  description = "Detailed information about the MongoDB cluster"
  value       = module.mongodb.cluster_details
}