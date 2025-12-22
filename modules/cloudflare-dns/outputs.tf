# modules/cloudflare-dns/outputs.tf

################################################################################
# ACM Validation Records
################################################################################

output "acm_validation_records" {
  description = "ACM validation DNS records created in Cloudflare"
  value = {
    for k, v in cloudflare_record.acm_validation : k => {
      id      = v.id
      name    = v.name
      type    = v.type
      content = v.content
    }
  }
}

output "acm_validation_record_ids" {
  description = "List of ACM validation record IDs"
  value       = [for r in cloudflare_record.acm_validation : r.id]
}

################################################################################
# Service DNS Records
################################################################################

output "service_records" {
  description = "Service DNS records created in Cloudflare"
  value = {
    for k, v in cloudflare_record.service : k => {
      id      = v.id
      name    = v.name
      type    = v.type
      content = v.content
      proxied = v.proxied
      fqdn    = "${v.name}.${var.domain}"
      url     = "https://${v.name}.${var.domain}"
    }
  }
}

output "service_urls" {
  description = "Map of service names to their URLs"
  value = {
    for k, v in cloudflare_record.service : k => "https://${v.name}.${var.domain}"
  }
}

################################################################################
# Wildcard Record
################################################################################

output "wildcard_record" {
  description = "Wildcard DNS record (if created)"
  value = var.create_wildcard_record ? {
    id      = cloudflare_record.wildcard[0].id
    name    = cloudflare_record.wildcard[0].name
    content = cloudflare_record.wildcard[0].content
    proxied = cloudflare_record.wildcard[0].proxied
    fqdn    = "*.${var.domain}"
  } : null
}

################################################################################
# Summary
################################################################################

output "dns_summary" {
  description = "Summary of all DNS records created"
  value = {
    zone_id                 = var.zone_id
    domain                  = var.domain
    nlb_target              = var.nlb_dns_name
    acm_validation_count    = length(cloudflare_record.acm_validation)
    service_record_count    = length(cloudflare_record.service)
    wildcard_record_created = var.create_wildcard_record
    total_records_created   = length(cloudflare_record.acm_validation) + length(cloudflare_record.service) + (var.create_wildcard_record ? 1 : 0)
  }
}
