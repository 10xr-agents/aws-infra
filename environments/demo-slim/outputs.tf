output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_service_names" {
  description = "The names of the ECS services"
  value       = aws_ecs_service.service[*].name
}

output "on_demand_asg_name" {
  description = "The name of the On-Demand Auto Scaling Group"
  value       = aws_autoscaling_group.on_demand.name
}

output "spot_asg_name" {
  description = "The name of the Spot Auto Scaling Group"
  value       = aws_autoscaling_group.spot.name
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch Log Group for ECS logs"
  value       = aws_cloudwatch_log_group.ecs_logs.name
}

output "alb_target_group_arns" {
  description = "The ARNs of the ALB target groups"
  value       = aws_lb_target_group.service[*].arn
}