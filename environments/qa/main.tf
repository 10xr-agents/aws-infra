# environments/qa/main.tf

locals {
  vpc_name = "${local.cluster_name}-${var.region}"
}

# Add this data source to the top of environments/qa/main.tf after the locals block

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

################################################################################
# ACM Certificate with Cloudflare DNS Validation
# This runs FIRST - no dependencies on ECS, ALB, or NLB
# Certificate is validated before any other infrastructure is created
################################################################################

module "certs" {
  source = "../../modules/certs"

  environment = var.environment
  domain      = var.domain
  subject_alternative_domains = [
    "*.${var.domain}", # Covers n8n.qa, webhook-n8n.qa, worker-n8n.qa, etc.
    "homehealth.${var.domain}",
    "hospice.${var.domain}",
    "voice.${var.domain}"
  ]

  # Cloudflare validation - creates DNS records and waits for validation
  enable_cloudflare_validation = var.enable_cloudflare_dns
  cloudflare_zone_id           = var.cloudflare_zone_id
  validation_timeout           = "30m"
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

  # HIPAA Configuration - VPC Flow Logs retention
  flow_log_cloudwatch_log_retention_days = var.hipaa_config.log_retention_days

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-HealthCare"
      "Platform"    = "AWS"
      "Terraform"   = "true"
    }
  )
}

################################################################################
# Redis Module - TLS Encrypted (Shared by ECS Services and n8n)
# Used by: home-health, hospice, n8n (main, webhook, worker)
################################################################################

module "redis" {
  source = "../../modules/redis"

  cluster_name = local.cluster_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets

  # Redis Configuration
  redis_node_type          = "cache.t3.micro" # Starter tier for QA
  redis_engine_version     = "7.1"
  redis_num_cache_clusters = 2

  # High Availability
  redis_multi_az_enabled           = true
  redis_automatic_failover_enabled = true
  redis_snapshot_retention_limit   = 7
  redis_snapshot_window            = "03:00-05:00"
  redis_maintenance_window         = "Mon:05:00-Mon:07:00"

  # Security Configuration
  create_security_group = true
  allowed_cidr_blocks   = [module.vpc.vpc_cidr_block]

  # Auth and Encryption - TLS ENABLED for HIPAA compliance
  auth_token_enabled               = true
  redis_transit_encryption_enabled = true # TLS enabled for home-health & hospice
  redis_at_rest_encryption_enabled = true

  # Monitoring and SSM
  store_connection_details_in_ssm = true
  create_cloudwatch_log_group     = true
  cloudwatch_log_retention_days   = var.hipaa_config.log_retention_days

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-HealthCare"
      "Component"   = "Redis"
      "Platform"    = "AWS"
      "Terraform"   = "true"
      "HIPAA"       = "true"
    }
  )

  depends_on = [module.vpc]
}

# Redis Auth Token in Secrets Manager (shared by ECS services and n8n)
resource "aws_secretsmanager_secret" "redis_auth" {
  name_prefix = "${local.cluster_name}-redis-auth-"
  description = "Redis auth token for ECS services and n8n (home-health, hospice, n8n)"

  tags = merge(var.tags, {
    Component = "Redis"
  })
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id     = aws_secretsmanager_secret.redis_auth.id
  secret_string = module.redis.redis_auth_token
}

# HIPAA-Compliant S3 Bucket for Patient Data
module "s3_patients" {
  source = "../../modules/s3-hipaa"

  cluster_name = var.cluster_name
  environment  = var.environment
  bucket_name  = "patients"

  # KMS encryption for HIPAA compliance
  create_kms_key          = true
  kms_key_deletion_window = 30

  # ECS task roles that need access (will be populated after ECS module)
  ecs_task_role_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" # Temporary - will update with actual task roles
  ]

  # HIPAA Configuration - configurable per environment
  retention_days        = var.hipaa_config.data_retention_days
  force_destroy         = var.hipaa_config.s3_force_destroy
  enable_access_logging = var.hipaa_config.enable_access_logging

  tags = merge(var.tags, {
    "Component" = "S3"
    "HIPAA"     = "true"
    "DataType"  = "PHI"
  })

  depends_on = [module.vpc]
}

################################################################################
# S3 Bucket for LiveKit Agent (Recording/Media Storage)
################################################################################

module "s3_livekit" {
  source = "../../modules/s3-hipaa"

