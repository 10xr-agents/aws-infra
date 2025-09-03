# modules/ecs-gpu/outputs.tf - Outputs for GPU ECS module

################################################################################
# Cluster Outputs
################################################################################

output "cluster_arn" {
  description = "ARN that identifies the cluster"
  value       = aws_ecs_cluster.gpu.arn
}

output "cluster_id" {
  description = "ID that identifies the cluster"
  value       = aws_ecs_cluster.gpu.id
}

output "cluster_name" {
  description = "Name that identifies the cluster"
  value       = aws_ecs_cluster.gpu.name
}

################################################################################
# Capacity Provider Outputs
################################################################################

output "capacity_provider_arn" {
  description = "ARN of the ECS capacity provider"
  value       = aws_ecs_capacity_provider.gpu.arn
}

output "capacity_provider_name" {
  description = "Name of the ECS capacity provider"
  value       = aws_ecs_capacity_provider.gpu.name
}

################################################################################
# Auto Scaling Group Outputs
################################################################################

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.ecs_gpu.arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.ecs_gpu.name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.ecs_gpu.id
}

################################################################################
# Service Outputs
################################################################################

output "services" {
  description = "Map of services created and their attributes"
  value = {
    for name, service in aws_ecs_service.service : name => {
      id              = service.id
      name            = service.name
      cluster         = service.cluster
      task_definition = service.task_definition
      desired_count   = service.desired_count
      arn             = service.id
    }
  }
}

output "service_arns" {
  description = "Map of service names to their ARNs"
  value = {
    for name, service in aws_ecs_service.service : name => service.id
  }
}

################################################################################
# Task Definition Outputs
################################################################################

output "task_definition_arns" {
  description = "Map of service names to their task definition ARNs"
  value = {
    for name, task_def in aws_ecs_task_definition.service : name => task_def.arn
  }
}

output "task_definition_revisions" {
  description = "Map of service names to their task definition revisions"
  value = {
    for name, task_def in aws_ecs_task_definition.service : name => task_def.revision
  }
}

################################################################################
# IAM Outputs
################################################################################

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

output "ecs_instance_role_arn" {
  description = "ARN of the ECS instance role"
  value       = aws_iam_role.ecs_instance.arn
}

################################################################################
# Security Group Outputs
################################################################################

output "ecs_instances_security_group_id" {
  description = "ID of the ECS instances security group"
  value       = aws_security_group.ecs_instances.id
}

output "service_security_group_ids" {
  description = "Map of service names to their security group IDs"
  value = {
    for name, sg in aws_security_group.ecs_service : name => sg.id
  }
}

################################################################################
# Target Group Outputs (if ALB enabled)
################################################################################

output "target_group_arns" {
  description = "Map of service names to their target group ARNs"
  value = {
    for name, tg in aws_lb_target_group.service : name => tg.arn
  }
}

################################################################################
# Log Group Outputs
################################################################################

output "cluster_log_group_name" {
  description = "Name of the cluster CloudWatch log group"
  value       = aws_cloudwatch_log_group.cluster.name
}

output "service_log_group_names" {
  description = "Map of service names to their CloudWatch log group names"
  value = {
    for name, lg in aws_cloudwatch_log_group.service_logs : name => lg.name
  }
}

################################################################################
# Configuration Summary
################################################################################

output "gpu_cluster_configuration" {
  description = "Summary of GPU cluster configuration"
  value = {
    cluster_name         = aws_ecs_cluster.gpu.name
    capacity_provider    = aws_ecs_capacity_provider.gpu.name
    instance_types       = var.instance_types
    min_capacity        = var.min_size
    max_capacity        = var.max_size
    desired_capacity    = var.desired_capacity
    services_deployed   = length(aws_ecs_service.service)
    gpu_enabled_services = length([
      for name, config in var.services : name
      if config.gpu_count > 0
    ])
  }
}