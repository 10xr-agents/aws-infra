# modules/storage-ecs/variables.tf (Updated for ECS + EKS)

variable "cluster_name" {
  description = "Name of the cluster"
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

# ECS Configuration
variable "ecs_security_group_id" {
  description = "Security group ID of ECS tasks"
  type        = string
}

# EKS Configuration (optional)
variable "enable_eks" {
  description = "Whether EKS is enabled"
  type        = bool
  default     = false
}

variable "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  type        = string
  default     = ""
}

variable "eks_node_security_group_id" {
  description = "Security group ID of the EKS nodes"
  type        = string
  default     = ""
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
  default     = ""
}

variable "livekit_namespace" {
  description = "Kubernetes namespace for LiveKit components"
  type        = string
  default     = "livekit"
}

variable "create_kubernetes_resources" {
  description = "Whether to create Kubernetes resources (storage classes, etc.)"
  type        = bool
  default     = true
}

# EFS Configuration
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

# S3 Configuration
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

# Kubernetes Storage Classes Configuration
variable "gp3_iops" {
  description = "IOPS for GP3 storage class"
  type        = string
  default     = "3000"
}

variable "gp3_throughput" {
  description = "Throughput for GP3 storage class"
  type        = string
  default     = "125"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}