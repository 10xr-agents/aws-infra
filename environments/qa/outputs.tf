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
      external_url = "http${local.acm_certificate_arn != "" ? "s" : ""}://${module.ecs.alb_dns_name}${try(config.alb_path_patterns[0], "/")}"
      paths        = try(config.alb_path_patterns, ["/${name}/*"])
    }
  }
}

################################################################################
# Networking Module Outputs
################################################################################

output "nlb_arn" {
  description = "ARN of the Network Load Balancer"
  value       = module.networking.nlb_arn
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = module.networking.nlb_dns_name
}

output "nlb_zone_id" {
  description = "Hosted zone ID of the Network Load Balancer"
  value       = module.networking.nlb_zone_id
}

output "nlb_connection_info" {
  description = "NLB connection information"
  value       = module.networking.nlb_connection_info
}

output "nlb_target_groups" {
  description = "NLB target groups"
  value       = module.networking.target_groups
}

output "nlb_listeners" {
  description = "NLB listeners"
  value       = module.networking.listeners
}

output "nlb_http_target_group_arn" {
  description = "ARN of the HTTP target group"
  value       = module.networking.http_target_group_arn
}

output "nlb_https_target_group_arn" {
  description = "ARN of the HTTPS target group"
  value       = module.networking.https_target_group_arn
}

output "nlb_security_group_id" {
  description = "ID of the NLB security group (if created)"
  value       = module.networking.security_group_id
}

output "nlb_s3_buckets" {
  description = "Information about NLB S3 buckets for logs"
  value       = module.networking.s3_buckets
}

output "nlb_access_logs_bucket" {
  description = "S3 bucket for NLB access logs"
  value       = module.networking.access_logs_bucket_id
}

output "nlb_connection_logs_bucket" {
  description = "S3 bucket for NLB connection logs"
  value       = module.networking.connection_logs_bucket_id
}

################################################################################
# Network Architecture Summary
################################################################################

output "network_architecture" {
  description = "Summary of the network architecture"
  value = {
    # Infrastructure Components
    vpc_id = module.vpc.vpc_id
    vpc_cidr = module.vpc.vpc_cidr_block

    # Load Balancers
    internal_alb = {
      dns_name = module.ecs.alb_dns_name
      zone_id  = module.ecs.alb_zone_id
      internal = true
    }

    external_nlb = {
      dns_name = module.networking.nlb_dns_name
      zone_id  = module.networking.nlb_zone_id
      internal = var.nlb_internal
    }

    # SSL/TLS Configuration
    ssl_config = {
      alb_https_enabled = local.acm_certificate_arn != ""
      nlb_https_protocol = var.https_listener_protocol
      ssl_termination_point = var.https_listener_protocol == "TLS" ? "NLB" : (local.acm_certificate_arn != "" ? "ALB" : "None")
    }
  }
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
    alb_https_url = local.acm_certificate_arn != "" ? "https://${module.ecs.alb_dns_name}" : null

    # NLB access
    nlb_dns_name = module.networking.nlb_dns_name
    nlb_http_url = var.create_http_listener ? "http://${module.networking.nlb_dns_name}" : null
    nlb_https_url = local.acm_certificate_arn != "" ? "https://${module.networking.nlb_dns_name}" : null
  }
}

output "redis_parameters_check" {
  description = "Redis parameters that might affect connectivity"
  value = var.redis_parameters
}

################################################################################
# DocumentDB Outputs
################################################################################

output "documentdb_cluster_id" {
  description = "The DocumentDB cluster identifier"
  value       = module.documentdb.cluster_id
}

output "documentdb_cluster_arn" {
  description = "The ARN of the DocumentDB cluster"
  value       = module.documentdb.cluster_arn
}

output "documentdb_endpoint" {
  description = "The primary endpoint of the DocumentDB cluster"
  value       = module.documentdb.endpoint
}

output "documentdb_reader_endpoint" {
  description = "The reader endpoint of the DocumentDB cluster"
  value       = module.documentdb.reader_endpoint
}

output "documentdb_port" {
  description = "The port of the DocumentDB cluster"
  value       = module.documentdb.port
}

output "documentdb_security_group_id" {
  description = "The security group ID for DocumentDB"
  value       = module.documentdb.security_group_id
}

output "documentdb_kms_key_arn" {
  description = "The KMS key ARN used for DocumentDB encryption"
  value       = module.documentdb.kms_key_arn
}

output "documentdb_secrets_manager_secret_arn" {
  description = "The ARN of the Secrets Manager secret for DocumentDB"
  value       = module.documentdb.secrets_manager_secret_arn
}

output "documentdb_iam_policy_arn" {
  description = "The ARN of the IAM policy for DocumentDB access"
  value       = module.documentdb.iam_policy_arn
}

output "documentdb_connection_info" {
  description = "DocumentDB connection information (non-sensitive)"
  value = {
    cluster_identifier = module.documentdb.cluster_identifier
    endpoint           = module.documentdb.endpoint
    reader_endpoint    = module.documentdb.reader_endpoint
    port               = module.documentdb.port
    database_name      = local.documentdb_database_name
    tls_enabled        = true
    secrets_manager_arn = module.documentdb.secrets_manager_secret_arn
  }
}