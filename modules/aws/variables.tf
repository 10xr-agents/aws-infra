
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

# VPC Tags
variable "tags" {
  description = "Additional tags for VPC resource"
  type        = map(string)
  default     = {}
}

# Subnet Tags
variable "public_subnet_tags" {
  description = "Additional tags for public subnet resources"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnet resources"
  type        = map(string)
  default     = {}
}

variable "alarm_actions" {
  description = "List of ARNs to notify when NAT Gateway alarm triggers"
  type        = list(string)
  default     = []
}


variable "services" {
  description = "List of services to deploy"
  type = list(object({
    name                  = string
    ecr_repo              = string
    cpu                   = number
    memory                = number
    desired_count         = number
    instance_type         = string
    port                  = number
    health_check_path     = string
    environment_variables = map(string)
    secrets               = map(string)
    additional_policies   = list(string)
    capacity_provider_strategy = list(object({
      capacity_provider = string
      weight            = number
      base              = number
    }))
    storage_mount_path      = optional(string, "/tmp")
  }))
}

variable "capacity_provider_strategy" {
  description = "Default capacity provider strategy"
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = number
  }))
  default = [
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 3
      base              = 0
    },
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 1
    }
  ]
}

variable "instance_types" {
  description = "Map of instance types for different capacities"
  type        = map(string)
  default = {
    "small"  = "t3.small"
    "medium" = "t3.medium"
    "large"  = "c5.large"
    "xlarge" = "c5.xlarge"
  }
}

variable "ecs_cluster_settings" {
  description = "Map of ECS cluster settings"
  type        = map(string)
  default     = {}
}

variable "enable_service_discovery" {
  description = "Whether to enable Service Discovery"
  type        = bool
  default     = false
}

variable "service_discovery_namespace" {
  description = "The namespace to use for Service Discovery"
  type        = string
  default     = "example.local"
}

variable "enable_ecs_exec" {
  description = "Whether to enable ECS Exec for the services"
  type        = bool
  default     = false
}

variable "asg_min_size" {
  description = "Minimum size for the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum size for the Auto Scaling Group"
  type        = number
  default     = 10
}

variable "asg_desired_capacity" {
  description = "Desired capacity for the Auto Scaling Group"
  type        = number
  default     = 1
}
