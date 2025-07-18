data "aws_region" "current" {}

resource "aws_acm_certificate" "main" {
  domain_name       = var.domain
  validation_method = "DNS"
  subject_alternative_names = var.subject_alternative_domains

  lifecycle {
    create_before_destroy = true
  }
}

# Cloudflare DNS record for certificate validation
resource "cloudflare_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
    if dvo.domain_name != "*.${var.domain}"
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  content = each.value.record
  type    = each.value.type
  ttl     = 60
  proxied = false
}

# Certificate Validation
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in cloudflare_record.cert_validation : record.hostname]
}