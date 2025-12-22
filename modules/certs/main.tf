# modules/certs/main.tf

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
# Certificate Validation
# Waits for certificate to be validated (after DNS records are created)
################################################################################

resource "aws_acm_certificate_validation" "main" {
  count = var.wait_for_validation ? 1 : 0

  certificate_arn = aws_acm_certificate.main.arn

  timeouts {
    create = var.validation_timeout
  }
}
