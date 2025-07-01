# modules/global-accelerator/variables.tf

variable "cluster_name" {
  description = "Name of the cluster (used for naming resources)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

################################################################################
# Global Accelerator Configuration
################################################################################

variable "ip_address_type" {
  description = "IP address type for the Global Accelerator (IPV4 or DUALSTACK)"
  type        = string
  default     = "IPV4"
}

variable "enabled" {
  description = "Whether the Global Accelerator is enabled"
  type        = bool
  default     = true
}

################################################################################
# Flow Logs Configuration
################################################################################

variable "enable_flow_logs" {
  description = "Whether to enable flow logs for Global Accelerator"
  type        = bool
  default     = true
}

variable "flow_logs_s3_bucket" {
  description = "S3 bucket name for flow logs (if empty, creates a new bucket)"
  type        = string
  default     = ""
}

variable "flow_logs_s3_prefix" {
  description = "S3 prefix for flow logs"
  type        = string
  default     = "global-accelerator-flow-logs"
}

variable "s3_force_destroy" {
  description = "Force destroy S3 bucket even if it contains objects"
  type        = bool
  default     = true
}

################################################################################
# Listener Configuration
################################################################################

variable "client_affinity" {
  description = "Client affinity for the listener (NONE or SOURCE_IP)"
  type        = string
  default     = "NONE"
}

variable "protocol" {
  description = "Protocol for the listener (TCP or UDP)"
  type        = string
  default     = "TCP"
}

variable "port_ranges" {
  description = "List of port ranges for the listener"
  type = list(object({
    from_port = number
    to_port   = number
  }))
  default = [
    {
      from_port = 80
      to_port   = 80
    },
    {
      from_port = 443
      to_port   = 443
    }
  ]
}

variable "additional_listeners" {
  description = "Additional listeners configuration for multi-protocol support"
  type = list(object({
    protocol        = string
    client_affinity = optional(string, "NONE")
    port_ranges = list(object({
      from_port = number
      to_port   = number
    }))
    endpoints = optional(list(object({
      endpoint_id                    = string
      weight                         = optional(number, 100)
      client_ip_preservation_enabled = optional(bool, false)
    })), [])
    port_overrides = optional(list(object({
      listener_port = number
      endpoint_port = number
    })), [])
    health_check_grace_period_seconds = optional(number)
    health_check_interval_seconds     = optional(number)
    health_check_path                 = optional(string)
    health_check_port                 = optional(number)
    health_check_protocol             = optional(string)
    threshold_count                   = optional(number)
    traffic_dial_percentage           = optional(number)
  }))
  default = []
}

################################################################################
# Endpoint Group Configuration
################################################################################

variable "endpoint_group_region" {
  description = "AWS region for the endpoint group (defaults to current region)"
  type        = string
  default     = ""
}

variable "endpoints" {
  description = "List of endpoints for the Global Accelerator"
  type = list(object({
    endpoint_id                    = string
    weight                         = optional(number, 100)
    client_ip_preservation_enabled = optional(bool, false)
  }))
}

variable "port_overrides" {
  description = "Port overrides for the endpoint group"
  type = list(object({
    listener_port = number
    endpoint_port = number
  }))
  default = []
}

################################################################################
# Health Check Configuration
################################################################################

variable "health_check_grace_period_seconds" {
  description = "Grace period before health check failures cause endpoints to be removed"
  type        = number
  default     = 30
}

variable "health_check_interval_seconds" {
  description = "Interval between health checks"
  type        = number
  default     = 30
}

variable "health_check_path" {
  description = "Path for health checks (for HTTP/HTTPS protocols)"
  type        = string
  default     = "/"
}

variable "health_check_port" {
  description = "Port for health checks"
  type        = number
  default     = 80
}

variable "health_check_protocol" {
  description = "Protocol for health checks (TCP or HTTP or HTTPS)"
  type        = string
  default     = "HTTP"
}

variable "threshold_count" {
  description = "Number of consecutive health checks before changing endpoint health status"
  type        = number
  default     = 3
}

variable "traffic_dial_percentage" {
  description = "Percentage of traffic to dial to this endpoint group"
  type        = number
  default     = 100
}

################################################################################
# CloudWatch Monitoring
################################################################################

variable "create_cloudwatch_alarms" {
  description = "Whether to create CloudWatch alarms for Global Accelerator"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

variable "new_flow_count_threshold" {
  description = "Threshold for new flow count alarm"
  type        = number
  default     = 1000
}

variable "processed_bytes_in_threshold" {
  description = "Threshold for processed bytes in alarm (in bytes)"
  type        = number
  default     = 1000000000  # 1GB
}

################################################################################
# Cloudflare Configuration Variables
################################################################################

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain"
  type        = string
}

variable "domain_name" {
  description = "Base domain name"
  type        = string
  default     = "10xr.co"
}

variable "create_cloudflare_dns_records" {
  description = "Whether to create Cloudflare DNS records"
  type        = bool
  default     = true
}

variable "dns_proxied" {
  description = "Whether DNS records should be proxied through Cloudflare"
  type        = bool
  default     = false
}

variable "dns_ttl" {
  description = "TTL for DNS records (ignored if proxied is true)"
  type        = number
  default     = 300
}

################################################################################
# Global Accelerator Configuration Variables
################################################################################

variable "create_global_accelerator" {
  description = "Whether to create Global Accelerator"
  type        = bool
  default     = true
}

variable "global_accelerator_enabled" {
  description = "Whether the Global Accelerator is enabled"
  type        = bool
  default     = true
}

variable "global_accelerator_ip_address_type" {
  description = "IP address type for Global Accelerator (IPV4 or DUALSTACK)"
  type        = string
  default     = "IPV4"
}

variable "global_accelerator_flow_logs_enabled" {
  description = "Whether to enable flow logs for Global Accelerator"
  type        = bool
  default     = true
}

variable "global_accelerator_flow_logs_s3_prefix" {
  description = "S3 prefix for Global Accelerator flow logs"
  type        = string
  default     = "global-accelerator-flow-logs"
}

variable "global_accelerator_client_affinity" {
  description = "Client affinity for Global Accelerator listener (NONE or SOURCE_IP)"
  type        = string
  default     = "NONE"
}

variable "global_accelerator_protocol" {
  description = "Protocol for Global Accelerator listener (TCP or UDP)"
  type        = string
  default     = "TCP"
}

variable "global_accelerator_health_check_grace_period" {
  description = "Grace period before health check failures cause endpoints to be removed"
  type        = number
  default     = 30
}

variable "global_accelerator_health_check_interval" {
  description = "Interval between health checks"
  type        = number
  default     = 30
}

variable "global_accelerator_health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/"
}

