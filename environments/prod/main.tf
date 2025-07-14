# environments/prod/main.tf

locals {
  cluster_name = "${var.cluster_name}-${var.environment}"
  vpc_name     = "${var.cluster_name}-${var.environment}-${var.region}"
  
  # Shortened name prefix for AWS resource name limits (32 chars)
  short_name_prefix = "10xr-${var.environment}"
}

# Data sources for AWS information
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# TEMPORARILY COMMENT OUT DocumentDB data sources from separate repository
# Uncomment these after DocumentDB workspace has run and created the SSM parameters

# data "aws_ssm_parameter" "documentdb_connection_string" {
#   name = "/ten_xr_storage_infra/${var.environment}/connection_string"
# }

# data "aws_ssm_parameter" "documentdb_endpoint" {
#   name = "/ten_xr_storage_infra/${var.environment}/endpoint"
# }

# data "aws_ssm_parameter" "documentdb_port" {
#   name = "/ten_xr_storage_infra/${var.environment}/port"
# }

# data "aws_ssm_parameter" "documentdb_username" {
#   name = "/ten_xr_storage_infra/${var.environment}/master_username"
# }

# data "aws_ssm_parameter" "documentdb_password" {
#   name = "/ten_xr_storage_infra/${var.environment}/master_password"
# }

# data "aws_ssm_parameter" "documentdb_security_group_id" {
#   name = "/ten_xr_storage_infra/${var.environment}/security_group_id"
# }


resource "aws_acm_certificate" "main" {
  domain_name       = var.domain
  validation_method = "DNS"
  subject_alternative_names = [
    "*.${var.domain}",
    "services.${var.domain}",
    "app.${var.domain}",
    "api.${var.domain}",
    "proxy.${var.domain}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Cloudflare DNS record for certificate validation
resource "cloudflare_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
    if dvo.domain_name != "*.${var.domain}"
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  content = each.value.record
  type    = each.value.type
  ttl     = 60
  proxied = false
}

# Certificate Validation
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in cloudflare_record.cert_validation : record.hostname]
}

# VPC Module - Reuse existing VPC module
module "vpc" {
  source = "../../modules/vpc"

  environment = var.environment

  vpc_name = local.vpc_name
  vpc_cidr = var.vpc_cidr
  azs      = var.azs

  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets

  map_public_ip_on_launch = var.map_public_ip_on_launch

  # ECS specific tags
  cluster_name = local.cluster_name

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-Agents"
      "Platform"    = "AWS"
      "Terraform"   = "true"
    }
  )
}


################################################################################
# DocumentDB Sub-Workspace via TFE Module
################################################################################

module "documentdb_workspace" {
  source = "../../modules/tfe-workspace"

  # Organization and parent workspace
  tfe_organization_name   = var.tfe_organization_name
  parent_workspace_name   = var.tfe_main_workspace_name

  # Workspace configuration
  environment        = var.environment
  region            = var.region
  workspace_suffix  = "storage"
  workspace_description = "DocumentDB infrastructure for ${var.environment}"
  auto_apply        = var.documentdb_workspace_auto_apply

  # VCS configuration
  github_repo           = var.documentdb_github_repo
  github_branch         = var.documentdb_github_branch
  github_oauth_token_id = var.github_oauth_token_id
  working_directory     = "environments/${var.environment}"

  # Variables to pass to DocumentDB workspace
  workspace_variables = {
    aws_region = {
      value       = var.region
      category    = "terraform"
      description = "AWS region"
    }
    environment = {
      value       = var.environment
      category    = "terraform"
      description = "Environment name"
    }
    vpc_name = {
      value       = "${var.cluster_name}-${var.environment}-${var.region}"
      category    = "terraform"
      description = "VPC name to find via data source"
    }
    instance_count = {
      value       = tostring(var.documentdb_instance_count)
      category    = "terraform"
      description = "Number of DocumentDB instances"
    }
    instance_class = {
      value       = var.documentdb_instance_class
      category    = "terraform"
      description = "DocumentDB instance class"
    }
    allowed_cidr_blocks = {
      value       = jsonencode([var.vpc_cidr])
      category    = "terraform"
      description = "CIDR blocks allowed to access DocumentDB"
      hcl         = true
    }
    AWS_DEFAULT_REGION = {
      value       = var.region
      category    = "env"
      description = "AWS Default Region"
    }
  }

