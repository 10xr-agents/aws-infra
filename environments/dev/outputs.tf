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