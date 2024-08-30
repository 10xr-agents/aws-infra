# modules/security/variables.tf

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "allowed_cidr_blocks" {
  description = "A list of ip blocks/sets"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for EKS node access"
  type        = string
}

variable "enable_cloudtrail" {
  description = "Whether to enable CloudTrail"
  type        = bool
  default     = false
}

variable "enable_security_hub" {
  description = "Whether to enable Security Hub"
  type        = bool
  default     = false
}

variable "enable_guardduty" {
  description = "Whether to enable GuardDuty"
  type        = bool
  default     = false
}

variable "enable_config" {
  description = "Whether to enable AWS Config"
  type        = bool
  default     = false
}

variable "is_organization_master" {
  description = "When true, it creates an organization trail that logs events for the master account and all member accounts in the AWS Organization."
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  type        = string
}
