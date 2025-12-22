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

# Note: Certificate validation is handled in the environment's main.tf
# This allows proper dependency ordering with DNS modules (Cloudflare/Route53)
