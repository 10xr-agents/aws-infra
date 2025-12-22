# modules/certs/main.tf
#
# ACM Certificate with Cloudflare DNS Validation
# This module creates the certificate AND validates it via Cloudflare
# No dependencies on ECS, ALB, or NLB

data "aws_region" "current" {}

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
  for_each = var.enable_cloudflare_validation ? {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
    # Skip wildcards - they share validation record with base domain
    if !startswith(dvo.domain_name, "*.")
  } : {}

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  content = each.value.record
  type    = each.value.type
  ttl     = 60
  proxied = false # Must be DNS Only for ACM validation

  comment = "ACM certificate validation for ${each.key} - Managed by Terraform"

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

  certificate_arn         = aws_acm_certificate.main.arn
  # Use the FQDN from ACM validation options (stored in for_each values)
  validation_record_fqdns = [for k, v in cloudflare_dns_record.acm_validation : trimsuffix(v.name, ".")]

  timeouts {
    create = var.validation_timeout
  }
}
