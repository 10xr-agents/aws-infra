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

# ALB Outputs
output "alb_id" {
  description = "The ID of the ALB"
  value       = module.ecs.alb_id
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = module.ecs.alb_arn
}

output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = module.ecs.alb_dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the ALB"
  value       = module.ecs.alb_zone_id
}

output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = module.ecs.alb_security_group_id
}

output "alb_listener_arns" {
  description = "Map of listener ARNs"
  value       = module.ecs.alb_listeners
}

output "alb_target_groups" {
  description = "Map of target groups created for services"
  value       = module.ecs.alb_target_groups
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

output "ecs_services" {
  description = "Map of ECS services created"
  value       = module.ecs.services
}

output "ecs_service_urls" {
  description = "Map of service URLs via ALB"
  value = {
    for name, config in local.ecs_services_with_overrides : name => {
      internal_url = var.enable_service_discovery ? "http://${name}.${local.cluster_name}.local:${config.port}" : null
      external_url = "http${var.acm_certificate_arn != "" ? "s" : ""}://${module.ecs.alb_dns_name}${lookup(config, "alb_path_patterns", ["/"])[0]}"
      paths        = lookup(config, "alb_path_patterns", ["/${name}/*"])
    }
  }
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