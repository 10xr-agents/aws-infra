# environments/qa/variables.tf

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "qa"
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "ten_xr_app_qa"
}

variable "domain" {
  description = "Domain name for 10xR services"
  type        = string
  default     = "qa.10xr.com"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "database_subnets" {
  description = "List of database subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
}

variable "enable_nat_gateway" {
  description = "Whether to enable NAT Gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Whether to use a single NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Whether to use one NAT Gateway per availability zone"
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch" {
  description = "Whether to assign public IP to resources within public subnets"
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Whether to enable ECS Exec for debugging"
  type        = bool
  default     = false
}

# ECS Configuration
variable "enable_container_insights" {
  description = "Whether to enable Container Insights for the ECS cluster"
  type        = bool
  default     = true
}

variable "enable_fargate" {
  description = "Whether to enable Fargate capacity provider"
  type        = bool
  default     = true
}

variable "enable_fargate_spot" {
  description = "Whether to enable Fargate Spot capacity provider"
  type        = bool
  default     = true
}

variable "enable_service_discovery" {
  description = "Whether to enable service discovery"
  type        = bool
  default     = true
}

variable "ssl_policy" {
  description = "SSL policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

# Redis Configuration Variables
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

variable "redis_num_cache_clusters" {
  description = "Number of cache clusters (nodes) for replication group"
  type        = number
  default     = 2
}

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
  description = "Number of days to retain Redis snapshots"
  type        = number
  default     = 7
}

variable "redis_snapshot_window" {
  description = "Daily time range for Redis snapshots (UTC)"
  type        = string
  default     = "03:00-05:00"
}

variable "redis_maintenance_window" {
  description = "Weekly time range for Redis maintenance (UTC)"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "redis_auth_token_enabled" {
  description = "Whether to enable Redis AUTH token (password)"
  type        = bool
  default     = true
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

variable "redis_parameters" {
  description = "Redis parameters to apply"
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
    }
  ]
}

variable "redis_store_connection_details_in_ssm" {
  description = "Whether to store Redis connection details in SSM Parameter Store"
  type        = bool
  default     = true
}

variable "redis_create_cloudwatch_log_group" {
  description = "Whether to create CloudWatch log group for Redis"
  type        = bool
  default     = false
}

variable "redis_cloudwatch_log_retention_days" {
  description = "Number of days to retain Redis CloudWatch logs"
  type        = number
  default     = 7
}

variable "ecs_services" {
  description = "Map of ECS services to create with their configurations"
  type = map(object({
    # Core configuration
    image         = string
    image_tag     = optional(string, "latest")
    port          = number
    cpu           = number
    memory        = number
    desired_count = number

    # Environment and secrets
    environment = optional(map(string), {})
    secrets = optional(list(object({
      name       = string
      value_from = string
    })), [])

    # Capacity provider strategy
    capacity_provider_strategy = list(object({
      capacity_provider = string
      weight            = number
      base              = number
    }))

    # Health checks
    health_check = optional(object({
      path                = optional(string, "/health")
      interval            = optional(number, 30)
      timeout             = optional(number, 20)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 3)
      matcher             = optional(string, "200")
    }), {})

    container_health_check = optional(object({
      command      = string
      interval     = optional(number, 30)
      timeout      = optional(number, 20)
      retries      = optional(number, 3)
      start_period = optional(number, 90)
    }))

    # Auto scaling
    enable_auto_scaling        = optional(bool, true)
    auto_scaling_min_capacity  = optional(number, 1)
    auto_scaling_max_capacity  = optional(number, 10)
    auto_scaling_cpu_target    = optional(number, 70)
    auto_scaling_memory_target = optional(number, 80)

    # Service discovery and load balancer
    enable_service_discovery = optional(bool, true)
    enable_load_balancer     = optional(bool, true)
    deregistration_delay     = optional(number, 30)

    # ALB routing
    alb_priority           = optional(number)
    alb_path_patterns      = optional(list(string))
    enable_default_routing = optional(bool, false),
    alb_host_headers       = optional(list(string))

    # Additional configuration
    efs_config = optional(object({
      enabled    = bool
      mount_path = string
    }))
    additional_task_policies = optional(map(string), {})
    memory_reservation       = optional(number)
    linux_parameters         = optional(any)
    ulimits                  = optional(any)
  }))
}

