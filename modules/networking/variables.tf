# modules/networking/variables.tf

variable "vpc_id" {
  description = "The ID of the VPC"
  type       = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment of the project"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ID of the security group for the ALB"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for the ALB"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}