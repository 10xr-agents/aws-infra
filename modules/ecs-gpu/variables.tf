# modules/ecs-gpu/variables.tf - Variables for GPU ECS module

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
  description = "List of private subnet IDs for ECS instances"
  type        = list(string)
}

variable "alb_security_group_ids" {
  description = "List of ALB security group IDs"
  type        = list(string)
  default     = []
}

################################################################################
# EC2 Configuration
################################################################################

variable "instance_type" {
  description = "Primary instance type for GPU instances"
  type        = string
  default     = "p4d.24xlarge"
}

variable "instance_types" {
  description = "List of instance types for mixed instances policy"
  type        = list(string)
  default     = ["p4d.24xlarge", "p4de.24xlarge"]
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 5
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 1
}

variable "on_demand_base_capacity" {
  description = "Number of on-demand instances to maintain"
  type        = number
  default     = 1
}

variable "on_demand_percentage" {
  description = "Percentage of on-demand instances above base capacity"
  type        = number
  default     = 25
}

variable "target_capacity" {
  description = "Target capacity percentage for capacity provider"
  type        = number
  default     = 100
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 100
}

################################################################################
# ECS Configuration
################################################################################

variable "enable_container_insights" {
  description = "Whether to enable Container Insights for the ECS cluster"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "create_alb" {
  description = "Whether to create ALB target groups"
  type        = bool
  default     = false
}

################################################################################
# Service Configuration
################################################################################

variable "services" {
  description = "Map of ECS services to create with GPU support"
  type = map(object({
    # Required fields
    image         = string
    port          = number
    cpu           = number
    memory        = number
    desired_count = number
    gpu_count     = number

    # Optional fields
    image_tag = optional(string, "latest")

    # Environment configuration
    environment = optional(map(string), {})
    secrets = optional(list(object({
      name       = string
      value_from = string
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

    # Container health check
    container_health_check = optional(object({
      command      = string
      interval     = optional(number, 30)
      timeout      = optional(number, 20)
      retries      = optional(number, 3)
      start_period = optional(number, 120)
    }))

    # Load balancer
    enable_load_balancer = optional(bool, false)
    deregistration_delay = optional(number, 30)

    # Docker configuration
    docker_labels = optional(map(string), {})
    ulimits = optional(list(object({
      name       = string
      soft_limit = number
      hard_limit = number
    })), [])

    # Working directory and user
    working_directory = optional(string)
    user             = optional(string)

    # Placement constraints
    placement_constraints = optional(list(object({
      type       = string
      expression = optional(string)
    })), [])
  }))
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}