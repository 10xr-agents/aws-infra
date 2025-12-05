# environments/qa/main.tf

locals {
  cluster_name = "${var.cluster_name}-${var.environment}"
  vpc_name     = "${var.cluster_name}-${var.environment}-${var.region}"
}

# Add this data source to the top of environments/qa/main.tf after the locals block

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

module "certs" {
  source = "../../modules/certs"

  environment = var.environment
  domain = var.domain
  cloudflare_zone_id = var.cloudflare_zone_id
  subject_alternative_domains = [
    "*.${var.domain}",
    "services.${var.domain}",
    "app.${var.domain}",
    "api.${var.domain}",
    "proxy.${var.domain}"
  ]
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

# # Redis Module
# module "redis" {
#   source = "../../modules/redis"
#
#   cluster_name = local.cluster_name
#   environment  = var.environment
#   vpc_id       = module.vpc.vpc_id
#   subnet_ids   = module.vpc.private_subnets  # Use private subnets for Redis
#
#   # Redis Configuration
#   redis_node_type      = var.redis_node_type
#   redis_engine_version = var.redis_engine_version
#   redis_num_cache_clusters = var.redis_num_cache_clusters
#
#   # High Availability
#   redis_multi_az_enabled           = var.redis_multi_az_enabled
#   redis_automatic_failover_enabled = var.redis_automatic_failover_enabled
#   redis_snapshot_retention_limit   = var.redis_snapshot_retention_limit
#   redis_snapshot_window            = var.redis_snapshot_window
#   redis_maintenance_window = var.redis_maintenance_window
#
#   # Security Configuration
#   create_security_group = true
#   allowed_cidr_blocks = [module.vpc.vpc_cidr_block]
#
#   # Auth and Encryption
#   auth_token_enabled               = var.redis_auth_token_enabled
#   redis_transit_encryption_enabled = var.redis_transit_encryption_enabled
#   redis_at_rest_encryption_enabled = var.redis_at_rest_encryption_enabled
#
#   # Parameter customization
#   redis_parameters = var.redis_parameters
#
#   # Monitoring and SSM
#   store_connection_details_in_ssm = var.redis_store_connection_details_in_ssm
#   create_cloudwatch_log_group     = var.redis_create_cloudwatch_log_group
#   cloudwatch_log_retention_days = var.redis_cloudwatch_log_retention_days
#
#   # ADD THIS: Allow access from ECS security groups
#   allowed_security_group_ids = []
#
#   tags = merge(
#     var.tags,
#     {
#       "Environment" = var.environment
#       "Project"     = "10xR-Agents"
#       "Component"   = "Redis"
#       "Platform"    = "AWS"
#       "Terraform"   = "true"
#     }
#   )
#
#   depends_on = [module.vpc]
# }

# ECS Cluster Module
module "ecs" {
  source = "../../modules/ecs"

  cluster_name = var.cluster_name
  environment  = var.environment

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  public_subnet_ids  = module.vpc.public_subnets

  acm_certificate_arn = local.acm_certificate_arn
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

  depends_on = [module.redis, module.certs]
}

# Networking Module (NEW - replaces the NLB resources)
module "networking" {
  source = "../../modules/networking"

  cluster_name = local.cluster_name
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
  certificate_arn = local.acm_certificate_arn

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