# modules/documentdb/variables.tf

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

variable "vpc_id" {
  description = "VPC ID where DocumentDB will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for DocumentDB subnet group"
  type        = list(string)
}

################################################################################
# Authentication
################################################################################

variable "master_username" {
  description = "Master username for DocumentDB"
  type        = string
  default     = "docdbadmin"
}

variable "master_password" {
  description = "Master password for DocumentDB. If empty, a random password will be generated"
  type        = string
  default     = ""
  sensitive   = true
}

variable "password_length" {
  description = "Length of auto-generated password"
  type        = number
  default     = 32
}

################################################################################
# Cluster Configuration
################################################################################

variable "cluster_size" {
  description = "Number of DocumentDB instances in the cluster"
  type        = number
  default     = 2
}

variable "instance_class" {
  description = "Instance class for DocumentDB instances"
  type        = string
  default     = "db.t3.medium"
}

variable "engine" {
  description = "DocumentDB engine"
  type        = string
  default     = "docdb"
}

variable "engine_version" {
  description = "DocumentDB engine version"
  type        = string
  default     = "8.0.0"
}

variable "db_port" {
  description = "Port for DocumentDB connections"
  type        = number
  default     = 27017
}

variable "cluster_family" {
  description = "DocumentDB cluster parameter group family"
  type        = string
  default     = "docdb8.0"
}

variable "storage_type" {
  description = "Storage type for DocumentDB (standard or iopt1 for I/O-Optimized)"
  type        = string
  default     = "standard"
}

################################################################################
# Security Configuration
################################################################################

variable "create_security_group" {
  description = "Whether to create a security group for DocumentDB"
  type        = bool
  default     = true
}

variable "security_group_ids" {
  description = "List of security group IDs to use (if not creating new one)"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access DocumentDB"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to access DocumentDB"
  type        = list(string)
  default     = []
}

################################################################################
# Encryption Configuration (HIPAA Compliance)
################################################################################

variable "create_kms_key" {
  description = "Whether to create a KMS key for encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (if not creating new one)"
  type        = string
  default     = ""
}

variable "kms_key_deletion_window" {
  description = "Duration in days before KMS key is deleted"
  type        = number
  default     = 30
}

variable "kms_key_enable_rotation" {
  description = "Enable automatic KMS key rotation"
  type        = bool
  default     = true
}

variable "tls_enabled" {
  description = "Enable TLS for encryption in transit (required for HIPAA)"
  type        = bool
  default     = true
}

################################################################################
# Backup Configuration
################################################################################

variable "backup_retention_period" {
  description = "Number of days to retain backups. HIPAA recommends at least 30 days."
  type        = number
  default     = 35 # 5 weeks - HIPAA best practice
}

variable "preferred_backup_window" {
  description = "Daily time range for automated backups (UTC)"
  type        = string
  default     = "03:00-05:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when cluster is deleted"
  type        = bool
  default     = false
}

variable "snapshot_identifier" {
  description = "Snapshot identifier to restore from"
  type        = string
  default     = null
}

################################################################################
# Maintenance Configuration
################################################################################

variable "preferred_maintenance_window" {
  description = "Weekly time range for maintenance (UTC)"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "apply_immediately" {
  description = "Apply changes immediately or during maintenance window"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

################################################################################
# Logging Configuration (HIPAA Compliance)
################################################################################

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch (audit, profiler)"
  type        = list(string)
  default     = ["audit", "profiler"]
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs. HIPAA requires 6 years (2192 days) for audit logs."
  type        = number
  default     = 2192 # 6 years - HIPAA compliance requirement
}

variable "audit_logs_enabled" {
  description = "Enable audit logging (required for HIPAA)"
  type        = bool
  default     = true
}

variable "profiler_enabled" {
  description = "Enable profiler for slow query logging"
  type        = bool
  default     = true
}

variable "profiler_threshold_ms" {
  description = "Profiler threshold in milliseconds"
  type        = number
  default     = 100
}

variable "ttl_monitor_enabled" {
  description = "Enable TTL monitor"
  type        = bool
  default     = true
}

################################################################################
# Parameter Group Configuration
################################################################################

variable "cluster_parameters" {
  description = "Additional cluster parameters"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

################################################################################
# Performance Configuration
################################################################################

variable "enable_performance_insights" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

################################################################################
# SSM Parameter Store Configuration
################################################################################

variable "ssm_parameter_enabled" {
  description = "Store connection details in SSM Parameter Store"
  type        = bool
  default     = true
}

################################################################################
# Secrets Manager Configuration
################################################################################

variable "secrets_manager_enabled" {
  description = "Store credentials in AWS Secrets Manager"
  type        = bool
  default     = true
}

################################################################################
# IAM Configuration
################################################################################

variable "create_iam_policy" {
  description = "Create IAM policy for DocumentDB access"
  type        = bool
  default     = true
}

################################################################################
# CloudWatch Alarms Configuration
################################################################################

variable "create_cloudwatch_alarms" {
  description = "Create CloudWatch alarms for monitoring"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "List of ARNs for alarm actions (SNS topics)"
  type        = list(string)
  default     = []
}

variable "cpu_utilization_threshold" {
  description = "CPU utilization threshold for alarm"
  type        = number
  default     = 80
}

variable "freeable_memory_threshold" {
  description = "Freeable memory threshold in bytes for alarm"
  type        = number
  default     = 1073741824 # 1 GB
}

variable "database_connections_threshold" {
  description = "Database connections threshold for alarm"
  type        = number
  default     = 500
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
