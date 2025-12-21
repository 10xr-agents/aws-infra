#------------------------------------------------------------------------------
# n8n Workflow Automation - QA Environment
# Unified architecture: Production-ready from Day 1, scale via variables
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Redis for n8n Queue Mode
# Required for distributed job processing in queue mode
#------------------------------------------------------------------------------

module "n8n_redis" {
  source = "../../modules/redis"

  cluster_name = "${var.cluster_name}-n8n"
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets

  # Redis Configuration - Starter tier
  redis_node_type          = var.n8n_config.redis_node_type
  redis_engine_version     = "7.1"
  redis_num_cache_clusters = var.n8n_config.redis_num_cache_clusters

  # High Availability - Disabled for starter tier, enable for growth/production
  redis_multi_az_enabled           = var.n8n_config.redis_multi_az
  redis_automatic_failover_enabled = var.n8n_config.redis_multi_az
  redis_snapshot_retention_limit   = 7
  redis_snapshot_window            = "03:00-05:00"
  redis_maintenance_window         = "Mon:05:00-Mon:07:00"

  # Security Configuration
  create_security_group = true
  allowed_cidr_blocks   = [module.vpc.vpc_cidr_block]

  # Auth and Encryption (HIPAA)
  auth_token_enabled               = true
  redis_transit_encryption_enabled = true
  redis_at_rest_encryption_enabled = true

  # Monitoring
  store_connection_details_in_ssm = true
  create_cloudwatch_log_group     = true
  cloudwatch_log_retention_days   = var.hipaa_config.log_retention_days

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-HealthCare"
      "Component"   = "n8n-Redis"
      "Platform"    = "AWS"
      "Terraform"   = "true"
    }
  )

  depends_on = [module.vpc]
}

#------------------------------------------------------------------------------
# Redis Auth Token in Secrets Manager (for ECS task injection)
#------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "n8n_redis_auth" {
  name_prefix = "${var.cluster_name}-${var.environment}-n8n-redis-auth-"
  description = "Redis auth token for n8n services"

  tags = merge(var.tags, {
    Component = "n8n-Redis"
  })
}

resource "aws_secretsmanager_secret_version" "n8n_redis_auth" {
  secret_id     = aws_secretsmanager_secret.n8n_redis_auth.id
  secret_string = module.n8n_redis.redis_auth_token
}

#------------------------------------------------------------------------------
# n8n Module
# Workflow automation with queue mode (main, webhook, worker services)
#------------------------------------------------------------------------------

module "n8n" {
  source = "../../modules/n8n"

  name_prefix = var.cluster_name
  environment = var.environment

  # Network Configuration
  vpc_id              = module.vpc.vpc_id
  vpc_cidr_block      = var.vpc_cidr
  private_subnet_ids  = module.vpc.private_subnets
  database_subnet_ids = module.vpc.database_subnets

  # ECS Cluster
  ecs_cluster_id   = module.ecs.cluster_id
  ecs_cluster_name = module.ecs.cluster_name

  # ALB Configuration
  alb_arn               = module.ecs.alb_arn
  alb_security_group_id = module.ecs.alb_security_group_id
  alb_listener_arn      = module.ecs.alb_listener_arns.https

  # Host headers for routing (DNS managed externally)
  main_host_header    = var.n8n_config.main_host_header
  webhook_host_header = var.n8n_config.webhook_host_header

  # Listener rule priorities (ensure no conflicts with existing services)
  listener_rule_priority_main    = 100
  listener_rule_priority_webhook = 101

  # RDS PostgreSQL Configuration
  db_instance_class        = var.n8n_config.db_instance_class
  db_allocated_storage     = var.n8n_config.db_allocated_storage
  db_max_allocated_storage = var.n8n_config.db_max_allocated_storage
  db_multi_az              = var.n8n_config.db_multi_az
  db_deletion_protection   = var.hipaa_config.enable_deletion_protection
  db_skip_final_snapshot   = var.hipaa_config.skip_final_snapshot

  # Redis Configuration (from n8n_redis module)
  enable_redis                = true
  redis_host                  = module.n8n_redis.redis_primary_endpoint
  redis_port                  = 6379
  redis_security_group_id     = module.n8n_redis.redis_security_group_id
  redis_auth_token_secret_arn = aws_secretsmanager_secret.n8n_redis_auth.arn

  # n8n Main Service
  main_cpu                 = var.n8n_config.main_cpu
  main_memory              = var.n8n_config.main_memory
  main_desired_count       = var.n8n_config.main_desired_count
  main_min_capacity        = var.n8n_config.main_min_capacity
  main_max_capacity        = var.n8n_config.main_max_capacity
  main_enable_auto_scaling = var.n8n_config.main_enable_auto_scaling

  # n8n Webhook Service
  webhook_cpu                 = var.n8n_config.webhook_cpu
  webhook_memory              = var.n8n_config.webhook_memory
  webhook_desired_count       = var.n8n_config.webhook_desired_count
  webhook_min_capacity        = var.n8n_config.webhook_min_capacity
  webhook_max_capacity        = var.n8n_config.webhook_max_capacity
  webhook_enable_auto_scaling = var.n8n_config.webhook_enable_auto_scaling

  # n8n Worker Service
  worker_cpu                 = var.n8n_config.worker_cpu
  worker_memory              = var.n8n_config.worker_memory
  worker_desired_count       = var.n8n_config.worker_desired_count
  worker_min_capacity        = var.n8n_config.worker_min_capacity
  worker_max_capacity        = var.n8n_config.worker_max_capacity
  worker_enable_auto_scaling = var.n8n_config.worker_enable_auto_scaling
  worker_concurrency         = var.n8n_config.worker_concurrency

  # n8n Application
  n8n_image     = var.n8n_config.n8n_image
  n8n_image_tag = var.n8n_config.n8n_image_tag
  n8n_timezone  = var.n8n_config.n8n_timezone

  # HIPAA Logging
  log_retention_days = var.hipaa_config.log_retention_days

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-HealthCare"
      "Component"   = "n8n"
      "Platform"    = "AWS"
      "Terraform"   = "true"
    }
  )

  depends_on = [module.ecs, module.n8n_redis]
}

#------------------------------------------------------------------------------
# Outputs
#------------------------------------------------------------------------------

output "n8n_main_url" {
  description = "URL for n8n main UI"
  value       = module.n8n.main_url
}

output "n8n_webhook_url" {
  description = "URL for n8n webhooks"
  value       = module.n8n.webhook_url
}

output "n8n_rds_endpoint" {
  description = "n8n RDS PostgreSQL endpoint"
  value       = module.n8n.rds_endpoint
}

output "n8n_redis_endpoint" {
  description = "n8n Redis endpoint"
  value       = module.n8n_redis.redis_primary_endpoint
}
