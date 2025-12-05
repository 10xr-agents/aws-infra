# modules/documentdb/main.tf
#
# Amazon DocumentDB Cluster Module
# HIPAA-compliant configuration with encryption at rest and in transit
#
# References:
# - https://docs.aws.amazon.com/documentdb/latest/developerguide/db-instance-classes.html
# - https://docs.aws.amazon.com/documentdb/latest/developerguide/security.encryption.ssl.html

locals {
  name_prefix = "${var.cluster_name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Component   = "DocumentDB"
      ManagedBy   = "terraform"
    }
  )
}

################################################################################
# Data Sources
################################################################################

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

################################################################################
# KMS Key for Encryption at Rest
################################################################################

resource "aws_kms_key" "documentdb" {
  count = var.create_kms_key ? 1 : 0

  description             = "KMS key for DocumentDB encryption - ${local.name_prefix}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.kms_key_enable_rotation

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow DocumentDB to use the key"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-documentdb-kms"
  })
}

resource "aws_kms_alias" "documentdb" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${local.name_prefix}-documentdb"
  target_key_id = aws_kms_key.documentdb[0].key_id
}

################################################################################
# Random Password for Master User
################################################################################

resource "random_password" "master_password" {
  count = var.master_password == "" ? 1 : 0

  length           = var.password_length
  special          = false
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "documentdb" {
  count = var.create_security_group ? 1 : 0

  name        = "${local.name_prefix}-documentdb-sg"
  description = "Security group for DocumentDB cluster ${local.name_prefix}"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-documentdb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Ingress from allowed CIDR blocks
resource "aws_security_group_rule" "documentdb_ingress_cidr" {
  count = var.create_security_group && length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = var.db_port
  to_port           = var.db_port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.documentdb[0].id
  description       = "DocumentDB access from allowed CIDR blocks"
}

# Ingress from allowed security groups
resource "aws_security_group_rule" "documentdb_ingress_sg" {
  for_each = var.create_security_group ? toset(var.allowed_security_group_ids) : toset([])

  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.documentdb[0].id
  description              = "DocumentDB access from security group ${each.value}"
}

# Egress - allow all outbound
resource "aws_security_group_rule" "documentdb_egress" {
  count = var.create_security_group ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.documentdb[0].id
  description       = "All outbound traffic"
}

################################################################################
# Subnet Group
################################################################################

resource "aws_docdb_subnet_group" "main" {
  name        = "${local.name_prefix}-documentdb-subnet-group"
  description = "DocumentDB subnet group for ${local.name_prefix}"
  subnet_ids  = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-documentdb-subnet-group"
  })
}

################################################################################
# Cluster Parameter Group
################################################################################

resource "aws_docdb_cluster_parameter_group" "main" {
  name        = "${local.name_prefix}-documentdb-params"
  family      = var.cluster_family
  description = "DocumentDB cluster parameter group for ${local.name_prefix}"

  # TLS enforcement for encryption in transit (HIPAA requirement)
  parameter {
    name  = "tls"
    value = var.tls_enabled ? "enabled" : "disabled"
  }

  # Audit logging for HIPAA compliance
  parameter {
    name  = "audit_logs"
    value = var.audit_logs_enabled ? "enabled" : "disabled"
  }

  # TTL Monitor
  parameter {
    name  = "ttl_monitor"
    value = var.ttl_monitor_enabled ? "enabled" : "disabled"
  }

  # Profiler for slow query logging
  parameter {
    name  = "profiler"
    value = var.profiler_enabled ? "enabled" : "disabled"
  }

  parameter {
    name  = "profiler_threshold_ms"
    value = tostring(var.profiler_threshold_ms)
  }

  # Additional custom parameters
  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", "immediate")
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-documentdb-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# DocumentDB Cluster
################################################################################

resource "aws_docdb_cluster" "main" {
  cluster_identifier = "${local.name_prefix}-documentdb"

  # Engine configuration
  engine         = var.engine
  engine_version = var.engine_version

  # Authentication
  master_username = var.master_username
  master_password = var.master_password != "" ? var.master_password : random_password.master_password[0].result

  # Network configuration
  db_subnet_group_name   = aws_docdb_subnet_group.main.name
  vpc_security_group_ids = var.create_security_group ? [aws_security_group.documentdb[0].id] : var.security_group_ids
  port                   = var.db_port

  # Parameter group
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name

  # Encryption at rest (HIPAA requirement)
  storage_encrypted = true
  kms_key_id        = var.create_kms_key ? aws_kms_key.documentdb[0].arn : var.kms_key_id

  # Storage type
  storage_type = var.storage_type

  # Backup configuration
  backup_retention_period   = var.backup_retention_period
  preferred_backup_window   = var.preferred_backup_window
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}-documentdb-final-snapshot"

  # Maintenance
  preferred_maintenance_window = var.preferred_maintenance_window
  apply_immediately            = var.apply_immediately

  # Deletion protection
  deletion_protection = var.deletion_protection

  # CloudWatch Logs exports for HIPAA audit requirements
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Snapshot restore (if specified)
  snapshot_identifier = var.snapshot_identifier

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-documentdb"
  })

  depends_on = [
    aws_docdb_subnet_group.main,
    aws_docdb_cluster_parameter_group.main
  ]
}

