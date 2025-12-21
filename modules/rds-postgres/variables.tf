#------------------------------------------------------------------------------
# RDS PostgreSQL Module - Variables
# HIPAA-compliant PostgreSQL database for n8n workflow automation
#------------------------------------------------------------------------------

variable "identifier" {
  description = "Unique identifier for the RDS instance"
  type        = string
}

variable "environment" {
  description = "Environment name (qa, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "database_subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to connect to RDS"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to RDS"
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# Database Configuration
#------------------------------------------------------------------------------

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.3"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling in GB (0 to disable)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "n8n"
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 5432
}

#------------------------------------------------------------------------------
# High Availability
#------------------------------------------------------------------------------

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Backup & Maintenance
#------------------------------------------------------------------------------

variable "backup_retention_period" {
  description = "Number of days to retain backups (HIPAA: 35 days recommended)"
  type        = number
  default     = 35
}

variable "backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-05:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "Mon:05:00-Mon:07:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion (set to false for production)"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier_prefix" {
  description = "Prefix for final snapshot identifier"
  type        = string
  default     = "final"
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# Security & Encryption (HIPAA)
#------------------------------------------------------------------------------

variable "storage_encrypted" {
  description = "Enable storage encryption (HIPAA requirement)"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (if not provided, creates new key)"
  type        = string
  default     = null
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Logging & Monitoring (HIPAA)
#------------------------------------------------------------------------------

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["postgresql", "upgrade"]
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention in days (HIPAA: 2192 = 6 years)"
  type        = number
  default     = 2192
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period (7 or 731 days)"
  type        = number
  default     = 7
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 to disable)"
  type        = number
  default     = 60
}

#------------------------------------------------------------------------------
# CloudWatch Alarms
#------------------------------------------------------------------------------

variable "create_cloudwatch_alarms" {
  description = "Create CloudWatch alarms for monitoring"
  type        = bool
  default     = true
}

variable "alarm_cpu_threshold" {
  description = "CPU utilization threshold for alarm (%)"
  type        = number
  default     = 80
}

variable "alarm_memory_threshold" {
  description = "Freeable memory threshold for alarm (bytes)"
  type        = number
  default     = 100000000 # 100MB
}

variable "alarm_storage_threshold" {
  description = "Free storage space threshold for alarm (bytes)"
  type        = number
  default     = 5000000000 # 5GB
}

variable "alarm_connections_threshold" {
  description = "Database connections threshold for alarm"
  type        = number
  default     = 100
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# Parameter Group
#------------------------------------------------------------------------------

variable "parameter_group_family" {
  description = "DB parameter group family"
  type        = string
  default     = "postgres16"
}

variable "parameters" {
  description = "Additional DB parameters"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