variable "create_alb_rules" {
  description = "Whether to create ALB listener rules"
  type        = bool
  default     = true
}

################################################################################
# Networking Module Variables
################################################################################

variable "create_nlb" {
  description = "Whether to create Network Load Balancer"
  type        = bool
  default     = true
}

variable "nlb_internal" {
  description = "Whether the NLB should be internal (private) or external (public)"
  type        = bool
  default     = false
}

# Note: nlb_enable_deletion_protection is now controlled by hipaa_config.enable_deletion_protection

variable "nlb_enable_cross_zone_load_balancing" {
  description = "Whether to enable cross-zone load balancing for the NLB"
  type        = bool
  default     = true
}

# Target Group Configuration
variable "create_http_target_group" {
  description = "Whether to create HTTP target group"
  type        = bool
  default     = true
}

variable "http_port" {
  description = "HTTP port for target group"
  type        = number
  default     = 80
}

variable "https_port" {
  description = "HTTPS port for target group"
  type        = number
  default     = 443
}

variable "target_type" {
  description = "Type of target for target groups (ip, instance, alb)"
  type        = string
  default     = "alb"
}

variable "deregistration_delay" {
  description = "Time to wait for in-flight requests to complete while deregistering a target"
  type        = number
  default     = 300
}

# Health Check Configuration
variable "health_check_enabled" {
  description = "Whether to enable health checks"
  type        = bool
  default     = true
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks"
  type        = number
  default     = 2
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_port" {
  description = "Port for health checks"
  type        = string
  default     = "traffic-port"
}

variable "health_check_protocol" {
  description = "Protocol for health checks"
  type        = string
  default     = "HTTP"
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 6
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks"
  type        = number
  default     = 2
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/"
}

variable "health_check_matcher" {
  description = "HTTP response codes for successful health checks"
  type        = string
  default     = "200"
}

# Listener Configuration
variable "create_http_listener" {
  description = "Whether to create HTTP listener"
  type        = bool
  default     = true
}

variable "https_listener_protocol" {
  description = "Protocol for HTTPS listener (TCP or TLS)"
  type        = string
  default     = "TCP"
  validation {
    condition     = contains(["TCP", "TLS"], var.https_listener_protocol)
    error_message = "HTTPS listener protocol must be either TCP or TLS."
  }
}

# Note: nlb_access_logs_enabled and nlb_connection_logs_enabled are now controlled by hipaa_config.enable_access_logging

# Security Groups (optional for NLB)
variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the NLB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Note: create_cloudwatch_alarms is now controlled by hipaa_config.enable_cloudwatch_alarms

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

# DNS is managed externally in GoDaddy - no Route 53 variables needed

################################################################################
# DocumentDB Configuration Variables
################################################################################

variable "documentdb_cluster_size" {
  description = "Number of DocumentDB instances in the cluster"
  type        = number
  default     = 2
}

variable "documentdb_instance_class" {
  description = "Instance class for DocumentDB instances"
  type        = string
  default     = "db.t3.medium" # Cost-optimized for QA; use db.r6g.large for production
}

variable "documentdb_engine_version" {
  description = "DocumentDB engine version"
  type        = string
  default     = "8.0.0"
}

variable "documentdb_cluster_family" {
  description = "DocumentDB cluster parameter group family"
  type        = string
  default     = "docdb8.0"
}

variable "documentdb_master_username" {
  description = "Master username for DocumentDB"
  type        = string
  default     = "docdbadmin"
}

variable "documentdb_master_password" {
  description = "Master password for DocumentDB. If empty, a random password will be generated"
  type        = string
  default     = ""
  sensitive   = true
}

variable "documentdb_create_kms_key" {
  description = "Whether to create a KMS key for DocumentDB encryption"
  type        = bool
  default     = true
}

