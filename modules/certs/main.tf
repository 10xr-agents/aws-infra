# modules/certs/main.tf
#
# ACM Certificate with Cloudflare DNS Validation
# This module creates the certificate AND validates it via Cloudflare
# No dependencies on ECS, ALB, or NLB

data "aws_region" "current" {}

################################################################################
# Local Variables
################################################################################

locals {
  # All domains that need certificates (primary + SANs)
  all_domains = concat([var.domain], var.subject_alternative_domains)

  # Filter out wildcards - they share validation records with their base domain
  # e.g., *.qa.10xr.co shares validation record with qa.10xr.co
  non_wildcard_domains = [
    for domain in local.all_domains : domain
    if !startswith(domain, "*.")
  ]

  # Create a map from domain name to validation options (for lookup)
  # This allows us to use static domain names as for_each keys
  domain_validation_map = var.enable_cloudflare_validation ? {
    for opt in aws_acm_certificate.main.domain_validation_options : opt.domain_name => {
      name  = opt.resource_record_name
      value = opt.resource_record_value
    }
  } : {}
}

################################################################################
# ACM Certificate
################################################################################

resource "aws_acm_certificate" "main" {
  domain_name               = var.domain
  validation_method         = "DNS"
  subject_alternative_names = var.subject_alternative_domains

  tags = merge(var.tags, {
    Name        = "${var.environment}-acm-certificate"
    Environment = var.environment
  })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Cloudflare DNS Validation Records
# Creates CNAME records in Cloudflare for ACM certificate validation
# Wildcards share validation records with their base domain, so we skip them
################################################################################

resource "cloudflare_dns_record" "acm_validation" {
  # Use static domain names as keys (known at plan time)
  for_each = var.enable_cloudflare_validation ? toset(local.non_wildcard_domains) : toset([])

  zone_id = var.cloudflare_zone_id
  name    = local.domain_validation_map[each.value].name
  type    = "CNAME"
  content = trimsuffix(local.domain_validation_map[each.value].value, ".")
  ttl     = 60
  proxied = false # Must be DNS Only for ACM validation

  comment = "ACM certificate validation for ${each.value} - Managed by Terraform"

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Certificate Validation
# Waits for ACM certificate to be validated after Cloudflare records are created
################################################################################

resource "aws_acm_certificate_validation" "main" {
  count = var.enable_cloudflare_validation ? 1 : 0

  certificate_arn = aws_acm_certificate.main.arn

  timeouts {
    create = var.validation_timeout
  }

  depends_on = [cloudflare_dns_record.acm_validation]
}
