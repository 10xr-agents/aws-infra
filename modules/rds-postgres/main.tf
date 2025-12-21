#------------------------------------------------------------------------------
# RDS PostgreSQL Module - Main Configuration
# HIPAA-compliant PostgreSQL database for n8n workflow automation
#------------------------------------------------------------------------------

locals {
  name_prefix = "${var.identifier}-${var.environment}"

  default_tags = merge(var.tags, {
    Module      = "rds-postgres"
    Environment = var.environment
  })
}

#------------------------------------------------------------------------------
# KMS Key for Encryption
#------------------------------------------------------------------------------

resource "aws_kms_key" "rds" {
  count = var.kms_key_id == null ? 1 : 0

  description             = "KMS key for RDS PostgreSQL encryption - ${local.name_prefix}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-rds-kms"
  })
}

resource "aws_kms_alias" "rds" {
  count = var.kms_key_id == null ? 1 : 0

  name          = "alias/${local.name_prefix}-rds"
  target_key_id = aws_kms_key.rds[0].key_id
}

locals {
  kms_key_id = var.kms_key_id != null ? var.kms_key_id : aws_kms_key.rds[0].arn
}

#------------------------------------------------------------------------------
# Security Group
#------------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name_prefix = "${local.name_prefix}-rds-"
  description = "Security group for RDS PostgreSQL - ${local.name_prefix}"
  vpc_id      = var.vpc_id

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_sg" {
  for_each = toset(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from allowed security groups"
  from_port                    = var.port
  to_port                      = var.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = each.value

  tags = local.default_tags
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_cidr" {
  for_each = toset(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.rds.id
  description       = "PostgreSQL from allowed CIDR blocks"
  from_port         = var.port
  to_port           = var.port
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value

  tags = local.default_tags
}

#------------------------------------------------------------------------------
# DB Subnet Group
#------------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name_prefix = "${local.name_prefix}-"
  description = "DB subnet group for ${local.name_prefix}"
  subnet_ids  = var.database_subnet_ids

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-subnet-group"
  })
}

#------------------------------------------------------------------------------
# Parameter Group
#------------------------------------------------------------------------------

resource "aws_db_parameter_group" "this" {
  name_prefix = "${local.name_prefix}-"
  family      = var.parameter_group_family
  description = "Parameter group for ${local.name_prefix}"

  # HIPAA-compliant logging settings
  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_checkpoints"
    value = "1"
  }

  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # Log queries taking > 1 second
  }

  # Additional custom parameters
  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-parameter-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

#------------------------------------------------------------------------------
# Secrets Manager - Database Credentials
#------------------------------------------------------------------------------

resource "random_password" "master_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name_prefix = "${local.name_prefix}-rds-credentials-"
  description = "RDS PostgreSQL credentials for ${local.name_prefix}"
  kms_key_id  = local.kms_key_id

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-rds-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username              = "n8nadmin"
    password              = random_password.master_password.result
    engine                = "postgres"
    host                  = aws_db_instance.this.address
    port                  = var.port
    dbname                = var.database_name
    connection_string     = "postgresql://n8nadmin:${random_password.master_password.result}@${aws_db_instance.this.address}:${var.port}/${var.database_name}?sslmode=require"
    connection_string_ecs = "postgres://n8nadmin:${random_password.master_password.result}@${aws_db_instance.this.address}:${var.port}/${var.database_name}?sslmode=require"
  })

  depends_on = [aws_db_instance.this]
}

#------------------------------------------------------------------------------
# IAM Role for Enhanced Monitoring
#------------------------------------------------------------------------------

resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name_prefix = "${local.name_prefix}-rds-monitoring-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-rds-monitoring-role"
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

#------------------------------------------------------------------------------
# RDS PostgreSQL Instance
#------------------------------------------------------------------------------

resource "aws_db_instance" "this" {
  identifier = local.name_prefix

  # Engine
  engine               = "postgres"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  parameter_group_name = aws_db_parameter_group.this.name

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.storage_encrypted ? local.kms_key_id : null

  # Database
  db_name  = var.database_name
  username = "n8nadmin"
  password = random_password.master_password.result
  port     = var.port

  # Network
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  # Backup
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}-${var.final_snapshot_identifier_prefix}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  copy_tags_to_snapshot     = true
  deletion_protection       = var.deletion_protection

  # Logging
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Monitoring
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? local.kms_key_id : null
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  # IAM
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # Updates
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = false

  tags = merge(local.default_tags, {
    Name = local.name_prefix
  })

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier
    ]
  }
}

#------------------------------------------------------------------------------
# CloudWatch Log Groups (with HIPAA retention)
#------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "rds" {
  for_each = toset(var.enabled_cloudwatch_logs_exports)

  name              = "/aws/rds/instance/${local.name_prefix}/${each.value}"
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = local.kms_key_id

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-${each.value}-logs"
  })
}

#------------------------------------------------------------------------------
# CloudWatch Alarms
#------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "cpu" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-cpu-utilization"
  alarm_description   = "RDS CPU utilization exceeds ${var.alarm_cpu_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.alarm_cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.identifier
  }

  actions_enabled = var.alarm_sns_topic_arn != null
  alarm_actions   = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions      = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = local.default_tags
}

resource "aws_cloudwatch_metric_alarm" "memory" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-freeable-memory"
  alarm_description   = "RDS freeable memory below ${var.alarm_memory_threshold / 1000000}MB"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.alarm_memory_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.identifier
  }

  actions_enabled = var.alarm_sns_topic_arn != null
  alarm_actions   = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions      = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = local.default_tags
}

resource "aws_cloudwatch_metric_alarm" "storage" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-free-storage"
  alarm_description   = "RDS free storage below ${var.alarm_storage_threshold / 1000000000}GB"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.alarm_storage_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.identifier
  }

  actions_enabled = var.alarm_sns_topic_arn != null
  alarm_actions   = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions      = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = local.default_tags
}

resource "aws_cloudwatch_metric_alarm" "connections" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-database-connections"
  alarm_description   = "RDS database connections exceed ${var.alarm_connections_threshold}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.alarm_connections_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.identifier
  }

  actions_enabled = var.alarm_sns_topic_arn != null
  alarm_actions   = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions      = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = local.default_tags
}
