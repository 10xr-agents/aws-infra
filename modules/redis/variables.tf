# modules/redis/variables.tf

variable "cluster_name" {
  description = "Name of the cluster (used for naming resources)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where Redis will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for Redis subnet group"
  type        = list(string)
}

################################################################################
# Redis Configuration
################################################################################

variable "redis_node_type" {
  description = "Node type for Redis instances"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_family" {
  description = "Redis parameter group family"
  type        = string
  default     = "redis7"
}

variable "redis_port" {
  description = "Port for Redis"
  type        = number
  default     = 6379
}

variable "redis_num_cache_clusters" {
  description = "Number of cache clusters (nodes) for replication group"
  type        = number
  default     = 2
}

################################################################################
# High Availability & Backup
################################################################################

variable "redis_multi_az_enabled" {
  description = "Enable Multi-AZ for Redis"
  type        = bool
  default     = true
}

variable "redis_automatic_failover_enabled" {
  description = "Enable automatic failover for Redis"
  type        = bool
  default     = true
}

variable "redis_snapshot_retention_limit" {
  description = "Number of days to retain snapshots (0 for no snapshots)"
  type        = number
  default     = 1
}

variable "redis_snapshot_window" {
  description = "Daily time range for snapshots (UTC)"
  type        = string
  default     = "03:00-05:00"
}

variable "redis_maintenance_window" {
  description = "Weekly time range for maintenance (UTC)"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

################################################################################
# Security
################################################################################

variable "create_security_group" {
  description = "Whether to create a security group for Redis"
  type        = bool
  default     = true
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with Redis (if not creating new one)"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access Redis"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access Redis"
  type        = list(string)
  default     = []
}

variable "additional_ingress_rules" {
  description = "Additional ingress rules for Redis security group"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = list(string)
  }))
  default = []
}

variable "auth_token_enabled" {
  description = "Whether to enable Redis AUTH token (password)"
  type        = bool
  default     = true
}

variable "auth_token_length" {
  description = "Length of the Redis AUTH token"
  type        = number
  default     = 64
}

variable "auth_token_special_chars" {
  description = "Whether to include special characters in AUTH token"
  type        = bool
  default     = false
}

variable "redis_transit_encryption_enabled" {
  description = "Enable encryption in transit for Redis"
  type        = bool
  default     = true
}

variable "redis_at_rest_encryption_enabled" {
  description = "Enable encryption at rest for Redis"
  type        = bool
  default     = true
}

variable "redis_kms_key_id" {
  description = "KMS key ID for Redis encryption (if not specified, uses default key)"
  type        = string
  default     = null
}

################################################################################
# Parameters - Optimized for temporary data/caching
################################################################################

variable "redis_parameters" {
  description = "List of Redis parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    },
    {
      name  = "timeout"
      value = "300"
    },
    {
      name  = "tcp-keepalive"
      value = "300"
    }
  ]
}

################################################################################
# Monitoring & Logging
################################################################################

variable "create_cloudwatch_log_group" {
  description = "Whether to create CloudWatch log group for Redis"
  type        = bool
  default     = true
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs. HIPAA requires 6 years (2192 days) for audit logs."
  type        = number
  default     = 2192 # 6 years - HIPAA compliance requirement
}

variable "redis_log_delivery_configuration" {
  description = "Redis log delivery configuration"
  type = list(object({
    destination      = string
    destination_type = string
    log_format       = string
    log_type         = string
  }))
  default = []
}

variable "redis_notification_topic_arn" {
  description = "SNS topic ARN for Redis notifications"
  type        = string
  default     = null
}

################################################################################
# SSM Integration
################################################################################

variable "store_connection_details_in_ssm" {
  description = "Whether to store Redis connection details in SSM Parameter Store"
  type        = bool
  default     = true
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}