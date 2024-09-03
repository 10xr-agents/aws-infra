variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "The CIDR blocks for the public subnets"
  type        = list(string)
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

variable "mongodb_atlas_public_key" {
  description = "MongoDB Atlas public key"
  type        = string
}

variable "mongodb_atlas_private_key" {
  description = "MongoDB Atlas private key"
  type        = string
}

variable "mongodb_atlas_project_name" {
  description = "MongoDB Atlas project name"
  type        = string
}

variable "mongodb_atlas_org_id" {
  description = "MongoDB Atlas organization ID"
  type        = string
}

variable "mongodb_atlas_project_id" {
  description = "MongoDB Atlas Project ID"
  type        = string
}

variable "mongodb_atlas_region" {
  description = "MongoDB Atlas region"
  type        = string
}

variable "mongodb_atlas_cidr_block" {
  description = "CIDR block for MongoDB Atlas cluster"
  type        = string
  default     = "192.168.248.0/21"
}

variable "mongodb_database_name" {
  description = "Database used from MongoDB Atlas cluster"
  type        = string
  default     = "converse-server"
}