################################################################################
# DocumentDB Cluster Instances
################################################################################

resource "aws_docdb_cluster_instance" "main" {
  count = var.cluster_size

  identifier         = "${local.name_prefix}-documentdb-${count.index}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = var.instance_class

  # Auto minor version upgrade
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Preferred maintenance window (can be different per instance)
  preferred_maintenance_window = var.preferred_maintenance_window

  # Apply changes immediately
  apply_immediately = var.apply_immediately

  # Enable performance insights (if supported)
  enable_performance_insights = var.enable_performance_insights

  # Promotion tier for failover priority (lower = higher priority)
  promotion_tier = count.index

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-documentdb-${count.index}"
  })
}

################################################################################
# CloudWatch Log Groups
################################################################################

resource "aws_cloudwatch_log_group" "documentdb_audit" {
  count = contains(var.enabled_cloudwatch_logs_exports, "audit") ? 1 : 0

  name              = "/aws/docdb/${local.name_prefix}-documentdb/audit"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-documentdb-audit-logs"
  })
}

resource "aws_cloudwatch_log_group" "documentdb_profiler" {
  count = contains(var.enabled_cloudwatch_logs_exports, "profiler") ? 1 : 0

  name              = "/aws/docdb/${local.name_prefix}-documentdb/profiler"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-documentdb-profiler-logs"
  })
}

################################################################################
# SSM Parameters for Connection Details
################################################################################

resource "aws_ssm_parameter" "documentdb_endpoint" {
  count = var.ssm_parameter_enabled ? 1 : 0

  name  = "/${var.environment}/${var.cluster_name}/documentdb/endpoint"
  type  = "String"
  value = aws_docdb_cluster.main.endpoint

  tags = local.common_tags
}

resource "aws_ssm_parameter" "documentdb_reader_endpoint" {
  count = var.ssm_parameter_enabled ? 1 : 0

  name  = "/${var.environment}/${var.cluster_name}/documentdb/reader_endpoint"
  type  = "String"
  value = aws_docdb_cluster.main.reader_endpoint

  tags = local.common_tags
}

resource "aws_ssm_parameter" "documentdb_port" {
  count = var.ssm_parameter_enabled ? 1 : 0

  name  = "/${var.environment}/${var.cluster_name}/documentdb/port"
  type  = "String"
  value = tostring(var.db_port)

  tags = local.common_tags
}

resource "aws_ssm_parameter" "documentdb_username" {
  count = var.ssm_parameter_enabled ? 1 : 0

  name  = "/${var.environment}/${var.cluster_name}/documentdb/username"
  type  = "SecureString"
  value = var.master_username

  tags = local.common_tags
}

resource "aws_ssm_parameter" "documentdb_password" {
  count = var.ssm_parameter_enabled ? 1 : 0

  name  = "/${var.environment}/${var.cluster_name}/documentdb/password"
  type  = "SecureString"
  value = var.master_password != "" ? var.master_password : random_password.master_password[0].result

  tags = local.common_tags
}

