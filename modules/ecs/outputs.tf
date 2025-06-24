# modules/ecs/outputs.tf

output "cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "ecs_instances_security_group_id" {
  description = "Security group ID for ECS instances (if EC2 is enabled)"
  value       = var.enable_ec2 ? aws_security_group.ecs_instances[0].id : null
}

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "task_execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.name
}

output "capacity_providers" {
  description = "List of capacity providers associated with the cluster"
  value       = aws_ecs_cluster_capacity_providers.main.capacity_providers
}

output "ec2_asg_arn" {
  description = "ARN of the EC2 Auto Scaling Group (if EC2 is enabled)"
  value       = var.enable_ec2 ? aws_autoscaling_group.ecs[0].arn : null
}

output "ec2_asg_name" {
  description = "Name of the EC2 Auto Scaling Group (if EC2 is enabled)"
  value       = var.enable_ec2 ? aws_autoscaling_group.ecs[0].name : null
}