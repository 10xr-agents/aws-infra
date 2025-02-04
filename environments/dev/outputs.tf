# environment/dev/outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.aws.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = var.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.aws.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.aws.private_subnet_ids
}

output "elastic_cache_subnet_ids" {
  description = "List of elastic cache subnet IDs"
  value       = module.aws.elastic_cache_subnet_ids
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.aws.nat_gateway_ids
}

output "azs" {
  description = "Availability zones being used"
  value       = module.aws.azs
}

output "vpc_ip_v6_cidr" {
  description = "IPv6 CIDR block of the VPC"
  value       = module.aws.vpc_ip_v6_cidrs
}

# ECS Outputs
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.aws.ecs_cluster_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.aws.ecs_cluster_name
}

# ALB Outputs
output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.aws.alb_dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = module.aws.alb_zone_id
}

# EFS Outputs
output "efs_file_system_id" {
  description = "ID of the EFS file system"
  value       = module.aws.efs_file_system_id
}

output "efs_file_system_dns_name" {
  description = "DNS name of the EFS file system"
  value       = module.aws.efs_file_system_dns_name
}