# Note: documentdb_backup_retention_period is now controlled by hipaa_config.backup_retention_days

variable "documentdb_preferred_backup_window" {
  description = "Daily time range for DocumentDB automated backups (UTC)"
  type        = string
  default     = "03:00-05:00"
}

# Note: documentdb_skip_final_snapshot is now controlled by hipaa_config.skip_final_snapshot

variable "documentdb_preferred_maintenance_window" {
  description = "Weekly time range for DocumentDB maintenance (UTC)"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "documentdb_apply_immediately" {
  description = "Apply DocumentDB changes immediately or during maintenance window"
  type        = bool
  default     = false
}

variable "documentdb_auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades for DocumentDB"
  type        = bool
  default     = true
}

# Note: documentdb_deletion_protection is now controlled by hipaa_config.enable_deletion_protection

variable "documentdb_enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch for DocumentDB"
  type        = list(string)
  default     = ["audit", "profiler"]
}

# Note: documentdb_cloudwatch_log_retention_days is now controlled by hipaa_config.log_retention_days

variable "documentdb_profiler_enabled" {
  description = "Enable profiler for DocumentDB slow query logging"
  type        = bool
  default     = true
}

variable "documentdb_profiler_threshold_ms" {
  description = "DocumentDB profiler threshold in milliseconds"
  type        = number
  default     = 100
}

variable "documentdb_ssm_parameter_enabled" {
  description = "Store DocumentDB connection details in SSM Parameter Store"
  type        = bool
  default     = true
}

variable "documentdb_secrets_manager_enabled" {
  description = "Store DocumentDB credentials in AWS Secrets Manager"
  type        = bool
  default     = true
}

# Note: documentdb_create_cloudwatch_alarms is now controlled by hipaa_config.enable_cloudwatch_alarms

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# HIPAA Compliance Configuration
# These settings control HIPAA-related features across all modules.
# Production environments should use strict settings (defaults).
# QA/staging environments can use relaxed settings for cost optimization.
################################################################################

variable "hipaa_config" {
  description = "HIPAA compliance configuration. Production should use strict defaults, QA can use relaxed settings."
  type = object({
    # Log retention in days (HIPAA requires 6 years = 2192 days for production)
    log_retention_days = number

    # Data retention in days for S3 buckets (HIPAA requires 6 years = 2192 days)
    data_retention_days = number

    # Database backup retention in days (HIPAA recommends at least 30 days)
    backup_retention_days = number

    # Enable deletion protection on critical resources (ALB, NLB, DocumentDB)
    enable_deletion_protection = bool

    # Allow force_destroy on S3 buckets (should be false in production)
    s3_force_destroy = bool

    # Skip final snapshot on database deletion (should be false in production)
    skip_final_snapshot = bool

    # Enable access logging for load balancers
    enable_access_logging = bool

    # Enable CloudWatch alarms for monitoring
    enable_cloudwatch_alarms = bool

    # Enable audit logging for databases
    enable_audit_logging = bool
  })

  default = {
    # HIPAA-compliant defaults (use these for production)
    log_retention_days         = 2192 # 6 years
    data_retention_days        = 2192 # 6 years
    backup_retention_days      = 35   # 5 weeks
    enable_deletion_protection = true
    s3_force_destroy           = false
    skip_final_snapshot        = false
    enable_access_logging      = true
    enable_cloudwatch_alarms   = true
    enable_audit_logging       = true
  }
}

################################################################################
# Service Secrets - Home Health
# These should be set in Terraform Cloud workspace variables (sensitive)
################################################################################

variable "nextauth_secret" {
  description = "NextAuth secret for Home Health service"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ontune_secret" {
  description = "OnTune secret for Home Health service"
  type        = string
  sensitive   = true
  default     = ""
}

variable "admin_api_key" {
  description = "Admin API key for Home Health service"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gemini_api_key" {
  description = "Gemini API key for Home Health service"
  type        = string
  sensitive   = true
  default     = ""
}

variable "openai_api_key" {
  description = "OpenAI API key for Home Health service"
  type        = string
  sensitive   = true
  default     = ""
}