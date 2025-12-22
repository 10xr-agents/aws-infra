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
    vpc_id   = module.vpc.vpc_id
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
      alb_https_enabled     = local.acm_certificate_arn != ""
      nlb_https_protocol    = var.https_listener_protocol
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
    alb_dns_name  = module.ecs.alb_dns_name
    alb_http_url  = "http://${module.ecs.alb_dns_name}"
    alb_https_url = local.acm_certificate_arn != "" ? "https://${module.ecs.alb_dns_name}" : null

    # NLB access
    nlb_dns_name  = module.networking.nlb_dns_name
    nlb_http_url  = var.create_http_listener ? "http://${module.networking.nlb_dns_name}" : null
    nlb_https_url = local.acm_certificate_arn != "" ? "https://${module.networking.nlb_dns_name}" : null
  }
}

output "redis_parameters_check" {
  description = "Redis parameters that might affect connectivity"
  value       = var.redis_parameters
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
    cluster_identifier        = module.documentdb.cluster_identifier
    endpoint                  = module.documentdb.endpoint
    reader_endpoint           = module.documentdb.reader_endpoint
    port                      = module.documentdb.port
    tls_enabled               = true
    secrets_manager_arn       = module.documentdb.secrets_manager_secret_arn
    database_name_home_health = local.documentdb_database_home_health
    database_name_hospice     = local.documentdb_database_hospice
  }
}

################################################################################
# Outputs for Use in ECS Services
################################################################################

output "home_health_secrets_arn" {
  description = "ARN of Home Health secrets in Secrets Manager"
  value       = aws_secretsmanager_secret.home_health.arn
}

output "hospice_secrets_arn" {
  description = "ARN of Hospice secrets in Secrets Manager"
  value       = aws_secretsmanager_secret.hospice.arn
}

output "home_health_ssm_parameters" {
  description = "SSM parameter ARNs for Home Health service"
  value = {
    base_url     = aws_ssm_parameter.home_health_base_url.arn
    nextauth_url = aws_ssm_parameter.home_health_nextauth_url.arn
    node_env     = aws_ssm_parameter.home_health_node_env.arn
  }
}

output "hospice_ssm_parameters" {
  description = "SSM parameter ARNs for Hospice service"
  value = {
    base_url     = aws_ssm_parameter.hospice_base_url.arn
    nextauth_url = aws_ssm_parameter.hospice_nextauth_url.arn
    node_env     = aws_ssm_parameter.hospice_node_env.arn
  }
}

################################################################################
# Bastion Host Outputs
################################################################################

output "bastion_instance_id" {
  description = "ID of the bastion EC2 instance"
  value       = var.enable_bastion_host ? module.bastion[0].instance_id : null
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion host"
  value       = var.enable_bastion_host ? module.bastion[0].private_ip : null
}

output "bastion_ssm_command" {
  description = "AWS CLI command to connect to the bastion host via SSM"
  value       = var.enable_bastion_host ? module.bastion[0].ssm_start_session_command : "Bastion host is not enabled. Set enable_bastion_host = true to enable."
}

output "bastion_connection_info" {
  description = "Connection information for the bastion host"
  value = var.enable_bastion_host ? {
    instance_id                     = module.bastion[0].instance_id
    private_ip                      = module.bastion[0].private_ip
    ssm_session_command             = module.bastion[0].ssm_start_session_command
    documentdb_port_forward_command = module.bastion[0].ssm_port_forward_documentdb_command
    redis_port_forward_command      = module.bastion[0].ssm_port_forward_redis_command
    documentdb_endpoint             = module.documentdb.endpoint
    documentdb_port                 = module.documentdb.port
    documentdb_secrets_manager_arn  = module.documentdb.secrets_manager_secret_arn
  } : null
}

################################################################################
# Cloudflare DNS Outputs
################################################################################

output "cloudflare_dns_records" {
  description = "Cloudflare DNS records created for services"
  value       = var.enable_cloudflare_dns ? module.cloudflare_dns[0].service_records : null
}

output "cloudflare_service_urls" {
  description = "URLs for all services via Cloudflare DNS"
  value       = var.enable_cloudflare_dns ? module.cloudflare_dns[0].service_urls : null
}

output "cloudflare_acm_validation_records" {
  description = "ACM certificate validation records in Cloudflare"
  value       = var.enable_cloudflare_dns ? module.certs.cloudflare_validation_records : null
}

output "cloudflare_dns_summary" {
  description = "Summary of Cloudflare DNS configuration"
  value       = var.enable_cloudflare_dns ? module.cloudflare_dns[0].dns_summary : null
}
