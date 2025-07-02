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
  value       = module.ecs.alb_listener_arns
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

# Add these Redis outputs to your environments/qa/outputs.tf

# Redis outputs
output "redis_port" {
  description = "Redis port"
  value       = module.redis.redis_port
}

output "redis_connection_string" {
  description = "Redis connection string"
  value       = module.redis.redis_connection_string
  sensitive   = true
}

output "redis_auth_token" {
  description = "Redis AUTH token"
  value       = module.redis.redis_auth_token
  sensitive   = true
}

output "redis_security_group_id" {
  description = "ID of the Redis security group"
  value       = module.redis.redis_security_group_id
}

output "redis_ssm_parameters" {
  description = "SSM parameter names for Redis connection details"
  value = {
    endpoint          = module.redis.ssm_parameter_redis_endpoint
    port             = module.redis.ssm_parameter_redis_port
    auth_token       = module.redis.ssm_parameter_redis_auth_token
    connection_string = module.redis.ssm_parameter_redis_connection_string
  }
}

# Add these outputs to your environments/qa/outputs.tf

################################################################################
# Global Accelerator Outputs
################################################################################

output "global_accelerator_dns_name" {
  description = "DNS name of the Global Accelerator"
  value       = var.create_global_accelerator ? module.global_accelerator[0].accelerator_dns_name : null
}

output "global_accelerator_static_ips" {
  description = "Static IP addresses of the Global Accelerator"
  value       = var.create_global_accelerator ? module.global_accelerator[0].static_ip_addresses_flat : []
}

output "global_accelerator_id" {
  description = "ID of the Global Accelerator"
  value       = var.create_global_accelerator ? module.global_accelerator[0].accelerator_id : null
}

output "global_accelerator_configuration" {
  description = "Global Accelerator configuration summary"
  value = var.create_global_accelerator ? module.global_accelerator[0].accelerator_configuration : {
    dns_name                = null
    ip_address_type         = null
    enabled                 = false
    static_ips              = []
    flow_logs_enabled       = false
    flow_logs_bucket        = null
    listener_protocol       = null
    listener_client_affinity = null
    endpoint_count          = 0
    health_check_protocol   = null
    health_check_path       = null
  }
}
output "global_accelerator_connection_info" {
  description = "Global Accelerator connection information"
  value = var.create_global_accelerator ? module.global_accelerator[0].accelerator_connection_info : null
}

output "global_accelerator_flow_logs_bucket" {
  description = "S3 bucket for Global Accelerator flow logs"
  value       = var.create_global_accelerator ? module.global_accelerator[0].flow_logs_bucket_id : null
}

################################################################################
# Cloudflare Outputs
################################################################################

output "cloudflare_dns_records" {
  description = "Summary of Cloudflare DNS records created"
  value = var.create_cloudflare_dns_records ? module.cloudflare[0].dns_records_summary : null
}

output "cloudflare_urls" {
  description = "Application URLs via Cloudflare"
  value = var.create_cloudflare_dns_records ? module.cloudflare.custom_dns_record_urls : {}
}

output "cloudflare_configuration" {
  description = "Cloudflare configuration summary"
  value       = var.create_cloudflare_dns_records ? module.cloudflare[0].cloudflare_configuration : {}
}

################################################################################
# Application URLs Summary
################################################################################

output "application_urls" {
  description = "Complete summary of application access URLs"
  value = {
    # Direct ALB access
    alb_dns_name = module.ecs.alb_dns_name
    alb_http_url = "http://${module.ecs.alb_dns_name}"
    alb_https_url = var.acm_certificate_arn != "" ? "https://${module.ecs.alb_dns_name}" : null

    # Global Accelerator access (if enabled)
    global_accelerator_dns_name = var.create_global_accelerator ? module.global_accelerator[0].accelerator_dns_name : null
    global_accelerator_http_url = var.create_global_accelerator ? "http://${module.global_accelerator[0].accelerator_dns_name}" : null
    global_accelerator_https_url = var.create_global_accelerator ? "https://${module.global_accelerator[0].accelerator_dns_name}" : null
    global_accelerator_static_ips = var.create_global_accelerator ? module.global_accelerator[0].static_ip_addresses_flat : []

    # Primary URLs (recommended for users)
    primary_app_url = var.create_cloudflare_dns_records ? module.cloudflare[0].custom_dns_record_urls[0].https_url : (
      var.create_global_accelerator ? "https://${module.global_accelerator[0].accelerator_dns_name}" : (
      var.acm_certificate_arn != "" ? "https://${module.ecs.alb_dns_name}" : "http://${module.ecs.alb_dns_name}"
    )
    )
    primary_api_url = var.create_cloudflare_dns_records ? module.cloudflare[0].custom_dns_record_urls[1].https_url : (
      var.create_global_accelerator ? "https://${module.global_accelerator[0].accelerator_dns_name}" : (
      var.acm_certificate_arn != "" ? "https://${module.ecs.alb_dns_name}" : "http://${module.ecs.alb_dns_name}"
    )
    )
  }
}