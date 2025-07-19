# modules/mongodb/outputs.tf
# Add these new outputs to your existing outputs.tf file

#------------------------------------------------------------------------------
# VPC Peering Outputs
#------------------------------------------------------------------------------

output "vpc_peering_connection_id" {
  description = "ID of the VPC peering connection between AWS VPC and MongoDB Atlas"
  value       = mongodbatlas_network_peering.main.connection_id
}

output "network_container_id" {
  description = "MongoDB Atlas network container ID"
  value       = mongodbatlas_network_peering.main.container_id
}

output "atlas_cidr_block" {
  description = "CIDR block used by MongoDB Atlas"
  value       = var.atlas_cidr_block
}

output "vpc_peering_status" {
  description = "Status of the VPC peering connection"
  value       = mongodbatlas_network_peering.main.status_name
}

output "mongodb_security_group_id" {
  description = "Security group ID for MongoDB Atlas access"
  value       = var.create_security_group ? aws_security_group.mongodb_atlas_access.id : null
}