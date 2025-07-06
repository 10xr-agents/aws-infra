# modules/mongodb/variables.tf

variable "cluster_name" {
  description = "Name prefix for the MongoDB cluster resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, qa, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where MongoDB will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where MongoDB instances will be deployed"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least one subnet ID must be provided."
  }
}

variable "replica_count" {
  description = "Number of MongoDB replica set members (should be odd number: 1, 3, 5, etc.)"
  type        = number
  default     = 3
  validation {
    condition     = var.replica_count % 2 == 1 && var.replica_count >= 1
    error_message = "Replica count must be an odd number (1, 3, 5, etc.) for proper quorum."
  }
}

variable "replica_set_name" {
  description = "Name of the MongoDB replica set. If empty, will use cluster_name-rs"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type for MongoDB nodes"
  type        = string
  default     = "t3.large"
}

variable "ami_id" {
  description = "AMI ID for MongoDB instances. If empty, will use latest Ubuntu 22.04"
  type        = string
  default     = ""
}

variable "mongodb_version" {
  description = "MongoDB version to install"
  type        = string
  default     = "8.0"
  validation {
    condition     = contains(["6.0", "7.0", "8.0"], var.mongodb_version)
    error_message = "MongoDB version must be either 6.0 or 7.0 or 8.0."
  }
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20
}

variable "data_volume_size" {
  description = "Size of the data EBS volume in GB"
  type        = number
  default     = 100
}

variable "data_volume_type" {
  description = "Type of the data EBS volume (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "data_volume_iops" {
  description = "IOPS for the data volume (only for gp3, io1, io2)"
  type        = number
  default     = 3000
}

variable "data_volume_throughput" {
  description = "Throughput in MiB/s for the data volume (only for gp3)"
  type        = number
  default     = 125
}

variable "data_volume_device" {
  description = "Device name for the data volume"
  type        = string
  default     = "/dev/sdf"
}

variable "create_security_group" {
  description = "Whether to create a new security group for MongoDB"
  type        = bool
  default     = true
}

variable "additional_security_group_ids" {
  description = "List of additional security group IDs to attach to instances"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access MongoDB"
  type        = list(string)
  default     = []
}

variable "allow_ssh" {
  description = "Whether to allow SSH access to MongoDB instances"
  type        = bool
  default     = false
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to instances"
  type        = list(string)
  default     = []
}

variable "mongodb_admin_username" {
  description = "MongoDB admin username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "mongodb_admin_password" {
  description = "MongoDB admin password"
  type        = string
  sensitive   = true
}

variable "mongodb_keyfile_content" {
  description = "Content of the MongoDB keyfile for replica set authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "default_database" {
  description = "Default database name"
  type        = string
  default     = "admin"
}

variable "enable_monitoring" {
  description = "Whether to enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "create_dns_records" {
  description = "Whether to create Route53 DNS records"
  type        = bool
  default     = false
}

variable "private_domain" {
  description = "Private domain for MongoDB DNS records"
  type        = string
  default     = ""
}

variable "store_connection_string_in_ssm" {
  description = "Whether to store the connection string in AWS Systems Manager Parameter Store"
  type        = bool
  default     = true
}

variable "backup_enabled" {
  description = "Whether to enable automated EBS snapshots"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Cron expression for backup schedule"
  type        = string
  default     = "cron(0 2 * * ? *)" # Daily at 2 AM
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "enable_encryption_at_rest" {
  description = "Whether to enable MongoDB encryption at rest"
  type        = bool
  default     = true
}

variable "enable_audit_logging" {
  description = "Whether to enable MongoDB audit logging"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}