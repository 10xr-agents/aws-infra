# modules/cloudflare/outputs.tf

################################################################################
# Application DNS Records Outputs
################################################################################

output "custom_dns_record_ids" {
  description = "Map of custom DNS record IDs"
  value = {
    for name, record in cloudflare_record.app_dns_records : name => record.id
  }
}

output "custom_dns_record_hostnames" {
  description = "Map of custom DNS record hostnames"
  value = {
    for name, record in cloudflare_record.app_dns_records : name => record.hostname
  }
}

################################################################################
# Certificate Validation Records Outputs
################################################################################

output "cert_validation_record_ids" {
  description = "Map of certificate validation record IDs"
  value = {
    for name, record in cloudflare_record.cert_validation : name => record.id
  }
}

output "cert_validation_record_hostnames" {
  description = "Map of certificate validation record hostnames"
  value = {
    for name, record in cloudflare_record.cert_validation : name => record.hostname
  }
}

################################################################################
# Page Rules Outputs
################################################################################

output "page_rule_ids" {
  description = "Map of page rule IDs"
  value = {
    for name, rule in cloudflare_page_rule.custom_rules : name => rule.id
  }
}

################################################################################
# Zone Settings Outputs
################################################################################

output "zone_settings_id" {
  description = "ID of the zone settings override"
  value       = var.manage_zone_settings ? cloudflare_zone_settings_override.zone_settings[0].id : null
}

################################################################################
# Application DNS Record URLs
################################################################################

output "custom_dns_record_urls" {
  description = "Map of custom DNS record URLs"
  value = {
    for name, record in cloudflare_record.app_dns_records : name => {
      http_url  = "http://${record.hostname}"
      https_url = "https://${record.hostname}"
      hostname  = record.hostname
    }
  }
}

################################################################################
# All DNS Records Summary
################################################################################

output "dns_records_summary" {
  description = "Summary of all created DNS records"
  value = {
    for name, record in cloudflare_record.app_dns_records : name => {
      hostname = record.hostname
      type     = record.type
      content  = record.content
      proxied  = record.proxied
    }
  }
}

################################################################################
# Configuration Summary
################################################################################

output "cloudflare_configuration" {
  description = "Summary of Cloudflare configuration"
  value = {
    zone_id              = var.cloudflare_zone_id
    environment          = var.environment
    dns_records_created  = length(cloudflare_record.app_dns_records)
    page_rules_created   = length(cloudflare_page_rule.custom_rules)
    zone_settings_managed = var.manage_zone_settings
    proxied_by_default   = var.proxied
    default_ttl          = var.ttl
  }
}