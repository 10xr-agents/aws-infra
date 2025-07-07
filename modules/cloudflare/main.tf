# modules/cloudflare/main.tf - Fixed version

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

  # Process custom DNS records and set content to target_dns_name if empty
  processed_custom_dns_records = {
    for name, record in var.app_dns_records : name => merge(record, {
      content = record.content != "" ? record.content : var.target_dns_name
    })
  }
}

################################################################################
# DNS Records for ALB/Global Accelerator
################################################################################

resource "cloudflare_record" "app_dns_records" {
  for_each = local.processed_custom_dns_records

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  content = each.value.content
  type    = each.value.type
  proxied = lookup(each.value, "proxied", var.proxied)
  ttl     = lookup(each.value, "proxied", var.proxied) ? null : lookup(each.value, "ttl", var.ttl)
  priority = lookup(each.value, "priority", null)

  comment = lookup(each.value, "comment", "Application DNS record for ${var.environment} environment")

}

# Public DNS records for MongoDB (add to existing configuration)
resource "aws_route53_record" "mongodb_public_primary" {
  count = var.create_public_mongodb_dns ? 1 : 0

  zone_id = var.cloudflare_zone_id  # Use your existing zone
  name    = "mongodb-primary.qa"
  type    = "A"
  ttl     = 300
  records = [var.mongo_instance_private_ips[0]]
}

resource "aws_route53_record" "mongodb_public_secondary1" {
  count = var.create_public_mongodb_dns ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = "mongodb-secondary1.qa"
  type    = "A"
  ttl     = 300
  records = [var.mongo_instance_private_ips[1]]
}

resource "aws_route53_record" "mongodb_public_secondary2" {
  count = var.create_public_mongodb_dns ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = "mongodb-secondary2.qa"
  type    = "A"
  ttl     = 300
  records = [var.mongo_instance_private_ips[2]]
}

# SRV record for MongoDB+SRV connection
resource "aws_route53_record" "mongodb_srv_public" {
  count = var.create_public_mongodb_dns ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = "_mongodb._tcp.qa"
  type    = "SRV"
  ttl     = 300
  records = [
    "0 5 27017 mongodb-primary.qa.10xr.co",
    "0 5 27017 mongodb-secondary1.qa.10xr.co",
    "0 5 27017 mongodb-secondary2.qa.10xr.co"
  ]
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

  # Removed tags - Cloudflare has a quota of 0 tags for DNS records
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