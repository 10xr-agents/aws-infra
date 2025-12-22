# modules/cloudflare-dns/main.tf
#
# Cloudflare DNS Module - Service Records Only
# Creates DNS records pointing services to NLB
# NOTE: ACM validation is handled by the certs module

################################################################################
# Local Variables
################################################################################

locals {
  # For QA: append ".qa" to service names (e.g., "homehealth.qa")
  # For Prod: use service names directly (e.g., "homehealth")
  environment_suffix = var.environment != "prod" ? ".${var.environment}" : ""

  # Wildcard pattern: "*.qa" for QA, "*" for prod
  wildcard_name = var.environment != "prod" ? "*.${var.environment}" : "*"
}

################################################################################
# Service DNS Records
# Creates CNAME records pointing to NLB for each service
################################################################################

resource "cloudflare_dns_record" "service" {
  for_each = var.dns_records

  zone_id = var.zone_id
  name    = "${each.value.name}${local.environment_suffix}"
  type    = each.value.type
  content = var.nlb_dns_name
  ttl     = each.value.proxied ? 1 : each.value.ttl # Auto TTL (1) when proxied
  proxied = each.value.proxied

  comment = coalesce(each.value.comment, "DNS record for ${each.key}.${var.environment} service - Managed by Terraform")

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Wildcard DNS Record
# Points *.{environment}.{domain} to NLB for catch-all routing
# QA: *.qa.10xr.co | Prod: *.10xr.co
################################################################################

resource "cloudflare_dns_record" "wildcard" {
  count = var.create_wildcard_record ? 1 : 0

  zone_id = var.zone_id
  name    = local.wildcard_name
  type    = "CNAME"
  content = var.nlb_dns_name
  ttl     = var.wildcard_proxied ? 1 : 300
  proxied = var.wildcard_proxied

  comment = "Wildcard DNS record for ${local.wildcard_name}.10xr.co - Managed by Terraform"

  lifecycle {
    create_before_destroy = true
  }
}
