#------------------------------------------------------------------------------
# n8n Module - Main Configuration
# Unified architecture for n8n workflow automation on AWS ECS Fargate
#------------------------------------------------------------------------------

locals {
  name_prefix = "${var.name_prefix}-n8n"

  default_tags = merge(var.tags, {
    Module      = "n8n"
    Environment = var.environment
    Component   = "n8n-workflow-automation"
  })

  # Service names
  main_service_name    = "${local.name_prefix}-main"
  webhook_service_name = "${local.name_prefix}-webhook"
  worker_service_name  = "${local.name_prefix}-worker"

  # Common environment variables for all n8n services
  common_environment = {
    # Database
    DB_TYPE                   = "postgresdb"
    DB_POSTGRESDB_HOST        = module.rds.address
    DB_POSTGRESDB_PORT        = tostring(module.rds.port)
    DB_POSTGRESDB_DATABASE    = module.rds.database_name
    DB_POSTGRESDB_SSL_ENABLED = "true"
    # Accept RDS SSL certificate (RDS uses Amazon-issued certificates)
    DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED = "false"

    # Redis Queue (with TLS when enabled)
    QUEUE_BULL_REDIS_HOST = var.redis_host
    QUEUE_BULL_REDIS_PORT = tostring(var.redis_port)
    QUEUE_BULL_REDIS_TLS  = var.enable_redis_tls ? "true" : "false"

    # Execution mode
    EXECUTIONS_MODE = "queue"

    # Timezone
    GENERIC_TIMEZONE = var.n8n_timezone
    TZ               = var.n8n_timezone

    # Logging
    N8N_LOG_LEVEL  = "info"
    N8N_LOG_OUTPUT = "console"

    # Disable telemetry for HIPAA
    N8N_DIAGNOSTICS_ENABLED           = "false"
    N8N_VERSION_NOTIFICATIONS_ENABLED = "false"
  }

  # Common secrets for all n8n services
  common_secrets = [
    {
      name      = "DB_POSTGRESDB_USER"
      valueFrom = "${module.rds.credentials_secret_arn}:username::"
    },
    {
      name      = "DB_POSTGRESDB_PASSWORD"
      valueFrom = "${module.rds.credentials_secret_arn}:password::"
    },
    {
      name      = "N8N_ENCRYPTION_KEY"
      valueFrom = aws_secretsmanager_secret.n8n_encryption_key.arn
    }
  ]

  # Add Redis auth if provided
  redis_secrets = var.redis_auth_token_secret_arn != null ? [
    {
      name      = "QUEUE_BULL_REDIS_PASSWORD"
      valueFrom = var.redis_auth_token_secret_arn
    }
  ] : []

  all_secrets = concat(local.common_secrets, local.redis_secrets)
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

#------------------------------------------------------------------------------
# RDS PostgreSQL Module
#------------------------------------------------------------------------------

module "rds" {
  source = "../rds-postgres"

  identifier          = var.name_prefix
  environment         = var.environment
  vpc_id              = var.vpc_id
  database_subnet_ids = var.database_subnet_ids

  # Instance configuration
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  multi_az              = var.db_multi_az
  database_name         = "n8n"

  # Security
  deletion_protection = var.db_deletion_protection
  skip_final_snapshot = var.db_skip_final_snapshot

  # Allow connections from VPC CIDR (n8n services are in private subnets)
  # Using CIDR instead of security group IDs to avoid plan-time unknown value issues
  allowed_cidr_blocks = [var.vpc_cidr_block]

  # HIPAA compliance
  cloudwatch_log_retention_days = var.log_retention_days

  tags = local.default_tags
}

#------------------------------------------------------------------------------
# n8n Encryption Key
#------------------------------------------------------------------------------

resource "random_password" "n8n_encryption_key" {
  count = var.n8n_encryption_key == null ? 1 : 0

  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "n8n_encryption_key" {
  name_prefix = "${local.name_prefix}-encryption-key-"
  description = "n8n encryption key for workflow credentials"

  tags = local.default_tags
}

resource "aws_secretsmanager_secret_version" "n8n_encryption_key" {
  secret_id     = aws_secretsmanager_secret.n8n_encryption_key.id
  secret_string = var.n8n_encryption_key != null ? var.n8n_encryption_key : random_password.n8n_encryption_key[0].result
}

#------------------------------------------------------------------------------
# CloudWatch Log Groups
#------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "n8n_main" {
  name              = "/ecs/${local.main_service_name}"
  retention_in_days = var.log_retention_days

  tags = merge(local.default_tags, {
    Service = "n8n-main"
  })
}

resource "aws_cloudwatch_log_group" "n8n_webhook" {
  name              = "/ecs/${local.webhook_service_name}"
  retention_in_days = var.log_retention_days

  tags = merge(local.default_tags, {
    Service = "n8n-webhook"
  })
}

resource "aws_cloudwatch_log_group" "n8n_worker" {
  name              = "/ecs/${local.worker_service_name}"
  retention_in_days = var.log_retention_days

  tags = merge(local.default_tags, {
    Service = "n8n-worker"
  })
}
