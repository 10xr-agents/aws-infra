# modules/cloudflare/outputs.tf

################################################################################
# Main DNS Record Outputs
################################################################################

output "main_dns_record_id" {
  description = "ID of the main DNS record"
  value       = var.create_main_dns_record ? cloudflare_record.main_dns[0].id : null
}

output "main_dns_record_hostname" {
  description = "Hostname of the main DNS record"
  value       = var.create_main_dns_record ? cloudflare_record.main_dns[0].hostname : null
}

output "main_dns_record_fqdn" {
  description = "FQDN of the main DNS record"
  value       = var.create_main_dns_record ? cloudflare_record.main_dns[0].hostname : null
}

output "api_dns_record_id" {
  description = "ID of the API DNS record"
  value       = var.create_api_dns_record ? cloudflare_record.api_dns[0].id : null
}

output "api_dns_record_hostname" {
  description = "Hostname of the API DNS record"
  value       = var.create_api_dns_record ? cloudflare_record.api_dns[0].hostname : null
}

output "proxy_dns_record_id" {
  description = "ID of the proxy DNS record"
  value       = var.create_proxy_dns_record ? cloudflare_record.proxy_dns[0].id : null
}

output "proxy_dns_record_hostname" {
  description = "Hostname of the proxy DNS record"
  value       = var.create_proxy_dns_record ? cloudflare_record.proxy_dns[0].hostname : null
}

################################################################################
# Custom DNS Records Outputs
################################################################################

output "custom_dns_record_ids" {
  description = "Map of custom DNS record IDs"
  value = {
    for name, record in cloudflare_record.custom_records : name => record.id
  }
}

output "custom_dns_record_hostnames" {
  description = "Map of custom DNS record hostnames"
  value = {
    for name, record in cloudflare_record.custom_records : name => record.hostname
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
# URL Outputs
################################################################################

output "main_url_http" {
  description = "HTTP URL for the main application"
  value       = var.create_main_dns_record ? "http://${cloudflare_record.main_dns[0].hostname}" : null
}

output "main_url_https" {
  description = "HTTPS URL for the main application"
  value       = var.create_main_dns_record ? "https://${cloudflare_record.main_dns[0].hostname}" : null
}

output "api_url_http" {
  description = "HTTP URL for the API"
  value       = var.create_api_dns_record ? "http://${cloudflare_record.api_dns[0].hostname}" : null
}

output "api_url_https" {
  description = "HTTPS URL for the API"
  value       = var.create_api_dns_record ? "https://${cloudflare_record.api_dns[0].hostname}" : null
}

output "proxy_url_http" {
  description = "HTTP URL for the proxy"
  value       = var.create_proxy_dns_record ? "http://${cloudflare_record.proxy_dns[0].hostname}" : null
}

output "proxy_url_https" {
  description = "HTTPS URL for the proxy"
  value       = var.create_proxy_dns_record ? "https://${cloudflare_record.proxy_dns[0].hostname}" : null
}

################################################################################
# Custom DNS Record URLs
################################################################################

output "custom_dns_record_urls" {
  description = "Map of custom DNS record URLs"
  value = {
    for name, record in cloudflare_record.custom_records : name => {
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
    main_dns = var.create_main_dns_record ? {
      hostname = cloudflare_record.main_dns[0].hostname
      type     = cloudflare_record.main_dns[0].type
      content  = cloudflare_record.main_dns[0].content
      proxied  = cloudflare_record.main_dns[0].proxied
    } : null

    api_dns = var.create_api_dns_record ? {
      hostname = cloudflare_record.api_dns[0].hostname
      type     = cloudflare_record.api_dns[0].type
      content  = cloudflare_record.api_dns[0].content
      proxied  = cloudflare_record.api_dns[0].proxied
    } : null

    proxy_dns = var.create_proxy_dns_record ? {
      hostname = cloudflare_record.proxy_dns[0].hostname
      type     = cloudflare_record.proxy_dns[0].type
      content  = cloudflare_record.proxy_dns[0].content
      proxied  = cloudflare_record.proxy_dns[0].proxied
    } : null

    custom_records = {
      for name, record in cloudflare_record.custom_records : name => {
        hostname = record.hostname
        type     = record.type
        content  = record.content
        proxied  = record.proxied
      }
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
    dns_records_created  = length(cloudflare_record.main_dns) + length(cloudflare_record.api_dns) + length(cloudflare_record.proxy_dns) + length(cloudflare_record.custom_records)
    page_rules_created   = length(cloudflare_page_rule.custom_rules)
    zone_settings_managed = var.manage_zone_settings
    proxied_by_default   = var.proxied
    default_ttl          = var.ttl
  }
}