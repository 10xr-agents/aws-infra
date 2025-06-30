# modules/livekit-proxy-ecs/outputs.tf

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.livekit_proxy.name
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.livekit_proxy.id
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.livekit_proxy.arn
}

output "task_definition_family" {
  description = "Family of the task definition"
  value       = aws_ecs_task_definition.livekit_proxy.family
}

output "task_definition_revision" {
  description = "Revision of the task definition"
  value       = aws_ecs_task_definition.livekit_proxy.revision
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.livekit_proxy.arn
}

output "target_group_name" {
  description = "Name of the target group"
  value       = aws_lb_target_group.livekit_proxy.name
}

output "security_group_id" {
  description = "ID of the LiveKit proxy security group"
  value       = aws_security_group.livekit_proxy.id
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.livekit_proxy.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.livekit_proxy.arn
}

output "service_discovery_service_arn" {
  description = "ARN of the service discovery service"
  value       = var.enable_service_discovery ? aws_service_discovery_service.livekit_proxy[0].arn : null
}

output "service_discovery_service_name" {
  description = "Name of the service discovery service"
  value       = var.enable_service_discovery ? aws_service_discovery_service.livekit_proxy[0].name : null
}

output "auto_scaling_target_resource_id" {
  description = "Resource ID of the auto scaling target"
  value       = var.enable_auto_scaling ? aws_appautoscaling_target.livekit_proxy[0].resource_id : null
}