  cluster_name = "ten-xr" # Fixed prefix for bucket name: ten-xr-livekit
  environment  = ""       # No environment suffix for this bucket
  bucket_name  = "livekit"

  # KMS encryption
  create_kms_key          = true
  kms_key_deletion_window = 30

  # ECS task roles that need access
  ecs_task_role_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]

  # Configuration - not PHI data, so relaxed retention
  retention_days        = var.hipaa_config.data_retention_days
  force_destroy         = var.hipaa_config.s3_force_destroy
  enable_access_logging = var.hipaa_config.enable_access_logging

  tags = merge(var.tags, {
    "Component" = "S3"
    "Service"   = "livekit-agent"
    "DataType"  = "MediaRecordings"
  })

  depends_on = [module.vpc]
}

# DocumentDB Module - HIPAA Compliant Database
module "documentdb" {
  source = "../../modules/documentdb"

  cluster_name = var.cluster_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.database_subnets # Use database subnets for DocumentDB

  # Cluster Configuration
  cluster_size   = var.documentdb_cluster_size
  instance_class = var.documentdb_instance_class
  engine_version = var.documentdb_engine_version
  cluster_family = var.documentdb_cluster_family

  # Authentication
  master_username = var.documentdb_master_username
  master_password = var.documentdb_master_password

  # Security - Allow access from VPC CIDR and ECS security groups
  create_security_group      = true
  allowed_cidr_blocks        = [module.vpc.vpc_cidr_block]
  allowed_security_group_ids = [] # Will be populated by ECS module if needed

  # Encryption (HIPAA Compliance)
  create_kms_key          = var.documentdb_create_kms_key
  kms_key_enable_rotation = true
  tls_enabled             = true # Required for HIPAA - encryption in transit

  # HIPAA Configuration - configurable per environment
  backup_retention_period       = var.hipaa_config.backup_retention_days
  preferred_backup_window       = var.documentdb_preferred_backup_window
  skip_final_snapshot           = var.hipaa_config.skip_final_snapshot
  deletion_protection           = var.hipaa_config.enable_deletion_protection
  cloudwatch_log_retention_days = var.hipaa_config.log_retention_days
  audit_logs_enabled            = var.hipaa_config.enable_audit_logging
  create_cloudwatch_alarms      = var.hipaa_config.enable_cloudwatch_alarms

  # Maintenance
  preferred_maintenance_window = var.documentdb_preferred_maintenance_window
  apply_immediately            = var.documentdb_apply_immediately
  auto_minor_version_upgrade   = var.documentdb_auto_minor_version_upgrade

  # Logging (HIPAA Compliance)
  enabled_cloudwatch_logs_exports = var.documentdb_enabled_cloudwatch_logs_exports
  profiler_enabled                = var.documentdb_profiler_enabled
  profiler_threshold_ms           = var.documentdb_profiler_threshold_ms

  # SSM and Secrets Manager
  ssm_parameter_enabled   = var.documentdb_ssm_parameter_enabled
  secrets_manager_enabled = var.documentdb_secrets_manager_enabled

  # IAM Policy for ECS access
  create_iam_policy = true

  # CloudWatch Alarms
  alarm_actions = var.alarm_actions

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-HealthCare"
      "Component"   = "DocumentDB"
      "Platform"    = "AWS"
      "Terraform"   = "true"
      "HIPAA"       = "true"
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
  vpc_cidr_block     = module.vpc.vpc_cidr_block
  private_subnet_ids = module.vpc.private_subnets
  public_subnet_ids  = module.vpc.public_subnets

  acm_certificate_arn = local.acm_certificate_arn
  enable_https        = true # Must be static for plan-time evaluation
  create_alb_rules    = true

  enable_container_insights = var.enable_container_insights
  enable_execute_command    = var.enable_execute_command
  enable_service_discovery  = true
  create_alb                = true
  alb_internal              = true

  # Pass the entire services configuration from variables
  services = local.ecs_services_with_overrides

  # HIPAA Configuration - configurable per environment
  alb_enable_deletion_protection = var.hipaa_config.enable_deletion_protection
  alb_access_logs_enabled        = var.hipaa_config.enable_access_logging
  alb_connection_logs_enabled    = var.hipaa_config.enable_access_logging
  log_retention_days             = var.hipaa_config.log_retention_days
  s3_force_destroy               = var.hipaa_config.s3_force_destroy

