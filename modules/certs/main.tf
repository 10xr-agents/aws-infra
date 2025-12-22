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
################################################################################

resource "cloudflare_dns_record" "acm_validation" {
  # Deduplicate by resource_record_name since wildcard and base domain share the same validation record
  # e.g., qa.10xr.co and *.qa.10xr.co both use _51e42db8eb04c31f186f8fe853418f8b.qa.10xr.co
  for_each = var.enable_cloudflare_validation ? {
    for opt in aws_acm_certificate.main.domain_validation_options : opt.resource_record_name => opt...
  } : {}

  zone_id = var.cloudflare_zone_id
  name    = each.value[0].resource_record_name
  type    = each.value[0].resource_record_type
  content = trimsuffix(each.value[0].resource_record_value, ".")
  ttl     = 60
  proxied = false # Must be DNS Only for ACM validation

  comment = "ACM certificate validation - Managed by Terraform"

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