  enable_run_trigger = true
}


# Redis Module
module "redis" {
  source = "../../modules/redis"

  cluster_name = local.cluster_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets  # Use private subnets for Redis

  # Redis Configuration - Production settings
  redis_node_type      = var.redis_node_type
  redis_engine_version = var.redis_engine_version
  redis_num_cache_clusters = var.redis_num_cache_clusters

  # High Availability
  redis_multi_az_enabled           = var.redis_multi_az_enabled
  redis_automatic_failover_enabled = var.redis_automatic_failover_enabled
  redis_snapshot_retention_limit   = var.redis_snapshot_retention_limit
  redis_snapshot_window            = var.redis_snapshot_window
  redis_maintenance_window = var.redis_maintenance_window

  # Security Configuration
  create_security_group = true
  allowed_cidr_blocks = [module.vpc.vpc_cidr_block]

  # Auth and Encryption
  auth_token_enabled               = var.redis_auth_token_enabled
  redis_transit_encryption_enabled = var.redis_transit_encryption_enabled
  redis_at_rest_encryption_enabled = var.redis_at_rest_encryption_enabled

  # Parameter customization
  redis_parameters = var.redis_parameters

  # Monitoring and SSM
  store_connection_details_in_ssm = var.redis_store_connection_details_in_ssm
  create_cloudwatch_log_group     = var.redis_create_cloudwatch_log_group
  cloudwatch_log_retention_days = var.redis_cloudwatch_log_retention_days

  # Allow access from ECS security groups
  allowed_security_group_ids = []

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-Agents"
      "Component"   = "Redis"
      "Platform"    = "AWS"
      "Terraform"   = "true"
    }
  )

  depends_on = [module.vpc]
}

# ECS Cluster Module
module "ecs" {
  source = "../../modules/ecs"

  cluster_name = var.cluster_name
  environment  = var.environment

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  public_subnet_ids  = module.vpc.public_subnets

  acm_certificate_arn = aws_acm_certificate.main.arn
  create_alb_rules    = true

  enable_container_insights = var.enable_container_insights
  enable_execute_command    = var.enable_execute_command
  enable_service_discovery  = true
  create_alb                = true
  alb_internal = true

  # Pass the entire services configuration from variables
  services = local.ecs_services_with_overrides

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-Agents"
      "Component"   = "ECS"
      "Platform"    = "AWS"
      "Terraform"   = "true"
    }
  )

  depends_on = [module.redis]
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  cluster_name = local.short_name_prefix  # Use shortened name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id

  public_subnet_ids = module.vpc.public_subnets
  private_subnet_ids = module.vpc.private_subnets

  # NLB Configuration
  create_nlb                     = var.create_nlb
  nlb_internal                   = var.nlb_internal
  nlb_enable_deletion_protection = var.nlb_enable_deletion_protection
  nlb_enable_cross_zone_load_balancing = var.nlb_enable_cross_zone_load_balancing

  # Target Group Configuration
  http_port                 = var.http_port
  https_port                = var.https_port
  target_type = var.target_type

  # Target Configuration
  alb_arn = module.ecs.alb_arn

  # Removed MongoDB custom target groups and listeners since using DocumentDB now
  custom_target_groups = {}
  custom_listeners = {}

  # Health Check Configuration
  health_check_enabled             = var.health_check_enabled
  health_check_healthy_threshold   = var.health_check_healthy_threshold
  health_check_interval            = var.health_check_interval
  health_check_port                = var.health_check_port
  health_check_protocol            = var.health_check_protocol
  health_check_timeout             = var.health_check_timeout
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold
  health_check_path                = var.health_check_path
  health_check_matcher             = var.health_check_matcher
  deregistration_delay = var.deregistration_delay

  # Listener Configuration
  https_listener_protocol = var.https_listener_protocol
  ssl_policy              = var.ssl_policy
  certificate_arn = aws_acm_certificate.main.arn

  # Access Logs
  nlb_access_logs_enabled = var.nlb_access_logs_enabled

  # Connection Logs
  nlb_connection_logs_enabled = var.nlb_connection_logs_enabled

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-Agents"
      "Component"   = "Networking"
      "Platform"    = "AWS"
      "Terraform"   = "true"
    }
  )

  depends_on = [module.ecs]
}

