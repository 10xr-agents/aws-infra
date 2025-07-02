# modules/redis/main.tf

locals {
  name_prefix = "${var.cluster_name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Component   = "Redis"
      ManagedBy   = "terraform"
    }
  )
}

################################################################################
# Random Password for Redis AUTH
################################################################################

resource "random_password" "redis_auth_token" {
  count   = var.auth_token_enabled ? 1 : 0
  length  = var.auth_token_length
  special = var.auth_token_special_chars
}

################################################################################
# ElastiCache Subnet Group
################################################################################

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${local.name_prefix}-redis-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis-subnet-group"
  })
}

################################################################################
# ElastiCache Parameter Group
################################################################################

resource "aws_elasticache_parameter_group" "redis" {
  family = var.redis_family
  name   = "${local.name_prefix}-redis-params"

  # Optimized parameters for temporary data/caching
  dynamic "parameter" {
    for_each = var.redis_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis-params"
  })
}

################################################################################
# Security Group for Redis
################################################################################

resource "aws_security_group" "redis" {
  count = var.create_security_group ? 1 : 0

  name        = "${local.name_prefix}-redis-sg"
  description = "Security group for Redis replication group"
  vpc_id      = var.vpc_id

  # Ingress rules for Redis port
  ingress {
    description     = "Redis port"
    from_port       = var.redis_port
    to_port         = var.redis_port
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
    cidr_blocks     = var.allowed_cidr_blocks
  }

  # Additional ingress rules if specified
  dynamic "ingress" {
    for_each = var.additional_ingress_rules
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks
      security_groups = ingress.value.security_groups
    }
  }

  # Egress - allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis-sg"
  })
}

################################################################################
# ElastiCache Replication Group
################################################################################

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${local.name_prefix}-redis"
  description          = "Redis replication group for ${local.name_prefix}"

  # Redis configuration
  node_type            = var.redis_node_type
  engine               = "redis"
  engine_version       = var.redis_engine_version
  port                 = var.redis_port
  parameter_group_name = aws_elasticache_parameter_group.redis.name

  # Replication settings
  num_cache_clusters = var.redis_num_cache_clusters

  # Multi-AZ and failover
  multi_az_enabled           = var.redis_multi_az_enabled
  automatic_failover_enabled = var.redis_automatic_failover_enabled

  # Backup settings - minimal for temporary data
  snapshot_retention_limit = var.redis_snapshot_retention_limit
  snapshot_window         = var.redis_snapshot_window

  # Maintenance
  maintenance_window = var.redis_maintenance_window

  # Security
  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = var.create_security_group ? [aws_security_group.redis[0].id] : var.security_group_ids

  # Auth token (password)
  auth_token                 = var.auth_token_enabled ? random_password.redis_auth_token[0].result : null
  transit_encryption_enabled = var.redis_transit_encryption_enabled
  at_rest_encryption_enabled = var.redis_at_rest_encryption_enabled

  # KMS key for encryption
  kms_key_id = var.redis_kms_key_id

  # Default logging configuration - enable slow and error logs
  dynamic "log_delivery_configuration" {
    for_each = length(var.redis_log_delivery_configuration) > 0 ? var.redis_log_delivery_configuration : [
      {
        destination      = aws_cloudwatch_log_group.redis_slow_log.name
        destination_type = "cloudwatch-logs"
        log_format       = "text"
        log_type         = "slow-log"
      },
      {
        destination      = aws_cloudwatch_log_group.redis_error_log.name
        destination_type = "cloudwatch-logs"
        log_format       = "text"
        log_type         = "engine-log"
      }
    ]
    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = log_delivery_configuration.value.log_type
    }
  }

  # Notification settings
  notification_topic_arn = var.redis_notification_topic_arn

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis"
  })
}

################################################################################
# CloudWatch Log Groups for Redis Logs
################################################################################

# Slow log group
resource "aws_cloudwatch_log_group" "redis_slow_log" {
  name              = "/aws/elasticache/${local.name_prefix}/redis/slow-log"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(local.common_tags, {
    Name = "/aws/elasticache/${local.name_prefix}/redis/slow-log"
  })
}

# Error log group
resource "aws_cloudwatch_log_group" "redis_error_log" {
  name              = "/aws/elasticache/${local.name_prefix}/redis/error-log"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(local.common_tags, {
    Name = "/aws/elasticache/${local.name_prefix}/redis/error-log"
  })
}

# Keep the existing general log group but make it conditional
resource "aws_cloudwatch_log_group" "redis" {
  count = var.create_cloudwatch_log_group && length(var.redis_log_delivery_configuration) == 0 ? 1 : 0

  name              = "/aws/elasticache/${local.name_prefix}/redis"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(local.common_tags, {
    Name = "/aws/elasticache/${local.name_prefix}/redis"
  })
}

################################################################################
# SSM Parameters for Redis Connection Details
################################################################################

resource "aws_ssm_parameter" "redis_endpoint" {
  count = var.store_connection_details_in_ssm ? 1 : 0

  name  = "/${var.environment}/${var.cluster_name}/redis/endpoint"
  type  = "String"
  value = aws_elasticache_replication_group.redis.primary_endpoint_address

  tags = local.common_tags
}

resource "aws_ssm_parameter" "redis_port" {
  count = var.store_connection_details_in_ssm ? 1 : 0

  name  = "/${var.environment}/${var.cluster_name}/redis/port"
  type  = "String"
  value = tostring(var.redis_port)

  tags = local.common_tags
}

resource "aws_ssm_parameter" "redis_auth_token" {
  count = var.store_connection_details_in_ssm && var.auth_token_enabled ? 1 : 0

  name  = "/${var.environment}/${var.cluster_name}/redis/auth_token"
  type  = "SecureString"
  value = random_password.redis_auth_token[0].result

  tags = local.common_tags
}

resource "aws_ssm_parameter" "redis_connection_string" {
  count = var.store_connection_details_in_ssm ? 1 : 0

  name  = "/${var.environment}/${var.cluster_name}/redis/connection_string"
  type  = "SecureString"
  value = (
    var.auth_token_enabled ?
    "redis://default:${random_password.redis_auth_token[0].result}@${aws_elasticache_replication_group.redis.primary_endpoint_address}:${var.redis_port}" :
    "redis://${aws_elasticache_replication_group.redis.primary_endpoint_address}:${var.redis_port}"
  )
  tags = local.common_tags
}
