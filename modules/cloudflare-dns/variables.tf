# modules/cloudflare-dns/variables.tf

################################################################################
# Required Variables
################################################################################

variable "zone_id" {
  description = "Cloudflare zone ID for the domain"
  type        = string
}

variable "environment" {
  description = "Environment name (qa, prod)"
  type        = string
}

variable "domain" {
  description = "Base domain for the environment (e.g., qa.10xr.co)"
  type        = string
}

variable "nlb_dns_name" {
  description = "NLB DNS name to point records to"
  type        = string
}

################################################################################
# ACM Certificate Validation
################################################################################

variable "acm_certificate_domain_validation_options" {
  description = "ACM certificate DNS validation options from aws_acm_certificate resource"
  type = set(object({
    domain_name           = string
    resource_record_name  = string
    resource_record_type  = string
    resource_record_value = string
  }))
  default = []
}

################################################################################
# DNS Records Configuration
################################################################################

variable "dns_records" {
  description = "Map of DNS records to create"
  type = map(object({
    name    = string # Record name (e.g., "homehealth" for homehealth.qa.10xr.co)
    type    = optional(string, "CNAME")
    proxied = optional(bool, false) # DNS Only mode (not proxied through Cloudflare)
    ttl     = optional(number, 300) # TTL in seconds (ignored if proxied=true)
    comment = optional(string, "")  # Optional comment
  }))
  default = {}
}

variable "create_wildcard_record" {
  description = "Whether to create a wildcard DNS record (*.domain)"
  type        = bool
  default     = true
}

variable "wildcard_proxied" {
  description = "Whether the wildcard record should be proxied through Cloudflare"
  type        = bool
  default     = false
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "Tags for resources (used in comments)"
  type        = map(string)
  default     = {}
}
