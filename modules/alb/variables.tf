# modules/alb/variables.tf

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

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection on the ALB"
  type        = bool
  default     = false
}

variable "enable_http2" {
  description = "Whether to enable HTTP2 on the ALB"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "create_security_group" {
  description = "Whether to create a security group for the ALB"
  type        = bool
  default     = true
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the ALB (if create_security_group is false)"
  type        = list(string)
  default     = []
}

variable "ingress_rules" {
  description = "List of ingress rules for the ALB security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

variable "target_group_defaults" {
  description = "Default values for target groups"
  type = object({
    port                             = number
    protocol                         = string
    target_type                      = string
    deregistration_delay            = number
    health_check_enabled            = bool
    health_check_interval           = number
    health_check_path               = string
    health_check_timeout            = number
    health_check_healthy_threshold  = number
    health_check_unhealthy_threshold = number
    health_check_matcher            = string
  })
  default = {
    port                             = 80
    protocol                         = "HTTP"
    target_type                      = "ip"
    deregistration_delay            = 30
    health_check_enabled            = true
    health_check_interval           = 30
    health_check_path               = "/"
    health_check_timeout            = 5
    health_check_healthy_threshold  = 2
    health_check_unhealthy_threshold = 3
    health_check_matcher            = "200"
  }
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
  default     = ""
}

variable "additional_certificate_arns" {
  description = "List of additional certificate ARNs for the HTTPS listener"
  type        = list(string)
  default     = []
}

variable "ssl_policy" {
  description = "SSL policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

