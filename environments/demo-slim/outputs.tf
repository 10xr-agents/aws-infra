output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "ecs_services" {
  description = "Details of the ECS services"
  value = [
    for i, service in aws_ecs_service.service : {
      name             = service.name
      cluster          = service.cluster
      desired_count    = service.desired_count
      task_definition  = service.task_definition
      load_balancer    = service.load_balancer
    }
  ]
}

output "ecs_task_definitions" {
  description = "ARNs of the ECS task definitions"
  value = {
    for i, task in aws_ecs_task_definition.service :
    var.services[i].name => task.arn
  }
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group for ECS logs"
  value       = aws_cloudwatch_log_group.ecs_logs.name
}

output "alb_target_groups" {
  description = "ARNs of the ALB target groups"
  value = {
    for i, tg in aws_lb_target_group.service :
    var.services[i].name => tg.arn
  }
}

output "ecs_security_group_id" {
  description = "ID of the ECS security group"
  value       = aws_security_group.ecs_sg.id
}

output "on_demand_asg_name" {
  description = "Name of the On-Demand Auto Scaling Group"
  value       = aws_autoscaling_group.on_demand.name
}

output "spot_asg_name" {
  description = "Name of the Spot Auto Scaling Group"
  value       = aws_autoscaling_group.spot.name
}

output "service_discovery_namespace" {
  description = "The Service Discovery namespace"
  value       = var.enable_service_discovery ? aws_service_discovery_private_dns_namespace.main[0].name : null
}

output "service_discovery_services" {
  description = "The Service Discovery service ARNs"
  value = var.enable_service_discovery ? {
    for i, service in aws_service_discovery_service.service :
    var.services[i].name => service.arn
  } : null
}

output "ecs_task_role_arns" {
  description = "ARNs of the ECS task roles"
  value = {
    for i, role in aws_iam_role.ecs_task_role :
    var.services[i].name => role.arn
  }
}