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

# Agent Analytics Outputs
output "agent_analytics_service_name" {
  description = "Name of the agent analytics ECS service"
  value       = aws_ecs_service.agent_analytics.name
}

output "agent_analytics_service_arn" {
  description = "ARN of the agent analytics ECS service"
  value       = aws_ecs_service.agent_analytics.id
}

output "agent_analytics_task_definition_arn" {
  description = "ARN of the agent analytics task definition"
  value       = aws_ecs_task_definition.agent_analytics.arn
}

output "agent_analytics_task_definition_family" {
  description = "Family of the agent analytics task definition"
  value       = aws_ecs_task_definition.agent_analytics.family
}

output "agent_analytics_task_definition_revision" {
  description = "Revision of the agent analytics task definition"
  value       = aws_ecs_task_definition.agent_analytics.revision
}

output "agent_analytics_target_group_arn" {
  description = "ARN of the agent analytics target group"
  value       = aws_lb_target_group.agent_analytics.arn
}

output "agent_analytics_target_group_name" {
  description = "Name of the agent analytics target group"
  value       = aws_lb_target_group.agent_analytics.name
}

output "agent_analytics_security_group_id" {
  description = "ID of the agent analytics security group"
  value       = aws_security_group.agent_analytics.id
}

output "agent_analytics_cloudwatch_log_group_name" {
  description = "Name of the agent analytics CloudWatch log group"
  value       = aws_cloudwatch_log_group.agent_analytics.name
}

output "agent_analytics_cloudwatch_log_group_arn" {
  description = "ARN of the agent analytics CloudWatch log group"
  value       = aws_cloudwatch_log_group.agent_analytics.arn
}

output "agent_analytics_service_discovery_service_arn" {
  description = "ARN of the agent analytics service discovery service"
  value       = var.agent_analytics_enable_service_discovery ? aws_service_discovery_service.agent_analytics[0].arn : null
}

output "agent_analytics_service_discovery_service_name" {
  description = "Name of the agent analytics service discovery service"
  value       = var.agent_analytics_enable_service_discovery ? aws_service_discovery_service.agent_analytics[0].name : null
}

output "agent_analytics_auto_scaling_target_resource_id" {
  description = "Resource ID of the agent analytics auto scaling target"
  value       = var.agent_analytics_enable_auto_scaling ? aws_appautoscaling_target.agent_analytics[0].resource_id : null
}

# UI Console Outputs
output "ui_console_service_name" {
  description = "Name of the UI console ECS service"
  value       = aws_ecs_service.ui_console.name
}

output "ui_console_service_arn" {
  description = "ARN of the UI console ECS service"
  value       = aws_ecs_service.ui_console.id
}

output "ui_console_task_definition_arn" {
  description = "ARN of the UI console task definition"
  value       = aws_ecs_task_definition.ui_console.arn
}

output "ui_console_task_definition_family" {
  description = "Family of the UI console task definition"
  value       = aws_ecs_task_definition.ui_console.family
}

output "ui_console_task_definition_revision" {
  description = "Revision of the UI console task definition"
  value       = aws_ecs_task_definition.ui_console.revision
}

output "ui_console_target_group_arn" {
  description = "ARN of the UI console target group"
  value       = aws_lb_target_group.ui_console.arn
}

output "ui_console_target_group_name" {
  description = "Name of the UI console target group"
  value       = aws_lb_target_group.ui_console.name
}

output "ui_console_security_group_id" {
  description = "ID of the UI console security group"
  value       = aws_security_group.ui_console.id
}

output "ui_console_cloudwatch_log_group_name" {
  description = "Name of the UI console CloudWatch log group"
  value       = aws_cloudwatch_log_group.ui_console.name
}

output "ui_console_cloudwatch_log_group_arn" {
  description = "ARN of the UI console CloudWatch log group"
  value       = aws_cloudwatch_log_group.ui_console.arn
}

output "ui_console_service_discovery_service_arn" {
  description = "ARN of the UI console service discovery service"
  value       = var.ui_console_enable_service_discovery ? aws_service_discovery_service.ui_console[0].arn : null
}

output "ui_console_service_discovery_service_name" {
  description = "Name of the UI console service discovery service"
  value       = var.ui_console_enable_service_discovery ? aws_service_discovery_service.ui_console[0].name : null
}

output "ui_console_auto_scaling_target_resource_id" {
  description = "Resource ID of the UI console auto scaling target"
  value       = var.ui_console_enable_auto_scaling ? aws_appautoscaling_target.ui_console[0].resource_id : null
}

# Agentic Framework Outputs
output "agentic_framework_service_name" {
  description = "Name of the agentic framework ECS service"
  value       = aws_ecs_service.agentic_framework.name
}

output "agentic_framework_service_arn" {
  description = "ARN of the agentic framework ECS service"
  value       = aws_ecs_service.agentic_framework.id
}

output "agentic_framework_task_definition_arn" {
  description = "ARN of the agentic framework task definition"
  value       = aws_ecs_task_definition.agentic_framework.arn
}

output "agentic_framework_task_definition_family" {
  description = "Family of the agentic framework task definition"
  value       = aws_ecs_task_definition.agentic_framework.family
}

output "agentic_framework_task_definition_revision" {
  description = "Revision of the agentic framework task definition"
  value       = aws_ecs_task_definition.agentic_framework.revision
}

output "agentic_framework_target_group_arn" {
  description = "ARN of the agentic framework target group"
  value       = aws_lb_target_group.agentic_framework.arn
}

output "agentic_framework_target_group_name" {
  description = "Name of the agentic framework target group"
  value       = aws_lb_target_group.agentic_framework.name
}

output "agentic_framework_security_group_id" {
  description = "ID of the agentic framework security group"
  value       = aws_security_group.agentic_framework.id
}

output "agentic_framework_cloudwatch_log_group_name" {
  description = "Name of the agentic framework CloudWatch log group"
  value       = aws_cloudwatch_log_group.agentic_framework.name
}

output "agentic_framework_cloudwatch_log_group_arn" {
  description = "ARN of the agentic framework CloudWatch log group"
  value       = aws_cloudwatch_log_group.agentic_framework.arn
}

output "agentic_framework_service_discovery_service_arn" {
  description = "ARN of the agentic framework service discovery service"
  value       = var.agentic_framework_enable_service_discovery ? aws_service_discovery_service.agentic_framework[0].arn : null
}

output "agentic_framework_service_discovery_service_name" {
  description = "Name of the agentic framework service discovery service"
  value       = var.agentic_framework_enable_service_discovery ? aws_service_discovery_service.agentic_framework[0].name : null
}

output "agentic_framework_auto_scaling_target_resource_id" {
  description = "Resource ID of the agentic framework auto scaling target"
  value       = var.agentic_framework_enable_auto_scaling ? aws_appautoscaling_target.agentic_framework[0].resource_id : null
}