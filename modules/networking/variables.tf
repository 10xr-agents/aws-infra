# modules/networking/variables.tf

variable "cluster_name" {
  description = "Name of the cluster (used for naming resources)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where networking resources will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for external NLB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for internal NLB"
  type        = list(string)
}

################################################################################
# NLB Configuration
################################################################################

variable "create_nlb" {
  description = "Whether to create Network Load Balancer"
  type        = bool
  default     = true
}

variable "nlb_internal" {
  description = "Whether the NLB should be internal (private) or external (public)"
  type        = bool
  default     = false
}

variable "nlb_enable_deletion_protection" {
  description = "Whether to enable deletion protection for the NLB"
  type        = bool
  default     = false
}

variable "nlb_enable_cross_zone_load_balancing" {
  description = "Whether to enable cross-zone load balancing for the NLB"
  type        = bool
  default     = true
}

################################################################################
# NLB Access Logs
################################################################################

variable "nlb_access_logs_enabled" {
  description = "Whether to enable NLB access logs"
  type        = bool
  default     = false
}

variable "nlb_access_logs_bucket" {
  description = "S3 bucket for NLB access logs"
  type        = string
  default     = ""
}

variable "nlb_access_logs_prefix" {
  description = "S3 prefix for NLB access logs"
  type        = string
  default     = "nlb-access-logs"
}

################################################################################
# NLB Connection Logs
################################################################################

variable "nlb_connection_logs_enabled" {
  description = "Whether to enable NLB connection logs"
  type        = bool
  default     = false
}

variable "nlb_connection_logs_bucket" {
  description = "S3 bucket for NLB connection logs"
  type        = string
  default     = ""
}

variable "nlb_connection_logs_prefix" {
  description = "S3 prefix for NLB connection logs"
  type        = string
  default     = "nlb-connection-logs"
}

################################################################################
# Target Groups Configuration
################################################################################

variable "create_http_target_group" {
  description = "Whether to create HTTP target group"
  type        = bool
  default     = true
}

variable "create_https_target_group" {
  description = "Whether to create HTTPS target group"
  type        = bool
  default     = false
}

variable "http_port" {
  description = "HTTP port for target group"
  type        = number
  default     = 80
}

variable "https_port" {
  description = "HTTPS port for target group"
  type        = number
  default     = 443
}

variable "target_type" {
  description = "Type of target for target groups (ip, instance, alb)"
  type        = string
  default     = "alb"
}

variable "deregistration_delay" {
  description = "Time to wait for in-flight requests to complete while deregistering a target"
  type        = number
  default     = 300
}

variable "custom_target_groups" {
  description = "Map of custom target groups to create"
  type = map(object({
    port               = number
    protocol           = optional(string, "TCP")
    target_type        = optional(string, "alb")
    target_id          = optional(string, "")
    deregistration_delay = optional(number, 300)
    health_check = optional(object({
      enabled             = optional(bool, true)
      healthy_threshold   = optional(number, 2)
      interval            = optional(number, 30)
      port                = optional(string, "traffic-port")
      protocol            = optional(string, "HTTP")
      timeout             = optional(number, 6)
      unhealthy_threshold = optional(number, 2)
      path                = optional(string, "/")
      matcher             = optional(string, "200")
    }))
  }))
  default = {}
}

################################################################################
# Health Check Configuration
################################################################################

variable "health_check_enabled" {
  description = "Whether to enable health checks"
  type        = bool
  default     = true
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks"
  type        = number
  default     = 2
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_port" {
  description = "Port for health checks"
  type        = string
  default     = "traffic-port"
}

variable "health_check_protocol" {
  description = "Protocol for health checks"
  type        = string
  default     = "HTTP"
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 6
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks"
  type        = number
  default     = 2
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/"
}

variable "health_check_matcher" {
  description = "HTTP response codes for successful health checks"
  type        = string
  default     = "200"
}

################################################################################
# Target Configuration
################################################################################

variable "alb_arn" {
  description = "ARN of the ALB to attach to NLB target groups"
  type        = string
  default     = ""
}

variable "default_http_target_group_arn" {
  description = "Default HTTP target group ARN (if not creating one)"
  type        = string
  default     = ""
}

variable "default_https_target_group_arn" {
  description = "Default HTTPS target group ARN (if not creating one)"
  type        = string
  default     = ""
}

################################################################################
# Listener Configuration
################################################################################

variable "create_http_listener" {
  description = "Whether to create HTTP listener"
  type        = bool
  default     = true
}

variable "create_https_listener" {
  description = "Whether to create HTTPS listener"
  type        = bool
  default     = true
}

variable "https_listener_protocol" {
  description = "Protocol for HTTPS listener (TCP or TLS)"
  type        = string
  default     = "TCP"
  validation {
    condition     = contains(["TCP", "TLS"], var.https_listener_protocol)
    error_message = "HTTPS listener protocol must be either TCP or TLS."
  }
}

variable "ssl_policy" {
  description = "SSL policy for TLS listeners"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for TLS listeners"
  type        = string
  default     = ""
}

variable "custom_listeners" {
  description = "Map of custom listeners to create"
  type = map(object({
    port            = number
    protocol        = string
    ssl_policy      = optional(string)
    certificate_arn = optional(string)
    target_group_arn = optional(string)
  }))
  default = {}
}

################################################################################
# Security Groups
################################################################################

variable "create_security_groups" {
  description = "Whether to create security groups for NLB"
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the NLB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_ports" {
  description = "List of additional ports to allow in security groups"
  type        = list(number)
  default     = []
}

variable "security_group_egress_rules" {
  description = "List of egress rules for the security group"
  type = list(object({
    description     = optional(string, "")
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), [])
    security_groups = optional(list(string), [])
  }))
  default = [
    {
      description = "All outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

################################################################################
# Route 53 Configuration
################################################################################

variable "create_route53_record" {
  description = "Whether to create Route 53 record for NLB"
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
  default     = ""
}

variable "route53_record_name" {
  description = "Route 53 record name"
  type        = string
  default     = ""
}

variable "route53_evaluate_target_health" {
  description = "Whether to evaluate target health for Route 53 alias"
  type        = bool
  default     = true
}

################################################################################
# CloudWatch Monitoring
################################################################################

variable "create_cloudwatch_alarms" {
  description = "Whether to create CloudWatch alarms for NLB"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

variable "healthy_host_count_threshold" {
  description = "Threshold for healthy host count alarm"
  type        = number
  default     = 1
}

variable "unhealthy_host_count_threshold" {
  description = "Threshold for unhealthy host count alarm"
  type        = number
  default     = 0
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}