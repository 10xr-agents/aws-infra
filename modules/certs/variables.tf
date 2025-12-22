# modules/certs/variables.tf

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "domain" {
  description = "Primary domain name for the certificate"
  type        = string
}

variable "subject_alternative_domains" {
  description = "Subject alternative domain names (SANs)"
  type        = list(string)
  default     = []
}

################################################################################
# Cloudflare Configuration
################################################################################

variable "enable_cloudflare_validation" {
  description = "Enable Cloudflare DNS validation for the certificate"
  type        = bool
  default     = false
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for DNS validation records"
  type        = string
  default     = ""
}

variable "validation_timeout" {
  description = "Timeout for certificate validation"
  type        = string
  default     = "30m"
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
