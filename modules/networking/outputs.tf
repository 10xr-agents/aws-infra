# modules/networking/outputs.tf

################################################################################
# NLB Outputs
################################################################################

output "nlb_arn" {
  description = "ARN of the Network Load Balancer"
  value       = var.create_nlb ? aws_lb.public_nlb[0].arn : null
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = var.create_nlb ? aws_lb.public_nlb[0].dns_name : null
}

output "nlb_zone_id" {
  description = "Hosted zone ID of the Network Load Balancer"
  value       = var.create_nlb ? aws_lb.public_nlb[0].zone_id : null
}

output "nlb_id" {
  description = "ID of the Network Load Balancer"
  value       = var.create_nlb ? aws_lb.public_nlb[0].id : null
}

output "nlb_arn_suffix" {
  description = "ARN suffix of the Network Load Balancer"
  value       = var.create_nlb ? aws_lb.public_nlb[0].arn_suffix : null
}

output "nlb_subnets" {
  description = "List of subnet IDs attached to the NLB"
  value       = var.create_nlb ? aws_lb.public_nlb[0].subnets : []
}

output "nlb_vpc_id" {
  description = "VPC ID of the Network Load Balancer"
  value       = var.create_nlb ? aws_lb.public_nlb[0].vpc_id : null
}

output "nlb_type" {
  description = "Type of the Network Load Balancer"
  value       = var.create_nlb ? aws_lb.public_nlb[0].load_balancer_type : null
}

output "nlb_internal" {
  description = "Whether the NLB is internal"
  value       = var.create_nlb ? aws_lb.public_nlb[0].internal : null
}

################################################################################
# S3 Bucket Outputs
################################################################################

output "access_logs_bucket_id" {
  description = "ID of the S3 bucket for access logs"
  value       = var.nlb_access_logs_enabled ? aws_s3_bucket.nlb_access_logs[0].id : null
}

output "access_logs_bucket_arn" {
  description = "ARN of the S3 bucket for access logs"
  value       = var.nlb_access_logs_enabled ? aws_s3_bucket.nlb_access_logs[0].arn : null
}

output "connection_logs_bucket_id" {
  description = "ID of the S3 bucket for connection logs"
  value       = var.nlb_connection_logs_enabled ? aws_s3_bucket.nlb_connection_logs[0].id : null
}

output "connection_logs_bucket_arn" {
  description = "ARN of the S3 bucket for connection logs"
  value       = var.nlb_connection_logs_enabled ? aws_s3_bucket.nlb_connection_logs[0].arn : null
}

output "s3_buckets" {
  description = "Information about created S3 buckets"
  value = {
    access_logs = var.nlb_access_logs_enabled ? {
      id     = aws_s3_bucket.nlb_access_logs[0].id
      arn    = aws_s3_bucket.nlb_access_logs[0].arn
      domain = aws_s3_bucket.nlb_access_logs[0].bucket_domain_name
    } : null
    connection_logs = var.nlb_connection_logs_enabled ? {
      id     = aws_s3_bucket.nlb_connection_logs[0].id
      arn    = aws_s3_bucket.nlb_connection_logs[0].arn
      domain = aws_s3_bucket.nlb_connection_logs[0].bucket_domain_name
    } : null
  }
}

################################################################################
# Target Group Outputs
################################################################################

output "http_target_group_arn" {
  description = "ARN of the HTTP target group"
  value       = var.create_nlb && var.create_http_target_group ? aws_lb_target_group.alb_targets_http[0].arn : null
}

output "https_target_group_arn" {
  description = "ARN of the HTTPS target group"
  value       = var.create_nlb ? aws_lb_target_group.alb_targets_https[0].arn : null
}

output "http_target_group_name" {
  description = "Name of the HTTP target group"
  value       = var.create_nlb && var.create_http_target_group ? aws_lb_target_group.alb_targets_http[0].name : null
}

output "https_target_group_name" {
  description = "Name of the HTTPS target group"
  value       = var.create_nlb ? aws_lb_target_group.alb_targets_https[0].name : null
}

output "custom_target_group_arns" {
  description = "Map of custom target group ARNs"
  value = {
    for name, tg in aws_lb_target_group.custom : name => tg.arn
  }
}

output "custom_target_group_names" {
  description = "Map of custom target group names"
  value = {
    for name, tg in aws_lb_target_group.custom : name => tg.name
  }
}

output "target_groups" {
  description = "Map of all target groups"
  value = merge(
      var.create_nlb && var.create_http_target_group ? {
      http = {
        arn  = aws_lb_target_group.alb_targets_http[0].arn
        name = aws_lb_target_group.alb_targets_http[0].name
        port = aws_lb_target_group.alb_targets_http[0].port
      }
    } : {},
      var.create_nlb ? {
      https = {
        arn  = aws_lb_target_group.alb_targets_https[0].arn
        name = aws_lb_target_group.alb_targets_https[0].name
        port = aws_lb_target_group.alb_targets_https[0].port
      }
    } : {},
    {
      for name, tg in aws_lb_target_group.custom : name => {
      arn  = tg.arn
      name = tg.name
      port = tg.port
    }
    }
  )
}

################################################################################
# Listener Outputs
################################################################################

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = var.create_nlb && var.create_http_listener ? aws_lb_listener.public_nlb_http[0].arn : null
}

