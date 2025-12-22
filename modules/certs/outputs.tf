# modules/certs/outputs.tf

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  value       = aws_acm_certificate.main.arn
}

output "acm_certificate_domain_validation_options" {
  description = "Domain validation options for the certificate (for Cloudflare/Route53 DNS validation)"
  value       = aws_acm_certificate.main.domain_validation_options
}

output "acm_certificate_status" {
  description = "Status of the ACM certificate"
  value       = aws_acm_certificate.main.status
}
