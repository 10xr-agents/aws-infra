# modules/global-accelerator/outputs.tf

################################################################################
# Global Accelerator Outputs
################################################################################

output "accelerator_id" {
  description = "The ID of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.main.id
}

output "accelerator_arn" {
  description = "The ARN of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.main.id
}

output "accelerator_dns_name" {
  description = "The DNS name of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.main.dns_name
}

output "accelerator_dual_stack_dns_name" {
  description = "The dual-stack DNS name of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.main.dual_stack_dns_name
}

output "accelerator_hosted_zone_id" {
  description = "The hosted zone ID of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.main.hosted_zone_id
}

output "accelerator_ip_sets" {
  description = "IP address sets associated with the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.main.ip_sets
}

################################################################################
# Static IP Addresses
################################################################################

output "static_ip_addresses" {
  description = "List of static IP addresses for the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.main.ip_sets[*].ip_addresses
}

output "static_ip_addresses_flat" {
  description = "Flattened list of static IP addresses"
  value       = flatten(aws_globalaccelerator_accelerator.main.ip_sets[*].ip_addresses)
}

################################################################################
# Listener Outputs
################################################################################

output "listener_id" {
  description = "The ID of the main listener"
  value       = aws_globalaccelerator_listener.main.id
}

output "listener_arn" {
  description = "The ARN of the main listener"
  value       = aws_globalaccelerator_listener.main.id
}

output "additional_listener_ids" {
  description = "IDs of additional listeners"
  value       = aws_globalaccelerator_listener.additional[*].id
}

output "additional_listener_arns" {
  description = "ARNs of additional listeners"
  value       = aws_globalaccelerator_listener.additional[*].id
}

################################################################################
# Endpoint Group Outputs
################################################################################

output "endpoint_group_id" {
  description = "The ID of the main endpoint group"
  value       = aws_globalaccelerator_endpoint_group.main.id
}

output "endpoint_group_arn" {
  description = "The ARN of the main endpoint group"
  value       = aws_globalaccelerator_endpoint_group.main.arn
}

output "additional_endpoint_group_ids" {
  description = "IDs of additional endpoint groups"
  value       = aws_globalaccelerator_endpoint_group.additional[*].id
}

output "additional_endpoint_group_arns" {
  description = "ARNs of additional endpoint groups"
  value       = aws_globalaccelerator_endpoint_group.additional[*].arn
}

################################################################################
# S3 Bucket Outputs (Flow Logs)
################################################################################

output "flow_logs_bucket_id" {
  description = "The ID of the S3 bucket for flow logs"
  value       = var.enable_flow_logs ? aws_s3_bucket.flow_logs[0].id : null
}

output "flow_logs_bucket_arn" {
  description = "The ARN of the S3 bucket for flow logs"
  value       = var.enable_flow_logs ? aws_s3_bucket.flow_logs[0].arn : null
}

output "flow_logs_bucket_domain_name" {
  description = "The domain name of the S3 bucket for flow logs"
  value       = var.enable_flow_logs ? aws_s3_bucket.flow_logs[0].bucket_domain_name : null
}

################################################################################
# CloudWatch Alarm Outputs
################################################################################

output "cloudwatch_alarm_new_flow_count_arn" {
  description = "ARN of the new flow count CloudWatch alarm"
  value       = var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.new_flow_count[0].arn : null
}

output "cloudwatch_alarm_processed_bytes_in_arn" {
  description = "ARN of the processed bytes in CloudWatch alarm"
  value       = var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.processed_bytes_in[0].arn : null
}

################################################################################
# Configuration Summary
################################################################################

output "accelerator_configuration" {
  description = "Summary of Global Accelerator configuration"
  value = {
    dns_name                = aws_globalaccelerator_accelerator.main.dns_name
    ip_address_type         = aws_globalaccelerator_accelerator.main.ip_address_type
    enabled                 = aws_globalaccelerator_accelerator.main.enabled
    static_ips              = flatten(aws_globalaccelerator_accelerator.main.ip_sets[*].ip_addresses)
    flow_logs_enabled       = var.enable_flow_logs
    flow_logs_bucket        = var.enable_flow_logs ? aws_s3_bucket.flow_logs[0].id : null
    listener_protocol       = var.protocol
    listener_client_affinity = var.client_affinity
    endpoint_count          = length(var.endpoints)
    health_check_protocol   = var.health_check_protocol
    health_check_path       = var.health_check_path
  }
}

################################################################################
# URLs and Connection Information
################################################################################

output "accelerator_url_http" {
  description = "HTTP URL for the Global Accelerator"
  value       = "http://${aws_globalaccelerator_accelerator.main.dns_name}"
}

output "accelerator_url_https" {
  description = "HTTPS URL for the Global Accelerator"
  value       = "https://${aws_globalaccelerator_accelerator.main.dns_name}"
}

output "accelerator_connection_info" {
  description = "Connection information for the Global Accelerator"
  value = {
    dns_name    = aws_globalaccelerator_accelerator.main.dns_name
    static_ips  = flatten(aws_globalaccelerator_accelerator.main.ip_sets[*].ip_addresses)
    ports       = var.port_ranges
    protocol    = var.protocol
    http_url    = "http://${aws_globalaccelerator_accelerator.main.dns_name}"
    https_url   = "https://${aws_globalaccelerator_accelerator.main.dns_name}"
  }
}