# Global Accelerator Module
module "global_accelerator" {
  count = var.create_global_accelerator ? 1 : 0

  source = "../../modules/global-accelerator"

  cluster_name = local.short_name_prefix  # Use shortened name
  environment = var.environment

  # Global Accelerator Configuration
  ip_address_type = var.global_accelerator_ip_address_type
  enabled = var.global_accelerator_enabled

  # Flow Logs
  enable_flow_logs = var.global_accelerator_flow_logs_enabled
  flow_logs_s3_prefix = var.global_accelerator_flow_logs_s3_prefix

  # Listener Configuration
  client_affinity = var.global_accelerator_client_affinity
  protocol        = var.global_accelerator_protocol
  port_ranges = [
    {
      from_port = 80
      to_port   = 80
    },
    {
      from_port = 443
      to_port   = 443
    }
  ]

  # Endpoints (NLB instead of ALB)
  endpoints = [
    {
      endpoint_id                    = module.networking.nlb_arn
      weight                         = 100
      client_ip_preservation_enabled = false
    }
  ]

  # Health Check Configuration
  health_check_grace_period_seconds = var.global_accelerator_health_check_grace_period
  health_check_interval_seconds     = var.global_accelerator_health_check_interval
  health_check_path                 = var.global_accelerator_health_check_path
  health_check_port                 = var.global_accelerator_health_check_port
  health_check_protocol             = var.global_accelerator_health_check_protocol
  threshold_count                   = var.global_accelerator_threshold_count
  traffic_dial_percentage           = var.global_accelerator_traffic_dial_percentage

  tags = merge(var.tags, {
    "Environment" = var.environment
    "Project"     = "10xR-Agents"
    "Component"   = "GlobalAccelerator"
    "Platform"    = "AWS"
    "Terraform"   = "true"
  })

  depends_on = [module.networking]
}

# Cloudflare Module
module "cloudflare" {
  count = var.create_cloudflare_dns_records ? 1 : 0

  source = "../../modules/cloudflare"

  cluster_name = local.short_name_prefix  # Use shortened name
  environment = var.environment

  # Cloudflare Configuration
  cloudflare_zone_id = var.cloudflare_zone_id

  # DNS Configuration
  target_dns_name = var.create_global_accelerator ? module.global_accelerator[0].accelerator_dns_name : module.networking.nlb_dns_name
  dns_record_type = "CNAME"
  proxied         = var.dns_proxied
  ttl = var.dns_ttl

  # Custom DNS records for our specific routing
  app_dns_records = var.app_dns_records

  # Zone Settings
  manage_zone_settings = var.manage_cloudflare_zone_settings
  zone_settings        = var.manage_cloudflare_zone_settings ? {
    ssl              = var.cloudflare_ssl_mode
    always_use_https = var.cloudflare_always_use_https
    min_tls_version  = var.cloudflare_min_tls_version
    security_level   = var.cloudflare_security_level
  } : {}

  tags = merge(var.tags, {
    "Environment" = var.environment
    "Project"     = "10xR-Agents"
    "Component"   = "Cloudflare"
    "Platform"    = "AWS"
    "Terraform"   = "true"
  })

  depends_on = [
    module.ecs,
    module.global_accelerator,
    module.networking
  ]
}

# Allow ECS to connect to Redis (INGRESS to Redis)
resource "aws_security_group_rule" "redis_from_ecs_ingress" {
  for_each = module.ecs.security_group_ids

  type                     = "ingress"
  from_port                = module.redis.redis_port
  to_port                  = module.redis.redis_port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = module.redis.redis_security_group_id
  description              = "Allow ECS services to access Redis"

  depends_on = [module.ecs, module.redis]
}



# resource "aws_security_group_rule" "documentdb_from_ecs" {
#   for_each = module.ecs.security_group_ids

#   type                     = "ingress"
#   from_port                = 27017
#   to_port                  = 27017
#   protocol                 = "tcp"
#   source_security_group_id = each.value
#   security_group_id        = data.aws_ssm_parameter.documentdb_security_group_id.value
#   description              = "Allow ECS services to access DocumentDB"

#   depends_on = [module.ecs]
# }