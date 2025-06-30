# modules/services/outputs.tf

# Voice Agent Outputs
output "voice_agent_service_name" {
  description = "Name of the voice agent ECS service"
  value       = aws_ecs_service.voice_agent.name
}

output "voice_agent_service_arn" {
  description = "ARN of the voice agent ECS service"
  value       = aws_ecs_service.voice_agent.id
}

output "voice_agent_task_definition_arn" {
  description = "ARN of the voice agent task definition"
  value       = aws_ecs_task_definition.voice_agent.arn
}

output "voice_agent_task_definition_family" {
  description = "Family of the voice agent task definition"
  value       = aws_ecs_task_definition.voice_agent.family
}

output "voice_agent_task_definition_revision" {
  description = "Revision of the voice agent task definition"
  value       = aws_ecs_task_definition.voice_agent.revision
}

output "voice_agent_target_group_arn" {
  description = "ARN of the voice agent target group"
  value       = aws_lb_target_group.voice_agent.arn
}

output "voice_agent_target_group_name" {
  description = "Name of the voice agent target group"
  value       = aws_lb_target_group.voice_agent.name
}

output "voice_agent_security_group_id" {
  description = "ID of the voice agent security group"
  value       = aws_security_group.voice_agent.id
}

output "voice_agent_cloudwatch_log_group_name" {
  description = "Name of the voice agent CloudWatch log group"
  value       = aws_cloudwatch_log_group.voice_agent.name
}

output "voice_agent_cloudwatch_log_group_arn" {
  description = "ARN of the voice agent CloudWatch log group"
  value       = aws_cloudwatch_log_group.voice_agent.arn
}

output "voice_agent_service_discovery_service_arn" {
  description = "ARN of the voice agent service discovery service"
  value       = var.voice_agent_enable_service_discovery ? aws_service_discovery_service.voice_agent[0].arn : null
}

output "voice_agent_service_discovery_service_name" {
  description = "Name of the voice agent service discovery service"
  value       = var.voice_agent_enable_service_discovery ? aws_service_discovery_service.voice_agent[0].name : null
}

output "voice_agent_auto_scaling_target_resource_id" {
  description = "Resource ID of the voice agent auto scaling target"
  value       = var.voice_agent_enable_auto_scaling ? aws_appautoscaling_target.voice_agent[0].resource_id : null
}

# LiveKit Proxy Outputs
output "livekit_proxy_service_name" {
  description = "Name of the LiveKit proxy ECS service"
  value       = aws_ecs_service.livekit_proxy.name
}

output "livekit_proxy_service_arn" {
  description = "ARN of the LiveKit proxy ECS service"
  value       = aws_ecs_service.livekit_proxy.id
}

output "livekit_proxy_task_definition_arn" {
  description = "ARN of the LiveKit proxy task definition"
  value       = aws_ecs_task_definition.livekit_proxy.arn
}

output "livekit_proxy_task_definition_family" {
  description = "Family of the LiveKit proxy task definition"
  value       = aws_ecs_task_definition.livekit_proxy.family
}

output "livekit_proxy_task_definition_revision" {
  description = "Revision of the LiveKit proxy task definition"
  value       = aws_ecs_task_definition.livekit_proxy.revision
}

output "livekit_proxy_target_group_arn" {
  description = "ARN of the LiveKit proxy target group"
  value       = aws_lb_target_group.livekit_proxy.arn
}

output "livekit_proxy_target_group_name" {
  description = "Name of the LiveKit proxy target group"
  value       = aws_lb_target_group.livekit_proxy.name
}

output "livekit_proxy_security_group_id" {
  description = "ID of the LiveKit proxy security group"
  value       = aws_security_group.livekit_proxy.id
}

output "livekit_proxy_cloudwatch_log_group_name" {
  description = "Name of the LiveKit proxy CloudWatch log group"
  value       = aws_cloudwatch_log_group.livekit_proxy.name
}

output "livekit_proxy_cloudwatch_log_group_arn" {
  description = "ARN of the LiveKit proxy CloudWatch log group"
  value       = aws_cloudwatch_log_group.livekit_proxy.arn
}

output "livekit_proxy_service_discovery_service_arn" {
  description = "ARN of the LiveKit proxy service discovery service"
  value       = var.livekit_proxy_enable_service_discovery ? aws_service_discovery_service.livekit_proxy[0].arn : null
}

output "livekit_proxy_service_discovery_service_name" {
  description = "Name of the LiveKit proxy service discovery service"
  value       = var.livekit_proxy_enable_service_discovery ? aws_service_discovery_service.livekit_proxy[0].name : null
}

output "livekit_proxy_auto_scaling_target_resource_id" {
  description = "Resource ID of the LiveKit proxy auto scaling target"
  value       = var.livekit_proxy_enable_auto_scaling ? aws_appautoscaling_target.livekit_proxy[0].resource_id : null
}