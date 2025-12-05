# modules/documentdb/outputs.tf

################################################################################
# Cluster Outputs
################################################################################

output "cluster_id" {
  description = "The DocumentDB cluster identifier"
  value       = aws_docdb_cluster.main.id
}

output "cluster_arn" {
  description = "The ARN of the DocumentDB cluster"
  value       = aws_docdb_cluster.main.arn
}

output "cluster_resource_id" {
  description = "The resource ID of the DocumentDB cluster"
  value       = aws_docdb_cluster.main.cluster_resource_id
}

output "cluster_identifier" {
  description = "The DocumentDB cluster identifier"
  value       = aws_docdb_cluster.main.cluster_identifier
}

################################################################################
# Connection Outputs
################################################################################

output "endpoint" {
  description = "The primary endpoint of the DocumentDB cluster"
  value       = aws_docdb_cluster.main.endpoint
}

output "reader_endpoint" {
  description = "The reader endpoint of the DocumentDB cluster"
  value       = aws_docdb_cluster.main.reader_endpoint
}

output "port" {
  description = "The port of the DocumentDB cluster"
  value       = aws_docdb_cluster.main.port
}

output "connection_string" {
  description = "The connection string for the DocumentDB cluster (without credentials)"
  value       = "mongodb://${aws_docdb_cluster.main.endpoint}:${aws_docdb_cluster.main.port}/?tls=true&tlsCAFile=global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
}

output "master_username" {
  description = "The master username"
  value       = aws_docdb_cluster.main.master_username
}

################################################################################
# Instance Outputs
################################################################################

output "instance_ids" {
  description = "List of DocumentDB instance identifiers"
  value       = aws_docdb_cluster_instance.main[*].id
}

output "instance_arns" {
  description = "List of DocumentDB instance ARNs"
  value       = aws_docdb_cluster_instance.main[*].arn
}

output "instance_endpoints" {
  description = "List of DocumentDB instance endpoints"
  value       = aws_docdb_cluster_instance.main[*].endpoint
}

################################################################################
# Security Group Outputs
################################################################################

output "security_group_id" {
  description = "The security group ID for DocumentDB"
  value       = var.create_security_group ? aws_security_group.documentdb[0].id : null
}

output "security_group_arn" {
  description = "The security group ARN for DocumentDB"
  value       = var.create_security_group ? aws_security_group.documentdb[0].arn : null
}

################################################################################
# KMS Key Outputs
################################################################################

output "kms_key_id" {
  description = "The KMS key ID used for encryption"
  value       = var.create_kms_key ? aws_kms_key.documentdb[0].key_id : var.kms_key_id
}

output "kms_key_arn" {
  description = "The KMS key ARN used for encryption"
  value       = var.create_kms_key ? aws_kms_key.documentdb[0].arn : null
}

################################################################################
# Subnet Group Outputs
################################################################################

output "subnet_group_name" {
  description = "The name of the DocumentDB subnet group"
  value       = aws_docdb_subnet_group.main.name
}

output "subnet_group_arn" {
  description = "The ARN of the DocumentDB subnet group"
  value       = aws_docdb_subnet_group.main.arn
}

################################################################################
# Parameter Group Outputs
################################################################################

output "parameter_group_name" {
  description = "The name of the DocumentDB parameter group"
  value       = aws_docdb_cluster_parameter_group.main.name
}

output "parameter_group_arn" {
  description = "The ARN of the DocumentDB parameter group"
  value       = aws_docdb_cluster_parameter_group.main.arn
}

################################################################################
# SSM Parameter Outputs
################################################################################

output "ssm_parameter_endpoint_name" {
  description = "The SSM parameter name for the endpoint"
  value       = var.ssm_parameter_enabled ? aws_ssm_parameter.documentdb_endpoint[0].name : null
}

output "ssm_parameter_connection_string_name" {
  description = "The SSM parameter name for the connection string"
  value       = var.ssm_parameter_enabled ? aws_ssm_parameter.documentdb_connection_string[0].name : null
}

################################################################################
# Secrets Manager Outputs
################################################################################

output "secrets_manager_secret_arn" {
  description = "The ARN of the Secrets Manager secret"
  value       = var.secrets_manager_enabled ? aws_secretsmanager_secret.documentdb[0].arn : null
}

output "secrets_manager_secret_name" {
  description = "The name of the Secrets Manager secret"
  value       = var.secrets_manager_enabled ? aws_secretsmanager_secret.documentdb[0].name : null
}

################################################################################
# IAM Policy Outputs
################################################################################

output "iam_policy_arn" {
  description = "The ARN of the IAM policy for DocumentDB access"
  value       = var.create_iam_policy ? aws_iam_policy.documentdb_access[0].arn : null
}

output "iam_policy_name" {
  description = "The name of the IAM policy for DocumentDB access"
  value       = var.create_iam_policy ? aws_iam_policy.documentdb_access[0].name : null
}

################################################################################
# CloudWatch Log Group Outputs
################################################################################

output "audit_log_group_name" {
  description = "The name of the audit CloudWatch log group"
  value       = contains(var.enabled_cloudwatch_logs_exports, "audit") ? aws_cloudwatch_log_group.documentdb_audit[0].name : null
}

output "profiler_log_group_name" {
  description = "The name of the profiler CloudWatch log group"
  value       = contains(var.enabled_cloudwatch_logs_exports, "profiler") ? aws_cloudwatch_log_group.documentdb_profiler[0].name : null
}

################################################################################
# ECS Environment Variables (for easy integration)
################################################################################

output "ecs_environment_variables" {
  description = "Environment variables for ECS task definitions"
  value = {
    DOCUMENTDB_HOST            = aws_docdb_cluster.main.endpoint
    DOCUMENTDB_READER_HOST     = aws_docdb_cluster.main.reader_endpoint
    DOCUMENTDB_PORT            = tostring(aws_docdb_cluster.main.port)
    DOCUMENTDB_TLS_ENABLED     = var.tls_enabled ? "true" : "false"
    DOCUMENTDB_DATABASE        = "admin"
  }
}

output "ecs_secrets" {
  description = "Secret references for ECS task definitions (Secrets Manager)"
  value = var.secrets_manager_enabled ? {
    DOCUMENTDB_USERNAME = "${aws_secretsmanager_secret.documentdb[0].arn}:username::"
    DOCUMENTDB_PASSWORD = "${aws_secretsmanager_secret.documentdb[0].arn}:password::"
    DOCUMENTDB_CONNECTION_STRING = "${aws_secretsmanager_secret.documentdb[0].arn}:connection_string::"
  } : {}
}

output "ecs_secrets_ssm" {
  description = "Secret references for ECS task definitions (SSM Parameter Store)"
  value = var.ssm_parameter_enabled ? {
    DOCUMENTDB_USERNAME = aws_ssm_parameter.documentdb_username[0].arn
    DOCUMENTDB_PASSWORD = aws_ssm_parameter.documentdb_password[0].arn
    DOCUMENTDB_CONNECTION_STRING = aws_ssm_parameter.documentdb_connection_string[0].arn
  } : {}
}
