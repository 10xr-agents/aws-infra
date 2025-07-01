# modules/redis/outputs.tf

################################################################################
# Redis Cluster Outputs
################################################################################

output "redis_replication_group_arn" {
  description = "ARN of the Redis replication group"
  value       = var.redis_cluster_mode ? try(aws_elasticache_replication_group.redis_cluster[0].arn, null) : try(aws_elasticache_replication_group.redis[0].arn, null)
}

output "redis_replication_group_id" {
  description = "ID of the Redis replication group"
  value       = var.redis_cluster_mode ? try(aws_elasticache_replication_group.redis_cluster[0].id, null) : try(aws_elasticache_replication_group.redis[0].id, null)
}

################################################################################
# Connection Information
################################################################################

output "redis_endpoint" {
  description = "Redis endpoint address"
  value       = var.redis_cluster_mode ? try(aws_elasticache_replication_group.redis_cluster[0].configuration_endpoint_address, null) : try(aws_elasticache_replication_group.redis[0].configuration_endpoint_address, null)
}

output "redis_primary_endpoint" {
  description = "Redis primary endpoint address"
  value       = var.redis_cluster_mode ? null : try(aws_elasticache_replication_group.redis[0].primary_endpoint_address, null)
}

output "redis_reader_endpoint" {
  description = "Redis reader endpoint address"
  value       = var.redis_cluster_mode ? null : try(aws_elasticache_replication_group.redis[0].reader_endpoint_address, null)
}

output "redis_port" {
  description = "Redis port"
  value       = var.redis_port
}

output "redis_configuration_endpoint" {
  description = "Redis configuration endpoint (for cluster mode)"
  value       = var.redis_cluster_mode ? try(aws_elasticache_replication_group.redis_cluster[0].configuration_endpoint_address, null) : null
}

################################################################################
# Connection Strings
################################################################################

output "redis_connection_string" {
  description = "Redis connection string"
  value       = var.auth_token_enabled ? "redis://default:${try(random_password.redis_auth_token[0].result, "")}@${var.redis_cluster_mode ? try(aws_elasticache_replication_group.redis_cluster[0].configuration_endpoint_address, "") : try(aws_elasticache_replication_group.redis[0].configuration_endpoint_address, "")}:${var.redis_port}" : "redis://${var.redis_cluster_mode ? try(aws_elasticache_replication_group.redis_cluster[0].configuration_endpoint_address, "") : try(aws_elasticache_replication_group.redis[0].configuration_endpoint_address, "")}:${var.redis_port}"
  sensitive   = true
}

output "redis_url" {
  description = "Redis URL for applications"
  value       = var.auth_token_enabled ? "redis://default:${try(random_password.redis_auth_token[0].result, "")}@${var.redis_cluster_mode ? try(aws_elasticache_replication_group.redis_cluster[0].configuration_endpoint_address, "") : try(aws_elasticache_replication_group.redis[0].configuration_endpoint_address, "")}:${var.redis_port}" : "redis://${var.redis_cluster_mode ? try(aws_elasticache_replication_group.redis_cluster[0].configuration_endpoint_address, "") : try(aws_elasticache_replication_group.redis[0].configuration_endpoint_address, "")}:${var.redis_port}"
  sensitive   = true
}

################################################################################
# Authentication
################################################################################

output "redis_auth_token" {
  description = "Redis AUTH token (password)"
  value       = var.auth_token_enabled ? try(random_password.redis_auth_token[0].result, null) : null
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
  value       = var.create_security_group ? try(aws_security_group.redis[0].id, null) : null
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
  value       = var.redis_cluster_mode ? null : var.redis_num_cache_clusters
}

output "redis_cluster_mode_enabled" {
  description = "Whether Redis cluster mode is enabled"
  value       = var.redis_cluster_mode
}

output "redis_num_node_groups" {
  description = "Number of node groups (shards) in cluster mode"
  value       = var.redis_cluster_mode ? var.redis_num_node_groups : null
}

output "redis_replicas_per_node_group" {
  description = "Number of replicas per node group in cluster mode"
  value       = var.redis_cluster_mode ? var.redis_replicas_per_node_group : null
}

################################################################################
# Member Clusters (for non-cluster mode)
################################################################################

output "redis_member_clusters" {
  description = "List of member cluster IDs"
  value       = var.redis_cluster_mode ? null : try(aws_elasticache_replication_group.redis[0].member_clusters, [])
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
# CloudWatch Log Group
################################################################################

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for Redis"
  value       = var.create_cloudwatch_log_group ? try(aws_cloudwatch_log_group.redis[0].name, null) : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for Redis"
  value       = var.create_cloudwatch_log_group ? try(aws_cloudwatch_log_group.redis[0].arn, null) : null
}

################################################################################
# Summary Output for Easy Reference
################################################################################

output "redis_cluster_details" {
  description = "Complete Redis cluster details"
  value = {
    endpoint                    = var.redis_cluster_mode ? try(aws_elasticache_replication_group.redis_cluster[0].configuration_endpoint_address, null) : try(aws_elasticache_replication_group.redis[0].configuration_endpoint_address, null)
    primary_endpoint           = var.redis_cluster_mode ? null : try(aws_elasticache_replication_group.redis[0].primary_endpoint_address, null)
    reader_endpoint            = var.redis_cluster_mode ? null : try(aws_elasticache_replication_group.redis[0].reader_endpoint_address, null)
    port                       = var.redis_port
    cluster_mode_enabled       = var.redis_cluster_mode
    auth_token_enabled         = var.auth_token_enabled
    transit_encryption_enabled = var.redis_transit_encryption_enabled
    at_rest_encryption_enabled = var.redis_at_rest_encryption_enabled
    multi_az_enabled           = var.redis_multi_az_enabled
    node_type                  = var.redis_node_type
    engine_version             = var.redis_engine_version
    replication_group_id       = var.redis_cluster_mode ? try(aws_elasticache_replication_group.redis_cluster[0].id, null) : try(aws_elasticache_replication_group.redis[0].id, null)
  }
}