# modules/ecs/variables.tf

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where ECS resources will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB (required if create_alb is true and alb_internal is false)"
  type        = list(string)
  default     = []
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB (if using ALB)"
  type        = string
  default     = ""
}

variable "create_alb_rules" {
  description = "Whether to create ALB listener rules"
  type        = bool
  default     = true
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
  default     = ""
}

variable "enable_container_insights" {
  description = "Whether to enable Container Insights for the ECS cluster"
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Whether to enable ECS Exec for debugging"
  type        = bool
  default     = false
}

variable "enable_service_discovery" {
  description = "Whether to enable service discovery"
  type        = bool
  default     = true
}

variable "create_alb" {
  description = "Whether to create ALB and target groups"
  type        = bool
  default     = true
}

variable "target_group_arns" {
  description = "Map of service names to external target group ARNs (if not creating new ones)"
  type        = map(string)
  default     = {}
}

# ALB Configuration Variables
variable "alb_internal" {
  description = "Whether the ALB should be internal (private) or external (public)"
  type        = bool
  default     = false
}

variable "alb_enable_deletion_protection" {
  description = "Whether to enable deletion protection for the ALB. HIPAA best practice: enable in production."
  type        = bool
  default     = true
}

variable "alb_enable_http2" {
  description = "Whether to enable HTTP/2 for the ALB"
  type        = bool
  default     = true
}

variable "alb_enable_cross_zone_load_balancing" {
  description = "Whether to enable cross-zone load balancing for the ALB"
  type        = bool
  default     = true
}

variable "alb_idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "alb_enable_waf_fail_open" {
  description = "Whether to enable WAF fail open for the ALB"
  type        = bool
  default     = false
}

variable "alb_allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "alb_additional_ports" {
  description = "List of additional ports to allow on the ALB security group"
  type        = list(number)
  default     = []
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listeners"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "default_target_group_arn" {
  description = "ARN of default target group for ALB default actions"
  type        = string
  default     = ""
}

variable "create_default_target_group" {
  description = "Whether to create a default target group"
  type        = bool
  default     = true
}

# ALB Access Logs
variable "alb_access_logs_enabled" {
  description = "Whether to enable ALB access logs. HIPAA requires access logging for audit trails."
  type        = bool
  default     = true  # HIPAA compliance - access logging required
}

variable "alb_access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
  default     = ""
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs"
  type        = string
  default     = "alb-access-logs"
}

# ALB Connection Logs
variable "alb_connection_logs_enabled" {
  description = "Whether to enable ALB connection logs. HIPAA requires connection logging for audit trails."
  type        = bool
  default     = true  # HIPAA compliance - connection logging required
}

variable "alb_connection_logs_bucket" {
  description = "S3 bucket for ALB connection logs"
  type        = string
  default     = ""
}

variable "alb_connection_logs_prefix" {
  description = "S3 prefix for ALB connection logs"
  type        = string
  default     = "alb-connection-logs"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs. HIPAA requires 6 years (2190 days) for audit logs."
  type        = number
  default     = 2190  # 6 years - HIPAA compliance requirement
}

variable "efs_file_system_id" {
  description = "EFS file system ID (required if any service uses EFS)"
  type        = string
  default     = ""
}

variable "efs_access_point_id" {
  description = "EFS access point ID (required if any service uses EFS)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "services" {
  description = "Map of ECS services to create with their configurations"
  type = map(object({
    # Required fields
    image         = string
    port          = number
    cpu           = number
    memory        = number
    desired_count = number

    # Optional fields
    image_tag = optional(string, "latest")

    # Environment configuration
    environment = optional(map(string), {})
    secrets = optional(list(object({
      name       = string
      value_from = string
    })), [])

    # Capacity provider strategy (optional - uses cluster default if not specified)
    capacity_provider_strategy = optional(list(object({
      capacity_provider = string
      weight           = number
      base             = number
    })), [])

    # Health check configuration
    health_check = optional(object({
      path                = optional(string, "/health")
      interval            = optional(number, 30)
      timeout             = optional(number, 20)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 3)
      matcher             = optional(string, "200")
    }), {})

    # Container health check (different from ALB health check)
    container_health_check = optional(object({
      command      = string
      interval     = optional(number, 30)
      timeout      = optional(number, 20)
      retries      = optional(number, 3)
      start_period = optional(number, 90)
    }))

    # Auto scaling configuration
    enable_auto_scaling       = optional(bool, true)
    auto_scaling_min_capacity = optional(number, 1)
    auto_scaling_max_capacity = optional(number, 10)
    auto_scaling_cpu_target   = optional(number, 70)
    auto_scaling_memory_target = optional(number, 80)

    # Service discovery
    enable_service_discovery = optional(bool, true)

    # Load balancer
    enable_load_balancer = optional(bool, true)
    deregistration_delay = optional(number, 30)

    # ALB routing configuration
    enable_default_routing = optional(bool, false),
    alb_path_patterns = optional(list(string))
    alb_host_headers  = optional(list(string))
    alb_priority      = optional(number)

    # EFS configuration
    efs_config = optional(object({
      enabled    = bool
      mount_path = string
    }))

    # Additional IAM policies for the task role
    additional_task_policies = optional(map(string), {})

    # Advanced container settings
    memory_reservation = optional(number)
    linux_parameters   = optional(any)
    ulimits           = optional(any)

    # Task definition placement constraints
    placement_constraints = optional(list(object({
      type       = string
      expression = optional(string)
    })), [])
  }))
}

# Add these variables to your modules/ecs/variables.tf

variable "redis_security_group_id" {
  description = "Security group ID of the Redis cluster for ECS services to access"
  type        = string
  default     = ""
}

variable "mongodb_security_group_id" {
  description = "Security group ID of the MongoDB cluster for ECS services to access"
  type        = string
  default     = ""
}

variable "additional_security_group_ids" {
  description = "Additional security group IDs to attach to ECS services"
  type        = list(string)
  default     = []
}

variable "enable_inter_service_communication" {
  description = "Whether to enable communication between ECS services"
  type        = bool
  default     = true
}