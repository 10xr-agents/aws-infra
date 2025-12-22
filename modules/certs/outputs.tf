# modules/certs/outputs.tf

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.main.arn
}

output "acm_certificate_domain_validation_options" {
  description = "Domain validation options for the certificate"
  value       = aws_acm_certificate.main.domain_validation_options
}

output "acm_certificate_status" {
  description = "Status of the ACM certificate"
  value       = aws_acm_certificate.main.status
}

output "validated_certificate_arn" {
  description = "ARN of the validated certificate (waits for validation to complete)"
  value       = var.enable_cloudflare_validation ? aws_acm_certificate_validation.main[0].certificate_arn : aws_acm_certificate.main.arn
}

output "cloudflare_validation_records" {
  description = "Cloudflare DNS records created for ACM validation"
  value = var.enable_cloudflare_validation ? {
    for k, v in cloudflare_dns_record.acm_validation : k => {
      id      = v.id
      name    = v.name
      type    = v.type
      content = v.content
    }
  } : {}
}
