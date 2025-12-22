# modules/cloudflare-dns/outputs.tf

################################################################################
# Service DNS Records
################################################################################

output "service_records" {
  description = "Service DNS records created in Cloudflare"
  value = {
    for k, v in cloudflare_dns_record.service : k => {
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
    for k, v in cloudflare_dns_record.service : k => "https://${v.name}.${var.domain}"
  }
}

################################################################################
# Wildcard Record
################################################################################

output "wildcard_record" {
  description = "Wildcard DNS record (if created)"
  value = var.create_wildcard_record ? {
    id      = cloudflare_dns_record.wildcard[0].id
    name    = cloudflare_dns_record.wildcard[0].name
    content = cloudflare_dns_record.wildcard[0].content
    proxied = cloudflare_dns_record.wildcard[0].proxied
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
    service_record_count    = length(cloudflare_dns_record.service)
    wildcard_record_created = var.create_wildcard_record
    total_records_created   = length(cloudflare_dns_record.service) + (var.create_wildcard_record ? 1 : 0)
  }
}
