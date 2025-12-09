# modules/ecs/outputs.tf

# Cluster Outputs
output "cluster_arn" {
  description = "ARN that identifies the cluster"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_id" {
  description = "ID that identifies the cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Name that identifies the cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_capacity_providers" {
  description = "Set of capacity providers associated with the cluster"
  value       = aws_ecs_cluster_capacity_providers.main.capacity_providers
}

# Services Outputs
output "services" {
  description = "Map of services created and their attributes"
  value = {
    for name, service in aws_ecs_service.service : name => {
      id               = service.id
      name             = service.name
      cluster          = service.cluster
      task_definition  = service.task_definition
      desired_count    = service.desired_count
      launch_type      = service.launch_type
      platform_version = service.platform_version
      arn              = service.id
    }
  }
}

# Service ARNs
output "service_arns" {
  description = "Map of service names to their ARNs"
  value = {
    for name, service in aws_ecs_service.service : name => service.id
  }
}

# Task Definition ARNs
output "task_definition_arns" {
  description = "Map of service names to their task definition ARNs"
  value = {
    for name, task_def in aws_ecs_task_definition.service : name => task_def.arn
  }
}

# Task Definition Revisions
output "task_definition_revisions" {
  description = "Map of service names to their task definition revisions"
  value = {
    for name, task_def in aws_ecs_task_definition.service : name => task_def.revision
  }
}

# IAM Roles
output "task_execution_role_arns" {
  description = "Map of service names to their task execution role ARNs"
  value = {
    for name, role in aws_iam_role.task_execution_role : name => role.arn
  }
}

output "task_role_arns" {
  description = "Map of service names to their task role ARNs"
  value = {
    for name, role in aws_iam_role.task_role : name => role.arn
  }
}

output "task_role_names" {
  description = "Map of service names to their task role ARNs"
  value = {
    for name, role in aws_iam_role.task_role : name => role.name
  }
}

# Security Groups
output "security_group_ids" {
  description = "Map of service names to their security group IDs"
  value = {
    for name, sg in aws_security_group.ecs_service : name => sg.id
  }
}

# Target Groups
output "target_group_arns" {
  description = "Map of service names to their target group ARNs"
  value = {
    for name, tg in aws_lb_target_group.service : name => tg.arn
  }
}

# CloudWatch Log Groups
output "log_group_names" {
  description = "Map of service names to their CloudWatch log group names"
  value = {
    for name, config in local.services_config : name => config.log_group_name
  }
}

output "log_group_arns" {
  description = "Map of service names to their CloudWatch log group ARNs"
  value = {
    for name, lg in aws_cloudwatch_log_group.service_logs : name => lg.arn
  }
}

# Auto Scaling
output "autoscaling_target_ids" {
  description = "Map of service names to their auto scaling target resource IDs"
  value = {
    for name, target in aws_appautoscaling_target.ecs_target : name => target.resource_id
  }
}

output "autoscaling_policy_arns" {
  description = "Map of service names to their auto scaling policy ARNs"
  value = {
    cpu_policies = {
      for name, policy in aws_appautoscaling_policy.ecs_cpu_policy : name => policy.arn
    }
    memory_policies = {
      for name, policy in aws_appautoscaling_policy.ecs_memory_policy : name => policy.arn
    }
  }
}

# Service Discovery Outputs
output "service_discovery_namespace_id" {
  description = "ID of the service discovery namespace"
  value       = try(aws_service_discovery_private_dns_namespace.main[0].id, null)
}

output "service_discovery_namespace_name" {
  description = "Name of the service discovery namespace"
  value       = try(aws_service_discovery_private_dns_namespace.main[0].name, null)
}

output "service_discovery_namespace_arn" {
  description = "ARN of the service discovery namespace"
  value       = try(aws_service_discovery_private_dns_namespace.main[0].arn, null)
}

output "service_discovery_service_arns" {
  description = "Map of service discovery service ARNs"
  value = {
    for name, service in aws_service_discovery_service.services : name => service.arn
  }
}

output "service_discovery_service_ids" {
  description = "Map of service discovery service IDs"
  value = {
    for name, service in aws_service_discovery_service.services : name => service.id
  }
}

# Service URLs
output "service_urls" {
  description = "Map of service URLs (internal service discovery)"
  value = var.enable_service_discovery ? {
    for name, config in var.services : name =>
    "http://${name}.${local.name_prefix}.local:${config.port}"
    if lookup(config, "enable_service_discovery", true)
  } : {}
}

# Comprehensive service information
output "service_details" {
  description = "Comprehensive details for all services"
  value = {
    for name, config in local.services_config : name => {
      service_arn              = aws_ecs_service.service[name].id
      task_definition_arn      = aws_ecs_task_definition.service[name].arn
      task_definition_revision = aws_ecs_task_definition.service[name].revision
      security_group_id        = aws_security_group.ecs_service[name].id
      target_group_arn         = try(aws_lb_target_group.service[name].arn, null)
      log_group_name           = config.log_group_name
      service_url              = var.enable_service_discovery && lookup(config, "enable_service_discovery", true) ? "http://${name}.${local.name_prefix}.local:${config.port}" : null
      task_execution_role_arn  = aws_iam_role.task_execution_role[name].arn
      task_role_arn            = aws_iam_role.task_role[name].arn
    }
  }
}

# ALB Outputs
output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = try(aws_lb.main[0].arn, null)
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = try(aws_lb.main[0].dns_name, null)
}

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = try(aws_lb.main[0].id, null)
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = try(aws_lb.main[0].zone_id, null)
}

output "alb_security_group_id" {
  description = "Security group ID of the Application Load Balancer"
  value       = try(aws_security_group.alb[0].id, null)
}

output "alb_listener_arns" {
  description = "ARNs of the ALB listeners"
  value = {
    http  = try(aws_lb_listener.http[0].arn, null)
    https = try(aws_lb_listener.https[0].arn, null)
  }
}

output "alb_target_groups" {
  description = "Map of target groups created for services"
  value = {
    for name, tg in aws_lb_target_group.service : name => tg.name
  }
}

# ALB URLs
output "alb_urls" {
  description = "URLs for accessing the ALB"
  value = var.create_alb ? {
    http  = "http://${aws_lb.main[0].dns_name}"
    https = var.acm_certificate_arn != "" ? "https://${aws_lb.main[0].dns_name}" : null
  } : {}
}

output "listener_rule_services" {
  value = {
    for name, config in var.services : name => config
    if lookup(config, "enable_load_balancer", true) &&
    lookup(config, "alb_path_patterns", null) != null
  }
}

# ALB Log Buckets (HIPAA Compliance)
output "alb_access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  value       = try(aws_s3_bucket.alb_access_logs[0].id, null)
}

output "alb_access_logs_bucket_arn" {
  description = "ARN of S3 bucket for ALB access logs"
  value       = try(aws_s3_bucket.alb_access_logs[0].arn, null)
}

output "alb_connection_logs_bucket" {
  description = "S3 bucket for ALB connection logs"
  value       = try(aws_s3_bucket.alb_connection_logs[0].id, null)
}

output "alb_connection_logs_bucket_arn" {
  description = "ARN of S3 bucket for ALB connection logs"
  value       = try(aws_s3_bucket.alb_connection_logs[0].arn, null)
}