variable "global_accelerator_health_check_port" {
  description = "Port for health checks"
  type        = number
  default     = 80
}

variable "global_accelerator_health_check_protocol" {
  description = "Protocol for health checks (TCP, HTTP, or HTTPS)"
  type        = string
  default     = "HTTP"
}

variable "global_accelerator_threshold_count" {
  description = "Number of consecutive health checks before changing endpoint health status"
  type        = number
  default     = 3
}

variable "global_accelerator_traffic_dial_percentage" {
  description = "Percentage of traffic to dial to the endpoint group"
  type        = number
  default     = 100
}

################################################################################
# Custom DNS Records
################################################################################

variable "custom_dns_records" {
  description = "Map of custom DNS records to create"
  type = map(object({
    name     = string
    content  = string
    type     = string
    proxied  = optional(bool)
    ttl      = optional(number)
    priority = optional(number)
    comment  = optional(string)
    tags     = optional(list(string), [])
  }))
  default = {}
}

################################################################################
# Zone Settings
################################################################################

variable "manage_cloudflare_zone_settings" {
  description = "Whether to manage Cloudflare zone settings"
  type        = bool
  default     = false
}

variable "cloudflare_ssl_mode" {
  description = "SSL mode for Cloudflare (off, flexible, full, strict)"
  type        = string
  default     = "flexible"
}

variable "cloudflare_always_use_https" {
  description = "Whether to always use HTTPS"
  type        = string
  default     = "off"
}

variable "cloudflare_min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"
}

variable "cloudflare_security_level" {
  description = "Cloudflare security level (off, essentially_off, low, medium, high, under_attack)"
  type        = string
  default     = "medium"
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}