# modules/cloudflare/main.tf

locals {
  name_prefix = "${var.cluster_name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Component   = "Cloudflare"
      ManagedBy   = "terraform"
    }
  )
}

################################################################################
# DNS Records for ALB/Global Accelerator
################################################################################

# Main application DNS record
resource "cloudflare_record" "main_dns" {
  count = var.create_main_dns_record ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = var.main_subdomain != "" ? var.main_subdomain : var.environment
  content = var.target_dns_name
  type    = var.dns_record_type
  proxied = var.proxied
  ttl     = var.proxied ? null : var.ttl

  comment = "Main DNS record for ${var.environment} environment"

  tags = ["terraform", "environment:${var.environment}"]
}

# API subdomain DNS record
resource "cloudflare_record" "api_dns" {
  count = var.create_api_dns_record ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = var.api_subdomain != "" ? var.api_subdomain : "api.${var.environment}"
  content = var.target_dns_name
  type    = var.dns_record_type
  proxied = var.proxied
  ttl     = var.proxied ? null : var.ttl

  comment = "API DNS record for ${var.environment} environment"

  tags = ["terraform", "environment:${var.environment}", "api"]
}

# Proxy subdomain DNS record (for LiveKit proxy)
resource "cloudflare_record" "proxy_dns" {
  count = var.create_proxy_dns_record ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = var.proxy_subdomain != "" ? var.proxy_subdomain : "proxy.${var.environment}"
  content = var.target_dns_name
  type    = var.dns_record_type
  proxied = var.proxied
  ttl     = var.proxied ? null : var.ttl

  comment = "Proxy DNS record for ${var.environment} environment"

  tags = ["terraform", "environment:${var.environment}", "proxy"]
}

################################################################################
# Custom DNS Records
################################################################################

resource "cloudflare_record" "custom_records" {
  for_each = var.custom_dns_records

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  content = each.value.content
  type    = each.value.type
  proxied = lookup(each.value, "proxied", var.proxied)
  ttl     = lookup(each.value, "proxied", var.proxied) ? null : lookup(each.value, "ttl", var.ttl)
  priority = lookup(each.value, "priority", null)

  comment = lookup(each.value, "comment", "Custom DNS record for ${var.environment} environment")

  tags = concat(
    ["terraform", "environment:${var.environment}", "custom"],
    lookup(each.value, "tags", [])
  )
}

################################################################################
# ACM Certificate Validation Records
################################################################################

resource "cloudflare_record" "cert_validation" {
  for_each = var.certificate_validation_records

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  content = each.value.record
  type    = each.value.type
  ttl     = 60  # Short TTL for validation
  proxied = false  # Certificate validation records should not be proxied

  comment = "ACM certificate validation record"

  tags = ["terraform", "environment:${var.environment}", "cert-validation"]
}

################################################################################
# Page Rules (Optional)
################################################################################

resource "cloudflare_page_rule" "custom_rules" {
  for_each = var.page_rules

  zone_id  = var.cloudflare_zone_id
  target   = each.value.target
  priority = lookup(each.value, "priority", 1)
  status   = lookup(each.value, "status", "active")

  actions {
    # SSL settings
    ssl = lookup(each.value.actions, "ssl", null)

    # Cache settings
    cache_level = lookup(each.value.actions, "cache_level", null)
    edge_cache_ttl = lookup(each.value.actions, "edge_cache_ttl", null)

    # Security settings
    security_level = lookup(each.value.actions, "security_level", null)

    # Browser cache TTL
    browser_cache_ttl = lookup(each.value.actions, "browser_cache_ttl", null)

    # Always use HTTPS
    always_use_https = lookup(each.value.actions, "always_use_https", null)

    # Forwarding URL
    dynamic "forwarding_url" {
      for_each = lookup(each.value.actions, "forwarding_url", null) != null ? [each.value.actions.forwarding_url] : []
      content {
        url         = forwarding_url.value.url
        status_code = forwarding_url.value.status_code
      }
    }
  }
}

################################################################################
# Firewall Rules (Optional)
################################################################################

resource "cloudflare_filter" "custom_filters" {
  for_each = var.firewall_rules

  zone_id     = var.cloudflare_zone_id
  description = each.value.description
  expression  = each.value.expression
}

resource "cloudflare_firewall_rule" "custom_firewall_rules" {
  for_each = var.firewall_rules

  zone_id     = var.cloudflare_zone_id
  description = each.value.description
  filter_id   = cloudflare_filter.custom_filters[each.key].id
  action      = each.value.action
  priority    = lookup(each.value, "priority", null)
  paused      = lookup(each.value, "paused", false)

  dynamic "action_parameters" {
    for_each = lookup(each.value, "action_parameters", null) != null ? [each.value.action_parameters] : []
    content {
      uri = lookup(action_parameters.value, "uri", null)
      dynamic "overrides" {
        for_each = lookup(action_parameters.value, "overrides", null) != null ? [action_parameters.value.overrides] : []
        content {
          action = lookup(overrides.value, "action", null)
          sensitivity = lookup(overrides.value, "sensitivity", null)
        }
      }
    }
  }
}

################################################################################
# Zone Settings (Optional)
################################################################################

resource "cloudflare_zone_settings_override" "zone_settings" {
  count = var.manage_zone_settings ? 1 : 0

  zone_id = var.cloudflare_zone_id

  settings {
    # SSL settings
    ssl                      = var.zone_settings.ssl
    always_use_https        = var.zone_settings.always_use_https
    min_tls_version         = var.zone_settings.min_tls_version
    opportunistic_encryption = var.zone_settings.opportunistic_encryption
    tls_1_3                 = var.zone_settings.tls_1_3
    automatic_https_rewrites = var.zone_settings.automatic_https_rewrites

    # Security settings
    security_level          = var.zone_settings.security_level
    challenge_ttl           = var.zone_settings.challenge_ttl
    browser_check           = var.zone_settings.browser_check
    hotlink_protection      = var.zone_settings.hotlink_protection

    # Performance settings
    brotli                  = var.zone_settings.brotli
    minify {
      css  = var.zone_settings.minify_css
      html = var.zone_settings.minify_html
      js   = var.zone_settings.minify_js
    }

    # Caching
    browser_cache_ttl       = var.zone_settings.browser_cache_ttl
    always_online           = var.zone_settings.always_online

    # Network settings
    ipv6                    = var.zone_settings.ipv6
    websockets              = var.zone_settings.websockets
    opportunistic_onion     = var.zone_settings.opportunistic_onion
    pseudo_ipv4             = var.zone_settings.pseudo_ipv4
    ip_geolocation          = var.zone_settings.ip_geolocation

    # Rocket Loader
    rocket_loader           = var.zone_settings.rocket_loader
  }
}