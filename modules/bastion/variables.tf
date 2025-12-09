# modules/bastion/variables.tf

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
  description = "VPC ID where the bastion host will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the bastion host (should be a private subnet)"
  type        = string
}

################################################################################
# Instance Configuration
################################################################################

variable "instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

################################################################################
# Security Configuration
################################################################################

variable "additional_security_group_ids" {
  description = "Additional security group IDs to attach to the bastion host"
  type        = list(string)
  default     = []
}

################################################################################
# Logging Configuration
################################################################################

variable "enable_session_logging" {
  description = "Enable CloudWatch logging for SSM sessions"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain session logs"
  type        = number
  default     = 90
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
