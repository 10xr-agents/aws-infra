data "aws_region" "current" {}

resource "aws_acm_certificate" "main" {
  domain_name       = var.domain
  validation_method = "DNS"
  subject_alternative_names = var.subject_alternative_domains

  lifecycle {
    create_before_destroy = true
  }
}