# modules/redis/outputs.tf

################################################################################
# Redis Replication Group Outputs
################################################################################

output "redis_replication_group_arn" {
  description = "ARN of the Redis replication group"
  value       = aws_elasticache_replication_group.redis.arn
}

output "redis_replication_group_id" {
  description = "ID of the Redis replication group"
  value       = aws_elasticache_replication_group.redis.id
}

################################################################################
# Connection Information
################################################################################

output "redis_primary_endpoint" {
  description = "Redis primary endpoint address"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Redis reader endpoint address"
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = var.redis_port
}

################################################################################
# Connection Strings
################################################################################

output "redis_connection_string" {
  description = "Redis connection string"
  value       = "redis://${aws_elasticache_replication_group.redis.primary_endpoint_address}:${var.redis_port}"
  sensitive = true
}

output "redis_url" {
  description = "Redis URL for applications"
  value       = "redis://${aws_elasticache_replication_group.redis.primary_endpoint_address}:${var.redis_port}"
  sensitive = true
}

################################################################################
# Authentication
################################################################################

output "redis_auth_token" {
  description = "Redis AUTH token (password)"
  value       = var.auth_token_enabled ? random_password.redis_auth_token[0].result : null
  sensitive   = true
}

output "redis_username" {
  description = "Redis username (always 'default' for ElastiCache)"
  value       = "default"
}

################################################################################
# Infrastructure Details
################################################################################

output "redis_subnet_group_name" {
  description = "Name of the Redis subnet group"
  value       = aws_elasticache_subnet_group.redis.name
}

output "redis_parameter_group_name" {
  description = "Name of the Redis parameter group"
  value       = aws_elasticache_parameter_group.redis.name
}

output "redis_security_group_id" {
  description = "ID of the Redis security group"
  value       = var.create_security_group ? aws_security_group.redis[0].id : null
}

output "redis_security_group_ids" {
  description = "List of security group IDs associated with Redis"
  value       = var.create_security_group ? [aws_security_group.redis[0].id] : var.security_group_ids
}

################################################################################
# Cluster Information
################################################################################

output "redis_node_type" {
  description = "Node type of Redis instances"
  value       = var.redis_node_type
}

output "redis_engine_version" {
  description = "Redis engine version"
  value       = var.redis_engine_version
}

output "redis_num_cache_clusters" {
  description = "Number of cache clusters"
  value       = var.redis_num_cache_clusters
}

output "redis_member_clusters" {
  description = "List of member cluster IDs"
  value       = aws_elasticache_replication_group.redis.member_clusters
}

################################################################################
# Configuration Details
################################################################################

output "redis_multi_az_enabled" {
  description = "Whether Multi-AZ is enabled"
  value       = var.redis_multi_az_enabled
}

output "redis_automatic_failover_enabled" {
  description = "Whether automatic failover is enabled"
  value       = var.redis_automatic_failover_enabled
}

output "redis_transit_encryption_enabled" {
  description = "Whether transit encryption is enabled"
  value       = var.redis_transit_encryption_enabled
}

output "redis_at_rest_encryption_enabled" {
  description = "Whether at-rest encryption is enabled"
  value       = var.redis_at_rest_encryption_enabled
}

################################################################################
# SSM Parameter Store References
################################################################################

output "ssm_parameter_redis_endpoint" {
  description = "SSM parameter name for Redis endpoint"
  value       = var.store_connection_details_in_ssm ? "/${var.environment}/${var.cluster_name}/redis/endpoint" : null
}

output "ssm_parameter_redis_port" {
  description = "SSM parameter name for Redis port"
  value       = var.store_connection_details_in_ssm ? "/${var.environment}/${var.cluster_name}/redis/port" : null
}

output "ssm_parameter_redis_auth_token" {
  description = "SSM parameter name for Redis auth token"
  value       = var.store_connection_details_in_ssm && var.auth_token_enabled ? "/${var.environment}/${var.cluster_name}/redis/auth_token" : null
}

output "ssm_parameter_redis_connection_string" {
  description = "SSM parameter name for Redis connection string"
  value       = var.store_connection_details_in_ssm ? "/${var.environment}/${var.cluster_name}/redis/connection_string" : null
}

################################################################################
# CloudWatch Log Groups
################################################################################

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for Redis (general)"
  value       = var.create_cloudwatch_log_group && length(var.redis_log_delivery_configuration) == 0 ? aws_cloudwatch_log_group.redis[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for Redis (general)"
  value       = var.create_cloudwatch_log_group && length(var.redis_log_delivery_configuration) == 0 ? aws_cloudwatch_log_group.redis[0].arn : null
}

output "cloudwatch_slow_log_group_name" {
  description = "Name of the CloudWatch log group for Redis slow logs"
  value       = aws_cloudwatch_log_group.redis_slow_log.name
}

output "cloudwatch_slow_log_group_arn" {
  description = "ARN of the CloudWatch log group for Redis slow logs"
  value       = aws_cloudwatch_log_group.redis_slow_log.arn
}

output "cloudwatch_error_log_group_name" {
  description = "Name of the CloudWatch log group for Redis error logs"
  value       = aws_cloudwatch_log_group.redis_error_log.name
}

output "cloudwatch_error_log_group_arn" {
  description = "ARN of the CloudWatch log group for Redis error logs"
  value       = aws_cloudwatch_log_group.redis_error_log.arn
}

################################################################################
# Summary Output for Easy Reference
################################################################################

# Update the redis_details output to include logging info
output "redis_details" {
  description = "Complete Redis details"
  value = {
    primary_endpoint           = aws_elasticache_replication_group.redis.primary_endpoint_address
    reader_endpoint            = aws_elasticache_replication_group.redis.reader_endpoint_address
    port                       = var.redis_port
    auth_token_enabled         = var.auth_token_enabled
    transit_encryption_enabled = var.redis_transit_encryption_enabled
    at_rest_encryption_enabled = var.redis_at_rest_encryption_enabled
    multi_az_enabled           = var.redis_multi_az_enabled
    node_type                  = var.redis_node_type
    engine_version             = var.redis_engine_version
    replication_group_id       = aws_elasticache_replication_group.redis.id
    logging_enabled            = true
    slow_log_group             = aws_cloudwatch_log_group.redis_slow_log.name
    error_log_group            = aws_cloudwatch_log_group.redis_error_log.name
  }
}