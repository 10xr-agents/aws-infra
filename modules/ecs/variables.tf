# modules/ecs-refactored/variables.tf

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

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB (if using ALB)"
  type        = string
  default     = ""
}

variable "alb_https_listener_arn" {
  description = "HTTPS Listener ARN of the ALB (if using ALB)"
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
  description = "Whether to create ALB target groups"
  type        = bool
  default     = true
}

variable "target_group_arns" {
  type = string
  default = ""
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

    # Capacity provider strategy
    capacity_provider_strategy = list(object({
      capacity_provider = string
      weight           = number
      base             = number
    }))

    # Health check configuration
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

    # EFS configuration
    efs_config = optional(object({
      enabled    = bool
      mount_path = string
    }))

    # Additional IAM policies
    additional_task_policies = optional(map(string), {})

    # Advanced container settings
    memory_reservation = optional(number)
    linux_parameters   = optional(any)
    ulimits           = optional(any)
  }))
}