  # IAM and KMS Configuration for accessing secrets and encrypted resources
  kms_key_arns = [
    module.documentdb.kms_key_arn, # DocumentDB KMS key
    module.s3_patients.kms_key_arn # S3 HIPAA bucket KMS key
  ]

  # Attach DocumentDB access policy to task execution roles (for pulling secrets at startup)
  task_execution_policy_arns = [
    module.documentdb.iam_policy_arn
  ]

  # Attach DocumentDB access policy to task roles (for runtime database access)
  task_role_policy_arns = [
    module.documentdb.iam_policy_arn
  ]

  # S3 bucket access for PHI data
  s3_bucket_arns = [
    module.s3_patients.bucket_arn
  ]

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-HealthCare"
      "Component"   = "ECS"
      "Platform"    = "AWS"
      "Terraform"   = "true"
    }
  )

  depends_on = [module.documentdb, module.certs, module.s3_patients]
}

# Networking Module (NEW - replaces the NLB resources)
module "networking" {
  source = "../../modules/networking"

  cluster_name = local.cluster_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id

  public_subnet_ids  = module.vpc.public_subnets
  private_subnet_ids = module.vpc.private_subnets

  # NLB Configuration
  create_nlb                           = var.create_nlb
  nlb_internal                         = var.nlb_internal
  nlb_enable_cross_zone_load_balancing = var.nlb_enable_cross_zone_load_balancing

  # HIPAA Configuration - configurable per environment
  nlb_enable_deletion_protection = var.hipaa_config.enable_deletion_protection
  nlb_access_logs_enabled        = var.hipaa_config.enable_access_logging
  nlb_connection_logs_enabled    = var.hipaa_config.enable_access_logging
  nlb_logs_retention_days        = var.hipaa_config.log_retention_days
  s3_force_destroy               = var.hipaa_config.s3_force_destroy
  create_cloudwatch_alarms       = var.hipaa_config.enable_cloudwatch_alarms

  # Target Group Configuration
  http_port   = var.http_port
  https_port  = var.https_port
  target_type = var.target_type

  # Target Configuration
  alb_arn = module.ecs.alb_arn

  custom_target_groups = {}
  custom_listeners     = {}

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
  deregistration_delay             = var.deregistration_delay

  # Listener Configuration
  https_listener_protocol = var.https_listener_protocol
  ssl_policy              = var.ssl_policy
  certificate_arn         = local.acm_certificate_arn

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-HealthCare"
      "Component"   = "Networking"
      "Platform"    = "AWS"
      "Terraform"   = "true"
    }
  )

  depends_on = [module.ecs]
}

################################################################################
# Cloudflare DNS Module - Service Records
# Creates DNS records pointing services to NLB
# NOTE: ACM validation is handled by the certs module (runs first)
################################################################################

module "cloudflare_dns" {
  source = "../../modules/cloudflare-dns"
  count  = var.enable_cloudflare_dns ? 1 : 0

  zone_id      = var.cloudflare_zone_id
  environment  = var.environment
  domain       = var.domain
  nlb_dns_name = module.networking.nlb_dns_name

  # Service DNS records (all pointing to NLB)
  dns_records = {
    homehealth = {
      name    = "homehealth"
      proxied = false
    }
    hospice = {
      name    = "hospice"
      proxied = false
    }
    voice = {
      name    = "voice"
      proxied = false
    }
    n8n = {
      name    = "n8n"
      proxied = false
    }
    webhook-n8n = {
      name    = "webhook-n8n" # Hyphen notation instead of nested subdomain
      proxied = false
    }
  }

  # No wildcard record - only create explicit service records
  create_wildcard_record = false

  tags = var.tags

  depends_on = [module.networking]
}

################################################################################
# Bastion Host Module - Secure access to VPC resources via SSM
################################################################################

module "bastion" {
  source = "../../modules/bastion"
  count  = var.enable_bastion_host ? 1 : 0

  cluster_name = var.cluster_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_id    = module.vpc.private_subnets[0] # Deploy in first private subnet

  # Instance configuration
  instance_type              = var.bastion_instance_type
  enable_detailed_monitoring = false

  # Logging
  enable_session_logging = true
  log_retention_days     = var.hipaa_config.log_retention_days

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-HealthCare"
      "Component"   = "Bastion"
      "Platform"    = "AWS"
      "Terraform"   = "true"
    }
  )

  depends_on = [module.vpc]
}