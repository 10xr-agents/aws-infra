# modules/cloudflare-dns/main.tf
#
# Cloudflare DNS Module - Service Records Only
# Creates DNS records pointing services to NLB
# NOTE: ACM validation is handled by the certs module

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
