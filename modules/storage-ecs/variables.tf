# modules/storage-ecs/variables.tf

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EFS mount targets"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID of ECS tasks"
  type        = string
}

variable "efs_performance_mode" {
  description = "Performance mode for EFS (generalPurpose or maxIO)"
  type        = string
  default     = "generalPurpose"
}

variable "efs_throughput_mode" {
  description = "Throughput mode for EFS (bursting or provisioned)"
  type        = string
  default     = "bursting"
}

variable "efs_provisioned_throughput" {
  description = "Provisioned throughput in MiB/s (required if throughput_mode is provisioned)"
  type        = number
  default     = null
}

variable "enable_efs_lifecycle_policy" {
  description = "Whether to enable EFS lifecycle policy"
  type        = bool
  default     = true
}

variable "create_recordings_bucket" {
  description = "Whether to create S3 bucket for recordings"
  type        = bool
  default     = true
}

variable "recordings_bucket_name" {
  description = "Name of the S3 bucket for recordings"
  type        = string
}

variable "recordings_expiration_days" {
  description = "Number of days after which recordings expire"
  type        = number
  default     = 30
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

