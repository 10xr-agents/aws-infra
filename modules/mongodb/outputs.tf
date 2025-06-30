# modules/mongodb/outputs.tf

output "instance_ids" {
  description = "IDs of the MongoDB EC2 instances"
  value       = aws_instance.mongodb[*].id
}

output "instance_private_ips" {
  description = "Private IP addresses of the MongoDB instances"
  value       = aws_instance.mongodb[*].private_ip
}

output "instance_private_dns" {
  description = "Private DNS names of the MongoDB instances"
  value       = aws_instance.mongodb[*].private_dns
}

output "endpoints" {
  description = "List of MongoDB endpoints (ip:port)"
  value       = formatlist("%s:27017", aws_instance.mongodb[*].private_ip)
}

output "replica_set_name" {
  description = "Name of the MongoDB replica set"
  value       = local.replica_set_name
}

output "connection_string" {
  description = "MongoDB connection string"
  value       = local.connection_string
  sensitive   = true
}

output "srv_connection_string" {
  description = "MongoDB SRV connection string (if DNS is enabled)"
  value       = local.srv_connection_string
  sensitive   = true
}

output "security_group_id" {
  description = "ID of the MongoDB security group"
  value       = var.create_security_group ? aws_security_group.mongodb[0].id : null
}

output "data_volume_ids" {
  description = "IDs of the MongoDB data EBS volumes"
  value       = aws_ebs_volume.mongodb_data[*].id
}

output "primary_endpoint" {
  description = "Primary MongoDB endpoint (first instance)"
  value       = "${aws_instance.mongodb[0].private_ip}:27017"
}

output "ssm_parameter_name" {
  description = "Name of the SSM parameter containing the connection string"
  value       = var.store_connection_string_in_ssm ? aws_ssm_parameter.mongodb_connection_string[0].name : null
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group for MongoDB logs"
  value       = var.enable_monitoring ? aws_cloudwatch_log_group.mongodb[0].name : null
}

output "dns_zone_id" {
  description = "ID of the Route53 private hosted zone"
  value       = var.create_dns_records ? aws_route53_zone.mongodb[0].zone_id : null
}

output "dns_records" {
  description = "Map of DNS records for MongoDB nodes"
  value = var.create_dns_records ? {
    for idx, record in aws_route53_record.mongodb_nodes :
    "mongo-${idx}" => record.fqdn
  } : {}
}

output "iam_role_arn" {
  description = "ARN of the IAM role for MongoDB instances"
  value       = aws_iam_role.mongodb.arn
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.mongodb.name
}

output "admin_username" {
  description = "MongoDB admin username"
  value       = var.mongodb_admin_username
  sensitive   = true
}

output "cluster_details" {
  description = "Detailed information about the MongoDB cluster"
  value = {
    cluster_name     = var.cluster_name
    replica_set_name = local.replica_set_name
    replica_count    = var.replica_count
    mongodb_version  = var.mongodb_version
    instance_type    = var.instance_type
    data_volume_size = var.data_volume_size
    vpc_id          = var.vpc_id
    subnet_ids      = var.subnet_ids
  }
}