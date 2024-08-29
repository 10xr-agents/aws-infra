# modules/networking/outputs.tf

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

# output "global_accelerator_arn" {
#   description = "ARN of the Global Accelerator"
#   value       = aws_globalaccelerator_accelerator.main.id
# }
#
# output "global_accelerator_ips" {
#   description = "Static IP addresses of the Global Accelerator"
#   value       = aws_globalaccelerator_accelerator.main.ip_sets[0].ip_addresses
# }

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

# output "global_accelerator_id" {
#   description = "ID of the Global Accelerator"
#   value       = aws_globalaccelerator_accelerator.main.id
# }
#
# output "global_accelerator_dns_name" {
#   description = "DNS name of the Global Accelerator"
#   value       = aws_globalaccelerator_accelerator.main.dns_name
# }
#
# output "global_accelerator_ip_sets" {
#   description = "IP address sets of the Global Accelerator"
#   value       = aws_globalaccelerator_accelerator.main.ip_sets
# }