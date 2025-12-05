# modules/s3-hipaa/variables.tf

################################################################################
# Required Variables
################################################################################

variable "cluster_name" {
  description = "Name of the cluster (used for naming resources)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., qa, prod)"
  type        = string
}

variable "bucket_name" {
  description = "Name suffix for the S3 bucket (will be prefixed with cluster-environment)"
  type        = string
}

################################################################################
# KMS Configuration
################################################################################

variable "create_kms_key" {
  description = "Whether to create a KMS key for S3 encryption"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of existing KMS key (if not creating new one)"
  type        = string
  default     = ""
}

variable "kms_key_deletion_window" {
  description = "Duration in days before KMS key is deleted"
  type        = number
  default     = 30
}

################################################################################
# Access Configuration
################################################################################

variable "ecs_task_role_arns" {
  description = "List of ECS task role ARNs that need access to this bucket"
  type        = list(string)
  default     = []
}

################################################################################
# Retention Configuration
################################################################################

variable "retention_days" {
  description = "Number of days to retain objects. HIPAA requires 6 years (2192 days)."
  type        = number
  default     = 2192  # 6 years - HIPAA compliance
}

################################################################################
# Logging Configuration
################################################################################

variable "enable_access_logging" {
  description = "Enable S3 access logging for audit trail"
  type        = bool
  default     = true
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
