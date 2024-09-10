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
      name                       = service.name
      cluster                    = service.cluster
      desired_count              = service.desired_count
      task_definition            = service.task_definition
      load_balancer              = service.load_balancer
      capacity_provider_strategy = service.capacity_provider_strategy
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

output "ecs_capacity_providers" {
  description = "Names of the ECS capacity providers"
  value = {
    ec2_on_demand = aws_ecs_capacity_provider.ec2["on_demand"].name
    ec2_spot      = aws_ecs_capacity_provider.ec2["spot"].name
    fargate       = "FARGATE"
    fargate_spot  = "FARGATE_SPOT"
  }
}

output "auto_scaling_groups" {
  description = "Names of the Auto Scaling Groups"
  value = {
    on_demand = aws_autoscaling_group.ecs_asg["on_demand"].name
    spot      = aws_autoscaling_group.ecs_asg["spot"].name
  }
}

output "launch_template_ids" {
  description = "IDs of the Launch Templates"
  value = {
    on_demand = aws_launch_template.on_demand.id
    spot      = aws_launch_template.spot.id
  }
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

output "ecs_execution_role_arn" {
  description = "ARN of the ECS execution role"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ecs_instance_profile_name" {
  description = "Name of the ECS instance profile"
  value       = aws_iam_instance_profile.ecs_instance_profile.name
}

# Output for manual DNS validation
output "acm_validation_records" {
  value = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  description = "The DNS records to create in Cloudflare for ACM certificate validation"
}

output "livekit_api_key" {
  description = "LiveKit API key"
  value       = var.livekit_api_key
}

# output "livekit_api_secret" {
#   description = "LiveKit API secret"
#   value       = random_password.livekit_api_secret
#   sensitive   = true
# }

# Output the access keys (Be cautious with this in production environments)
output "s3_external_access_key_id" {
  value = aws_iam_access_key.s3_external_access.id
  description = "Access Key ID for S3 external access"
}

output "s3_external_access_secret" {
  value = aws_iam_access_key.s3_external_access.secret
  description = "Secret Access Key for S3 external access"
  sensitive = true
}

output "s3_external_access_bucket_name" {
  value = aws_s3_bucket.external_access.id
  description = "Name of the S3 bucket for external access"
}

# Output the Global Accelerator DNS name
output "global_accelerator_dns_name" {
  value       = aws_globalaccelerator_accelerator.main.dns_name
  description = "The DNS name of the Global Accelerator"
}

# Output the Global Accelerator IP addresses
output "global_accelerator_ip_addresses" {
  value       = aws_globalaccelerator_accelerator.main.ip_sets[0].ip_addresses
  description = "The IP addresses of the Global Accelerator"
}

output "redis_endpoint" {
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  description = "The endpoint of the Redis ElastiCache cluster"
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "eks_cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = aws_eks_cluster.main.name
}

output "eks_admin_role_arn" {
  description = "ARN of the EKS admin role"
  value       = aws_iam_role.eks_admin.arn
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks get-token --cluster-name ${aws_eks_cluster.main.name} | kubectl apply -f -"
}