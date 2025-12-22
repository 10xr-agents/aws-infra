# modules/cloudflare-dns/main.tf
#
# Cloudflare DNS Module for 10xR Healthcare Platform
# Creates DNS records for services and handles ACM certificate validation

################################################################################
# ACM Certificate DNS Validation Records
# Creates Cloudflare DNS records required for ACM certificate validation
################################################################################

resource "cloudflare_record" "acm_validation" {
  for_each = {
    for opt in var.acm_certificate_domain_validation_options : opt.domain_name => opt
  }

  zone_id = var.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  content = trimsuffix(each.value.resource_record_value, ".")
  ttl     = 60
  proxied = false # Must be DNS Only for ACM validation

  comment = "ACM certificate validation for ${each.value.domain_name} - Managed by Terraform"

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Service DNS Records
# Creates CNAME records pointing to NLB for each service
################################################################################

resource "cloudflare_record" "service" {
  for_each = var.dns_records

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  content = var.nlb_dns_name
  ttl     = each.value.proxied ? 1 : each.value.ttl # Auto TTL (1) when proxied
  proxied = each.value.proxied

  comment = coalesce(each.value.comment, "DNS record for ${each.key} service - Managed by Terraform")

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Wildcard DNS Record
# Points *.{domain} to NLB for catch-all routing
################################################################################

resource "cloudflare_record" "wildcard" {
  count = var.create_wildcard_record ? 1 : 0

  zone_id = var.zone_id
  name    = "*"
  type    = "CNAME"
  content = var.nlb_dns_name
  ttl     = var.wildcard_proxied ? 1 : 300
  proxied = var.wildcard_proxied

  comment = "Wildcard DNS record for ${var.domain} - Managed by Terraform"

  lifecycle {
    create_before_destroy = true
  }
}
