# environments/qa/main.tf

locals {
  cluster_name = "${var.cluster_name}-${var.environment}"
  vpc_name     = "${var.cluster_name}-${var.environment}-${var.region}"
  # Get all ECS security group IDs
  ecs_security_group_ids = [for sg_id in module.ecs.security_group_ids : sg_id]
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

# Redis Module
module "redis" {
  source = "../../modules/redis"

  cluster_name = local.cluster_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets  # Use private subnets for Redis

  # Redis Configuration
  redis_node_type          = var.redis_node_type
  redis_engine_version     = var.redis_engine_version
  redis_num_cache_clusters = var.redis_num_cache_clusters

  # High Availability
  redis_multi_az_enabled           = var.redis_multi_az_enabled
  redis_automatic_failover_enabled = var.redis_automatic_failover_enabled
  redis_snapshot_retention_limit   = var.redis_snapshot_retention_limit
  redis_snapshot_window           = var.redis_snapshot_window
  redis_maintenance_window        = var.redis_maintenance_window

  # Security Configuration
  create_security_group = true
  allowed_cidr_blocks   = [module.vpc.vpc_cidr_block]

  # Auth and Encryption
  auth_token_enabled              = var.redis_auth_token_enabled
  redis_transit_encryption_enabled = var.redis_transit_encryption_enabled
  redis_at_rest_encryption_enabled = var.redis_at_rest_encryption_enabled

  # Parameter customization
  redis_parameters = var.redis_parameters

  # Monitoring and SSM
  store_connection_details_in_ssm = var.redis_store_connection_details_in_ssm
  create_cloudwatch_log_group     = var.redis_create_cloudwatch_log_group
  cloudwatch_log_retention_days   = var.redis_cloudwatch_log_retention_days

  # ADD THIS: Allow access from ECS security groups
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

# MongoDB Cluster Module
module "mongodb" {
  source = "../../modules/mongodb"

  cluster_name = "${local.cluster_name}-mongodb"
  environment  = var.environment

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.database_subnets  # Using database subnets for MongoDB

  # Instance configuration
  replica_count = var.mongodb_replica_count
  instance_type = var.mongodb_instance_type
  ami_id        = var.mongodb_ami_id
  # Removed key_name - key pair will be created automatically

  # MongoDB configuration
  mongodb_version         = var.mongodb_version
  mongodb_admin_username  = var.mongodb_admin_username
  mongodb_admin_password  = var.mongodb_admin_password
  mongodb_keyfile_content = var.mongodb_keyfile_content
  default_database = var.mongodb_default_database

  # Storage configuration
  root_volume_size = var.mongodb_root_volume_size
  data_volume_size = var.mongodb_data_volume_size
  data_volume_type = var.mongodb_data_volume_type
  data_volume_iops = var.mongodb_data_volume_iops
  data_volume_throughput = var.mongodb_data_volume_throughput

  # Security configuration
  create_security_group = true
  allowed_cidr_blocks = [module.vpc.vpc_cidr_block]
  additional_security_group_ids = []
  allow_ssh             = var.mongodb_allow_ssh
  ssh_cidr_blocks = var.mongodb_ssh_cidr_blocks

  # Monitoring and logging
  enable_monitoring = var.mongodb_enable_monitoring
  log_retention_days = var.mongodb_log_retention_days

  # DNS configuration
  create_dns_records = var.mongodb_create_dns_records
  private_domain = var.mongodb_private_domain

  # Backup configuration
  backup_enabled  = var.mongodb_backup_enabled
  backup_schedule = var.mongodb_backup_schedule
  backup_retention_days = var.mongodb_backup_retention_days

  # Additional features
  store_connection_string_in_ssm = var.mongodb_store_connection_string_in_ssm
  enable_encryption_at_rest      = var.mongodb_enable_encryption_at_rest
  enable_audit_logging           = var.mongodb_enable_audit_logging

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-Agents"
      "Component"   = "MongoDB"
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

  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnets

  acm_certificate_arn = ""
  create_alb_rules    = true

  enable_container_insights = var.enable_container_insights
  enable_execute_command    = var.enable_execute_command
  enable_service_discovery  = true
  create_alb = true

  # ADD THESE LINES for Redis connectivity
  redis_security_group_id   = module.redis.redis_security_group_id
  mongodb_security_group_id = module.mongodb.security_group_id

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

  depends_on = [module.mongodb, module.redis]
}

# Global Accelerator Module
module "global_accelerator" {
  count = var.create_global_accelerator ? 1 : 0

  source = "../../modules/global-accelerator"

  cluster_name = local.cluster_name
  environment  = var.environment

  # Global Accelerator Configuration
  ip_address_type = var.global_accelerator_ip_address_type
  enabled         = var.global_accelerator_enabled

  # Flow Logs
  enable_flow_logs       = var.global_accelerator_flow_logs_enabled
  flow_logs_s3_prefix    = var.global_accelerator_flow_logs_s3_prefix

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

  # Endpoints (ALB)
  endpoints = [
    {
      endpoint_id                    = module.ecs.alb_arn
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

  depends_on = [module.ecs]
}

# Cloudflare Module
module "cloudflare" {
  count = var.create_cloudflare_dns_records ? 1 : 0

  source = "../../modules/cloudflare"

  cluster_name = local.cluster_name
  environment  = var.environment

  # Cloudflare Configuration
  cloudflare_zone_id = var.cloudflare_zone_id

  # DNS Configuration
  target_dns_name = var.create_global_accelerator ? module.global_accelerator[0].accelerator_dns_name : module.ecs.alb_dns_name
  dns_record_type = "CNAME"
  proxied         = var.dns_proxied
  ttl             = var.dns_ttl

  # Custom DNS records for our specific routing
  app_dns_records = var.app_dns_records

  # Zone Settings
  manage_zone_settings = var.manage_cloudflare_zone_settings
  zone_settings = var.manage_cloudflare_zone_settings ? {
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
    module.global_accelerator
  ]
}

# Allow ECS to connect to Redis (INGRESS to Redis)
resource "aws_security_group_rule" "redis_from_ecs_ingress" {
  for_each = toset(local.ecs_security_group_ids)

  type                     = "ingress"
  from_port                = module.redis.redis_port
  to_port                  = module.redis.redis_port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = module.redis.redis_security_group_id
  description              = "Allow ECS services to access Redis"

  depends_on = [module.ecs, module.redis]
}

# Allow ECS to connect to Redis (EGRESS from ECS)
resource "aws_security_group_rule" "ecs_to_redis_egress" {
  for_each = module.ecs.security_group_ids

  type                     = "egress"
  from_port                = module.redis.redis_port
  to_port                  = module.redis.redis_port
  protocol                 = "tcp"
  source_security_group_id = module.redis.redis_security_group_id
  security_group_id        = each.value
  description              = "Allow ECS services to connect to Redis"

  depends_on = [module.ecs, module.redis]
}

# Security Group Rule to allow ECS access to MongoDB
resource "aws_security_group_rule" "mongodb_from_ecs" {
  for_each = module.ecs.security_group_ids

  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = module.mongodb.security_group_id

  depends_on = [module.ecs, module.mongodb]
}