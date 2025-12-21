#------------------------------------------------------------------------------
# RDS PostgreSQL Module - Outputs
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Instance Information
#------------------------------------------------------------------------------

output "instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.this.id
}

output "instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.this.arn
}

output "instance_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.identifier
}

output "instance_resource_id" {
  description = "RDS instance resource ID"
  value       = aws_db_instance.this.resource_id
}

#------------------------------------------------------------------------------
# Connection Information
#------------------------------------------------------------------------------

output "endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "RDS instance address (host only)"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS instance port"
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Name of the database"
  value       = aws_db_instance.this.db_name
}

#------------------------------------------------------------------------------
# Security
#------------------------------------------------------------------------------

output "security_group_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}

output "kms_key_id" {
  description = "KMS key ID used for encryption"
  value       = local.kms_key_id
}

output "kms_key_arn" {
  description = "KMS key ARN used for encryption"
  value       = var.kms_key_id != null ? var.kms_key_id : aws_kms_key.rds[0].arn
}

#------------------------------------------------------------------------------
# Secrets Manager
#------------------------------------------------------------------------------

output "credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing credentials"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

output "credentials_secret_name" {
  description = "Name of the Secrets Manager secret containing credentials"
  value       = aws_secretsmanager_secret.rds_credentials.name
}

#------------------------------------------------------------------------------
# ECS Integration - Secrets for Task Definition
#------------------------------------------------------------------------------

output "ecs_secrets" {
  description = "Secrets configuration for ECS task definitions"
  value = {
    DB_POSTGRESDB_USER = {
      name      = "DB_POSTGRESDB_USER"
      valueFrom = "${aws_secretsmanager_secret.rds_credentials.arn}:username::"
    }
    DB_POSTGRESDB_PASSWORD = {
      name      = "DB_POSTGRESDB_PASSWORD"
      valueFrom = "${aws_secretsmanager_secret.rds_credentials.arn}:password::"
    }
    DATABASE_URL = {
      name      = "DATABASE_URL"
      valueFrom = "${aws_secretsmanager_secret.rds_credentials.arn}:connection_string_ecs::"
    }
  }
}

#------------------------------------------------------------------------------
# ECS Integration - Environment Variables
#------------------------------------------------------------------------------

output "ecs_environment" {
  description = "Environment variables for ECS task definitions"
  value = {
    DB_TYPE                   = "postgresdb"
    DB_POSTGRESDB_HOST        = aws_db_instance.this.address
    DB_POSTGRESDB_PORT        = tostring(aws_db_instance.this.port)
    DB_POSTGRESDB_DATABASE    = aws_db_instance.this.db_name
    DB_POSTGRESDB_SSL_ENABLED = "true"
  }
}

#------------------------------------------------------------------------------
# IAM Policy for ECS Task Access
#------------------------------------------------------------------------------

output "ecs_task_policy_arn" {
  description = "IAM policy ARN for ECS task access to RDS secrets"
  value       = aws_iam_policy.ecs_task_access.arn
}

resource "aws_iam_policy" "ecs_task_access" {
  name_prefix = "${var.identifier}-${var.environment}-rds-access-"
  description = "IAM policy for ECS tasks to access RDS PostgreSQL secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.rds_credentials.arn
        ]
      },
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          local.kms_key_id
        ]
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

data "aws_region" "current" {}

#------------------------------------------------------------------------------
# Subnet Group
#------------------------------------------------------------------------------

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.this.name
}

output "db_subnet_group_arn" {
  description = "ARN of the DB subnet group"
  value       = aws_db_subnet_group.this.arn
}

#------------------------------------------------------------------------------
# Parameter Group
#------------------------------------------------------------------------------

output "parameter_group_name" {
  description = "Name of the DB parameter group"
  value       = aws_db_parameter_group.this.name
}

output "parameter_group_arn" {
  description = "ARN of the DB parameter group"
  value       = aws_db_parameter_group.this.arn
}