resource "aws_ssm_parameter" "documentdb_connection_string" {
  count = var.ssm_parameter_enabled ? 1 : 0

  name = "/${var.environment}/${var.cluster_name}/documentdb/connection_string"
  type = "SecureString"
  value = format(
    "mongodb://%s:%s@%s:%s/?tls=true&tlsCAFile=global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false",
    var.master_username,
    var.master_password != "" ? var.master_password : random_password.master_password[0].result,
    aws_docdb_cluster.main.endpoint,
    var.db_port
  )

  tags = local.common_tags
}

################################################################################
# Secrets Manager for Connection Details (Alternative to SSM)
################################################################################

resource "aws_secretsmanager_secret" "documentdb" {
  count = var.secrets_manager_enabled ? 1 : 0

  name        = "${local.name_prefix}-documentdb-credentials"
  description = "DocumentDB credentials for ${local.name_prefix}"

  # KMS encryption for the secret
  kms_key_id = var.create_kms_key ? aws_kms_key.documentdb[0].arn : var.kms_key_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-documentdb-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "documentdb" {
  count = var.secrets_manager_enabled ? 1 : 0

  secret_id = aws_secretsmanager_secret.documentdb[0].id
  secret_string = jsonencode({
    username          = var.master_username
    password          = var.master_password != "" ? var.master_password : random_password.master_password[0].result
    engine            = "docdb"
    host              = aws_docdb_cluster.main.endpoint
    reader_host       = aws_docdb_cluster.main.reader_endpoint
    port              = var.db_port
    dbClusterIdentifier = aws_docdb_cluster.main.cluster_identifier
    connection_string = format(
      "mongodb://%s:%s@%s:%s/?tls=true&tlsCAFile=global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false",
      var.master_username,
      var.master_password != "" ? var.master_password : random_password.master_password[0].result,
      aws_docdb_cluster.main.endpoint,
      var.db_port
    )
  })
}

################################################################################
# IAM Policy for ECS Tasks to Access DocumentDB
################################################################################

resource "aws_iam_policy" "documentdb_access" {
  count = var.create_iam_policy ? 1 : 0

  name        = "${local.name_prefix}-documentdb-access-policy"
  description = "IAM policy for accessing DocumentDB cluster ${local.name_prefix}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DocumentDBDescribe"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances",
          "rds:DescribeDBSubnetGroups",
          "rds:ListTagsForResource"
        ]
        Resource = [
          aws_docdb_cluster.main.arn,
          "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster:${aws_docdb_cluster.main.cluster_identifier}",
          "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subgrp:${aws_docdb_subnet_group.main.name}"
        ]
      },
      {
        Sid    = "SSMParameterAccess"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/${var.cluster_name}/documentdb/*"
        ]
      },
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secrets_manager_enabled ? [
          aws_secretsmanager_secret.documentdb[0].arn
        ] : []
      },
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = var.create_kms_key ? [
          aws_kms_key.documentdb[0].arn
        ] : var.kms_key_id != "" ? [var.kms_key_id] : ["*"]
      }
    ]
  })

  tags = local.common_tags
}

################################################################################
# CloudWatch Alarms
################################################################################

resource "aws_cloudwatch_metric_alarm" "documentdb_cpu" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-documentdb-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/DocDB"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_utilization_threshold
  alarm_description   = "DocumentDB cluster CPU utilization is high"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.main.cluster_identifier
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "documentdb_memory" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-documentdb-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeableMemory"
  namespace           = "AWS/DocDB"
  period              = 300
  statistic           = "Average"
  threshold           = var.freeable_memory_threshold
  alarm_description   = "DocumentDB cluster freeable memory is low"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.main.cluster_identifier
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "documentdb_connections" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-documentdb-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/DocDB"
  period              = 300
  statistic           = "Average"
  threshold           = var.database_connections_threshold
  alarm_description   = "DocumentDB cluster connections are high"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.main.cluster_identifier
  }

  tags = local.common_tags
}
