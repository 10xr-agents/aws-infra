#------------------------------------------------------------------------------
# n8n Module - Outputs
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Service URLs
#------------------------------------------------------------------------------

output "main_url" {
  description = "URL for n8n main UI"
  value       = "https://${var.main_host_header}"
}

output "webhook_url" {
  description = "URL for n8n webhooks"
  value       = "https://${var.webhook_host_header}"
}

#------------------------------------------------------------------------------
# ECS Services
#------------------------------------------------------------------------------

output "main_service_name" {
  description = "Name of the n8n main ECS service"
  value       = aws_ecs_service.n8n_main.name
}

output "main_service_arn" {
  description = "ARN of the n8n main ECS service"
  value       = aws_ecs_service.n8n_main.id
}

output "webhook_service_name" {
  description = "Name of the n8n webhook ECS service"
  value       = aws_ecs_service.n8n_webhook.name
}

output "webhook_service_arn" {
  description = "ARN of the n8n webhook ECS service"
  value       = aws_ecs_service.n8n_webhook.id
}

output "worker_service_name" {
  description = "Name of the n8n worker ECS service"
  value       = aws_ecs_service.n8n_worker.name
}

output "worker_service_arn" {
  description = "ARN of the n8n worker ECS service"
  value       = aws_ecs_service.n8n_worker.id
}

#------------------------------------------------------------------------------
# Task Definitions
#------------------------------------------------------------------------------

output "main_task_definition_arn" {
  description = "ARN of the n8n main task definition"
  value       = aws_ecs_task_definition.n8n_main.arn
}

output "webhook_task_definition_arn" {
  description = "ARN of the n8n webhook task definition"
  value       = aws_ecs_task_definition.n8n_webhook.arn
}

output "worker_task_definition_arn" {
  description = "ARN of the n8n worker task definition"
  value       = aws_ecs_task_definition.n8n_worker.arn
}

#------------------------------------------------------------------------------
# Security Groups
#------------------------------------------------------------------------------

output "main_security_group_id" {
  description = "Security group ID for n8n main service"
  value       = aws_security_group.n8n_main.id
}

output "webhook_security_group_id" {
  description = "Security group ID for n8n webhook service"
  value       = aws_security_group.n8n_webhook.id
}

output "worker_security_group_id" {
  description = "Security group ID for n8n worker service"
  value       = aws_security_group.n8n_worker.id
}

#------------------------------------------------------------------------------
# Target Groups
#------------------------------------------------------------------------------

output "main_target_group_arn" {
  description = "ARN of the n8n main target group"
  value       = aws_lb_target_group.n8n_main.arn
}

output "webhook_target_group_arn" {
  description = "ARN of the n8n webhook target group"
  value       = aws_lb_target_group.n8n_webhook.arn
}

#------------------------------------------------------------------------------
# RDS PostgreSQL
#------------------------------------------------------------------------------

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.endpoint
}

output "rds_address" {
  description = "RDS PostgreSQL address (host only)"
  value       = module.rds.address
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = module.rds.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.rds.database_name
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = module.rds.security_group_id
}

output "rds_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing RDS credentials"
  value       = module.rds.credentials_secret_arn
}

#------------------------------------------------------------------------------
# Secrets
#------------------------------------------------------------------------------

output "encryption_key_secret_arn" {
  description = "ARN of the n8n encryption key secret"
  value       = aws_secretsmanager_secret.n8n_encryption_key.arn
}

#------------------------------------------------------------------------------
# IAM
#------------------------------------------------------------------------------

output "execution_role_arn" {
  description = "ARN of the ECS execution role"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.n8n_task_role.arn
}

#------------------------------------------------------------------------------
# CloudWatch Log Groups
#------------------------------------------------------------------------------

output "main_log_group_name" {
  description = "CloudWatch log group name for n8n main"
  value       = aws_cloudwatch_log_group.n8n_main.name
}

output "webhook_log_group_name" {
  description = "CloudWatch log group name for n8n webhook"
  value       = aws_cloudwatch_log_group.n8n_webhook.name
}

output "worker_log_group_name" {
  description = "CloudWatch log group name for n8n worker"
  value       = aws_cloudwatch_log_group.n8n_worker.name
}
