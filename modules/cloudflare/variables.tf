# modules/cloudflare/variables.tf

variable "cluster_name" {
  description = "Name of the cluster (used for naming resources)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain"
  type        = string
}

################################################################################
# Main DNS Configuration
################################################################################

variable "target_dns_name" {
  description = "Target DNS name (ALB or Global Accelerator DNS name)"
  type        = string
}

variable "dns_record_type" {
  description = "DNS record type (A, AAAA, CNAME)"
  type        = string
  default     = "CNAME"
}

variable "proxied" {
  description = "Whether DNS records should be proxied through Cloudflare"
  type        = bool
  default     = false
}

variable "ttl" {
  description = "TTL for DNS records (ignored if proxied is true)"
  type        = number
  default     = 300
}

################################################################################
# Main Application DNS Records
################################################################################

variable "create_main_dns_record" {
  description = "Whether to create the main DNS record"
  type        = bool
  default     = true
}

variable "main_subdomain" {
  description = "Main subdomain (defaults to environment name if empty)"
  type        = string
  default     = ""
}

variable "create_api_dns_record" {
  description = "Whether to create the API DNS record"
  type        = bool
  default     = true
}

variable "api_subdomain" {
  description = "API subdomain (defaults to 'api.{environment}' if empty)"
  type        = string
  default     = ""
}

variable "create_proxy_dns_record" {
  description = "Whether to create the proxy DNS record"
  type        = bool
  default     = true
}

variable "proxy_subdomain" {
  description = "Proxy subdomain (defaults to 'proxy.{environment}' if empty)"
  type        = string
  default     = ""
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
# Certificate Validation Records
################################################################################

variable "certificate_validation_records" {
  description = "Map of certificate validation records for ACM"
  type = map(object({
    name   = string
    record = string
    type   = string
  }))
  default = {}
}

################################################################################
# Page Rules
################################################################################

variable "page_rules" {
  description = "Map of Cloudflare page rules to create"
  type = map(object({
    target   = string
    priority = optional(number, 1)
    status   = optional(string, "active")
    actions = object({
      ssl                = optional(string)
      cache_level        = optional(string)
      edge_cache_ttl     = optional(number)
      security_level     = optional(string)
      browser_cache_ttl  = optional(number)
      always_use_https   = optional(bool)
      forwarding_url = optional(object({
        url         = string
        status_code = number
      }))
    })
  }))
  default = {}
}

################################################################################
# Firewall Rules
################################################################################

variable "firewall_rules" {
  description = "Map of Cloudflare firewall rules to create"
  type = map(object({
    description = string
    expression  = string
    action      = string
    priority    = optional(number)
    paused      = optional(bool, false)
    action_parameters = optional(object({
      uri = optional(string)
      overrides = optional(object({
        action      = optional(string)
        sensitivity = optional(string)
      }))
    }))
  }))
  default = {}
}

################################################################################
# Zone Settings
################################################################################

variable "manage_zone_settings" {
  description = "Whether to manage Cloudflare zone settings"
  type        = bool
  default     = false
}

variable "zone_settings" {
  description = "Cloudflare zone settings configuration"
  type = object({
    # SSL settings
    ssl                      = optional(string, "flexible")
    always_use_https        = optional(string, "off")
    min_tls_version         = optional(string, "1.2")
    opportunistic_encryption = optional(string, "on")
    tls_1_3                 = optional(string, "zrt")
    automatic_https_rewrites = optional(string, "on")

    # Security settings
    security_level          = optional(string, "medium")
    challenge_ttl           = optional(number, 1800)
    browser_check           = optional(string, "on")
    hotlink_protection      = optional(string, "off")

    # Performance settings
    brotli                  = optional(string, "on")
    minify_css             = optional(bool, true)
    minify_html            = optional(bool, true)
    minify_js              = optional(bool, true)

    # Caching
    browser_cache_ttl       = optional(number, 14400)
    always_online           = optional(string, "off")

    # Network settings
    ipv6                    = optional(string, "on")
    websockets              = optional(string, "on")
    opportunistic_onion     = optional(string, "on")
    pseudo_ipv4             = optional(string, "off")
    ip_geolocation          = optional(string, "on")

    # Rocket Loader
    rocket_loader           = optional(string, "off")
  })
  default = {}
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}