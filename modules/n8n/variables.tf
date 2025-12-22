#------------------------------------------------------------------------------
# n8n Module - Variables
# Unified architecture for n8n workflow automation on AWS ECS Fargate
#------------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (qa, prod)"
  type        = string
}

#------------------------------------------------------------------------------
# Network Configuration
#------------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID where n8n will be deployed"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS services"
  type        = list(string)
}

variable "database_subnet_ids" {
  description = "List of database subnet IDs for RDS"
  type        = list(string)
}

#------------------------------------------------------------------------------
# ECS Cluster Configuration
#------------------------------------------------------------------------------

variable "ecs_cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

#------------------------------------------------------------------------------
# Load Balancer Configuration
#------------------------------------------------------------------------------

variable "alb_arn" {
  description = "ALB ARN for n8n services"
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB security group ID"
  type        = string
}

variable "alb_listener_arn" {
  description = "ALB HTTPS listener ARN"
  type        = string
}

variable "main_host_header" {
  description = "Host header for n8n main UI (e.g., n8n.qa.10xr.co)"
  type        = string
}

variable "webhook_host_header" {
  description = "Host header for n8n webhooks (e.g., webhook-n8n.qa.10xr.co)"
  type        = string
}

variable "listener_rule_priority_main" {
  description = "Priority for n8n main listener rule"
  type        = number
  default     = 200
}

variable "listener_rule_priority_webhook" {
  description = "Priority for n8n webhook listener rule"
  type        = number
  default     = 201
}

#------------------------------------------------------------------------------
# RDS PostgreSQL Configuration
#------------------------------------------------------------------------------

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "RDS max storage for autoscaling in GB"
  type        = number
  default     = 100
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Enable deletion protection for RDS"
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot on RDS deletion"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Redis Configuration
#------------------------------------------------------------------------------

variable "enable_redis" {
  description = "Enable Redis integration (set to true when providing Redis configuration)"
  type        = bool
  default     = true
}

variable "redis_endpoint" {
  description = "Redis endpoint (host:port) - if using existing Redis"
  type        = string
  default     = null
}

variable "redis_host" {
  description = "Redis host - if using existing Redis"
  type        = string
  default     = null
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "redis_security_group_id" {
  description = "Redis security group ID - if using existing Redis"
  type        = string
  default     = null
}

variable "redis_auth_token_secret_arn" {
  description = "Secrets Manager ARN for Redis auth token - if using existing Redis"
  type        = string
  default     = null
}

variable "enable_redis_tls" {
  description = "Enable TLS for Redis connection (must match Redis cluster transit encryption setting)"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# n8n Main Service Configuration
#------------------------------------------------------------------------------

variable "main_cpu" {
  description = "CPU units for n8n main service"
  type        = number
  default     = 512
}

variable "main_memory" {
  description = "Memory (MB) for n8n main service"
  type        = number
  default     = 1024
}

variable "main_desired_count" {
  description = "Desired count for n8n main service"
  type        = number
  default     = 1
}

variable "main_min_capacity" {
  description = "Minimum capacity for n8n main auto-scaling"
  type        = number
  default     = 1
}

variable "main_max_capacity" {
  description = "Maximum capacity for n8n main auto-scaling"
  type        = number
  default     = 3
}

variable "main_enable_auto_scaling" {
  description = "Enable auto-scaling for n8n main service"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# n8n Webhook Service Configuration
#------------------------------------------------------------------------------

variable "webhook_cpu" {
  description = "CPU units for n8n webhook service"
  type        = number
  default     = 256
}

variable "webhook_memory" {
  description = "Memory (MB) for n8n webhook service"
  type        = number
  default     = 512
}

variable "webhook_desired_count" {
  description = "Desired count for n8n webhook service"
  type        = number
  default     = 1
}

variable "webhook_min_capacity" {
  description = "Minimum capacity for n8n webhook auto-scaling"
  type        = number
  default     = 1
}

variable "webhook_max_capacity" {
  description = "Maximum capacity for n8n webhook auto-scaling"
  type        = number
  default     = 4
}

variable "webhook_enable_auto_scaling" {
  description = "Enable auto-scaling for n8n webhook service"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# n8n Worker Service Configuration
#------------------------------------------------------------------------------

variable "worker_cpu" {
  description = "CPU units for n8n worker service"
  type        = number
  default     = 512
}

variable "worker_memory" {
  description = "Memory (MB) for n8n worker service"
  type        = number
  default     = 1024
}

variable "worker_desired_count" {
  description = "Desired count for n8n worker service"
  type        = number
  default     = 1
}

variable "worker_min_capacity" {
  description = "Minimum capacity for n8n worker auto-scaling"
  type        = number
  default     = 1
}

variable "worker_max_capacity" {
  description = "Maximum capacity for n8n worker auto-scaling"
  type        = number
  default     = 6
}

variable "worker_enable_auto_scaling" {
  description = "Enable auto-scaling for n8n worker service"
  type        = bool
  default     = true
}

variable "worker_concurrency" {
  description = "Number of concurrent workflow executions per worker"
  type        = number
  default     = 5
}

#------------------------------------------------------------------------------
# n8n Application Configuration
#------------------------------------------------------------------------------

variable "n8n_image" {
  description = "n8n Docker image"
  type        = string
  default     = "n8nio/n8n"
}

variable "n8n_image_tag" {
  description = "n8n Docker image tag"
  type        = string
  default     = "latest"
}

variable "n8n_port" {
  description = "n8n application port"
  type        = number
  default     = 5678
}

variable "n8n_timezone" {
  description = "Timezone for n8n"
  type        = string
  default     = "America/New_York"
}

variable "n8n_encryption_key" {
  description = "n8n encryption key (if not provided, will be generated)"
  type        = string
  default     = null
  sensitive   = true
}

variable "n8n_basic_auth_active" {
  description = "Enable basic authentication for n8n"
  type        = bool
  default     = false
}

variable "n8n_basic_auth_user" {
  description = "Basic auth username (if enabled)"
  type        = string
  default     = "admin"
}

variable "n8n_basic_auth_password" {
  description = "Basic auth password (if enabled)"
  type        = string
  default     = null
  sensitive   = true
}

#------------------------------------------------------------------------------
# Logging Configuration
#------------------------------------------------------------------------------

variable "log_retention_days" {
  description = "CloudWatch log retention in days (HIPAA: 2192 = 6 years)"
  type        = number
  default     = 2192
}

#------------------------------------------------------------------------------
# Health Check Configuration
#------------------------------------------------------------------------------

variable "health_check_path" {
  description = "Health check path for n8n services"
  type        = string
  default     = "/healthz"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Healthy threshold for health checks"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Unhealthy threshold for health checks"
  type        = number
  default     = 3
}

#------------------------------------------------------------------------------
# Route 53 DNS Configuration
#------------------------------------------------------------------------------

variable "create_route53_records" {
  description = "Whether to create Route 53 DNS records for n8n services"
  type        = bool
  default     = true
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for DNS records"
  type        = string
  default     = null
}

variable "nlb_dns_name" {
  description = "NLB DNS name for Route 53 alias records"
  type        = string
  default     = null
}

variable "nlb_zone_id" {
  description = "NLB hosted zone ID for Route 53 alias records"
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
