# environments/qa/terraform.tfvars

# AWS Region
region = "us-east-1"
environment = "qa"

# Cluster Configuration
cluster_name = "ten-xr-livekit"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]

private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

enable_nat_gateway     = true
single_nat_gateway     = false
one_nat_gateway_per_az = true
map_public_ip_on_launch = true

# ECS Configuration
enable_container_insights = true
enable_fargate           = true
enable_fargate_spot      = true

ecs_services = local.ecs_services_with_overrides

# MongoDB Configuration
mongodb_replica_count    = 3
mongodb_instance_type    = "t3.large"
mongodb_key_name         = "ten-xr-qa-keypair"  # Replace with your actual key pair name

mongodb_version          = "7.0"
mongodb_admin_username   = "admin"
mongodb_admin_password   = "TenXR-MongoDB-QA-2024!"  # Please change this to a secure password
mongodb_keyfile_content  = ""  # Generate a secure keyfile content for replica set authentication

mongodb_default_database = "ten_xr_livekit_qa"

# Storage Configuration
mongodb_root_volume_size       = 30
mongodb_data_volume_size       = 200
mongodb_data_volume_type       = "gp3"
mongodb_data_volume_iops       = 3000
mongodb_data_volume_throughput = 125

# Security Configuration
mongodb_allow_ssh       = true
mongodb_ssh_cidr_blocks = ["10.0.0.0/16"]  # Allow SSH from within VPC

# Monitoring and Logging
mongodb_enable_monitoring  = true
mongodb_log_retention_days = 7

# DNS Configuration
mongodb_create_dns_records = true
mongodb_private_domain     = "mongodb.qa.10xr.local"

# Backup Configuration
mongodb_backup_enabled        = true
mongodb_backup_schedule       = "cron(0 2 * * ? *)"  # Daily at 2 AM
mongodb_backup_retention_days = 7

# Additional Features
mongodb_store_connection_string_in_ssm = true
mongodb_enable_encryption_at_rest      = true
mongodb_enable_audit_logging          = false

# Tags
tags = {
  Environment = "qa"
  Project     = "LiveKit"
  Platform    = "ECS"
  Terraform   = "true"
}