output "https_tcp_listener_arn" {
  description = "ARN of the HTTPS TCP listener"
  value       = var.create_nlb && var.create_https_listener && var.https_listener_protocol == "TCP" ? aws_lb_listener.public_nlb_https_tcp[0].arn : null
}

output "https_tls_listener_arn" {
  description = "ARN of the HTTPS TLS listener"
  value       = var.create_nlb && var.create_https_listener && var.https_listener_protocol == "TLS" ? aws_lb_listener.public_nlb_https_tls[0].arn : null
}

output "custom_listener_arns" {
  description = "Map of custom listener ARNs"
  value = {
    for name, listener in aws_lb_listener.custom : name => listener.arn
  }
}

output "listeners" {
  description = "Map of all listeners"
  value = merge(
      var.create_nlb && var.create_http_listener ? {
      http = {
        arn      = aws_lb_listener.public_nlb_http[0].arn
        port     = aws_lb_listener.public_nlb_http[0].port
        protocol = aws_lb_listener.public_nlb_http[0].protocol
      }
    } : {},
      var.create_nlb && var.create_https_listener && var.https_listener_protocol == "TCP" ? {
      https_tcp = {
        arn      = aws_lb_listener.public_nlb_https_tcp[0].arn
        port     = aws_lb_listener.public_nlb_https_tcp[0].port
        protocol = aws_lb_listener.public_nlb_https_tcp[0].protocol
      }
    } : {},
      var.create_nlb && var.create_https_listener && var.https_listener_protocol == "TLS" ? {
      https_tls = {
        arn      = aws_lb_listener.public_nlb_https_tls[0].arn
        port     = aws_lb_listener.public_nlb_https_tls[0].port
        protocol = aws_lb_listener.public_nlb_https_tls[0].protocol
      }
    } : {},
    {
      for name, listener in aws_lb_listener.custom : name => {
      arn      = listener.arn
      port     = listener.port
      protocol = listener.protocol
    }
    }
  )
}

################################################################################
# Security Group Outputs
################################################################################

output "security_group_id" {
  description = "ID of the NLB security group"
  value       = var.create_nlb && var.create_security_groups ? aws_security_group.nlb[0].id : null
}

output "security_group_arn" {
  description = "ARN of the NLB security group"
  value       = var.create_nlb && var.create_security_groups ? aws_security_group.nlb[0].arn : null
}

################################################################################
# Route 53 Outputs
################################################################################

output "route53_record_fqdn" {
  description = "FQDN of the Route 53 record"
  value       = var.create_nlb && var.create_route53_record ? aws_route53_record.nlb[0].fqdn : null
}

output "route53_record_name" {
  description = "Name of the Route 53 record"
  value       = var.create_nlb && var.create_route53_record ? aws_route53_record.nlb[0].name : null
}

################################################################################
# CloudWatch Alarms Outputs
################################################################################

output "healthy_host_count_alarm_arn" {
  description = "ARN of the healthy host count CloudWatch alarm"
  value       = var.create_nlb && var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.nlb_healthy_host_count[0].arn : null
}

output "unhealthy_host_count_alarm_arn" {
  description = "ARN of the unhealthy host count CloudWatch alarm"
  value       = var.create_nlb && var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.nlb_unhealthy_host_count[0].arn : null
}

################################################################################
# Connection Information
################################################################################

output "nlb_connection_info" {
  description = "NLB connection information"
  value = var.create_nlb ? {
    dns_name = aws_lb.public_nlb[0].dns_name
    zone_id  = aws_lb.public_nlb[0].zone_id
    arn      = aws_lb.public_nlb[0].arn
    http_url = var.create_http_listener ? "http://${aws_lb.public_nlb[0].dns_name}" : null
    https_url = var.create_https_listener ? "https://${aws_lb.public_nlb[0].dns_name}" : null
    subnets  = aws_lb.public_nlb[0].subnets
    vpc_id   = aws_lb.public_nlb[0].vpc_id
    internal = aws_lb.public_nlb[0].internal
  } : null
}

################################################################################
# Configuration Summary
################################################################################

output "nlb_configuration" {
  description = "Summary of NLB configuration"
  value = var.create_nlb ? {
    name                             = aws_lb.public_nlb[0].name
    internal                         = aws_lb.public_nlb[0].internal
    load_balancer_type               = aws_lb.public_nlb[0].load_balancer_type
    cross_zone_load_balancing_enabled = aws_lb.public_nlb[0].enable_cross_zone_load_balancing
    deletion_protection_enabled      = aws_lb.public_nlb[0].enable_deletion_protection
    access_logs_enabled              = var.nlb_access_logs_enabled
    connection_logs_enabled          = var.nlb_connection_logs_enabled
    http_listener_enabled            = var.create_http_listener
    https_listener_enabled           = var.create_https_listener
    https_listener_protocol          = var.https_listener_protocol
    target_groups_created            = length(aws_lb_target_group.custom) + (var.create_http_target_group ? 1 : 0) + (var.create_https_target_group ? 1 : 0)
    custom_listeners_created         = length(aws_lb_listener.custom)
    security_groups_created          = var.create_security_groups
    route53_record_created           = var.create_route53_record
    cloudwatch_alarms_created        = var.create_cloudwatch_alarms
  } : null
}