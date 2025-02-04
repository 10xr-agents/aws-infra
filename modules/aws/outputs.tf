output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "elastic_cache_subnet_ids" {
  description = "List of elastic cache subnet IDs"
  value       = module.vpc.elasticache_subnets
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDRs"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "elastic_cache_subnet_cidrs" {
  description = "List of elastic cache subnet CIDRs"
  value       = module.vpc.elasticache_subnets_cidr_blocks
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

output "public_route_table_ids" {
  description = "List of public route table IDs"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = module.vpc.private_route_table_ids
}

output "elastic_cache_route_table_ids" {
  description = "List of elastic cache route table IDs"
  value       = module.vpc.elasticache_route_table_ids
}

output "public_subnet_ip_v6_cidrs" {
  description = "List of public subnet IP V6 CIDRs"
  value       = module.vpc.public_subnets_ipv6_cidr_blocks
}

output "private_subnet_ip_v6_cidrs" {
  description = "List of private subnet IP V6 CIDRs"
  value       = module.vpc.private_subnets_ipv6_cidr_blocks
}

output "elastic_cache_subnet_ip_v6_cidrs" {
  description = "List of elastic cache subnet IP V6 CIDRs"
  value       = module.vpc.elasticache_subnets_ipv6_cidr_blocks
}

output "vpc_ip_v6_cidrs" {
  value = module.vpc.vpc_ipv6_cidr_block
}

# Output the number of AZs being used
output "azs" {
  description = "Number of AZs being used in the VPC"
  value       = module.vpc.azs
}

# ECS Outputs
# output "ecs_cluster_id" {
#   description = "ID of the ECS cluster"
#   value       = module.ecs.cluster_id
# }
#
# output "ecs_cluster_name" {
#   description = "Name of the ECS cluster"
#   value       = module.ecs.cluster_name
# }
#
# output "ecs_services" {
#   description = "Map of ECS services created"
#   value = module.ecs.services
# }
#
# # ALB Outputs
# output "alb_dns_name" {
#   description = "The DNS name of the load balancer"
#   value       = module.alb.dns_name
# }
#
# output "alb_zone_id" {
#   description = "The canonical hosted zone ID of the load balancer"
#   value       = module.alb.zone_id
# }
#
# # Output the EFS file system ID and access points
# output "efs_file_system_id" {
#   description = "EFS File System ID"
#   value       = module.efs.id
# }
#
# output "efs_file_system_dns_name" {
#   description = "EFS File System DNS name"
#   value       = module.efs.dns_name
# }
#
# output "efs_access_points" {
#   description = "EFS Access Points"
#   value       = aws_efs_access_point.service[*].id
# }