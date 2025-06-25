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
enable_ec2               = false

# EC2 Capacity Provider Configuration (if enabled)
ec2_asg_min_size         = 0
ec2_asg_max_size         = 10
ec2_asg_desired_capacity = 2
ec2_instance_types       = ["m5.large", "m5.xlarge", "m5a.large", "m5a.xlarge"]

# ALB Configuration
alb_enable_deletion_protection = false
alb_enable_http2              = true
alb_idle_timeout              = 60
# acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Storage Configuration
efs_performance_mode       = "generalPurpose"
efs_throughput_mode        = "bursting"
create_recordings_bucket   = true
recordings_expiration_days = 30

# Tags
tags = {
  Environment = "qa"
  Project     = "LiveKit"
  Platform    = "ECS"
  Terraform   = "true"
}