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