# environments/qa/main.tf

locals {
  cluster_name = "${var.cluster_name}-${var.environment}"
  vpc_name     = "${var.cluster_name}-${var.environment}-${var.region}"
}

# VPC Module - Reuse existing VPC module
module "vpc" {
  source = "../../modules/vpc"

  environment = var.environment

  vpc_name = local.vpc_name
  vpc_cidr = var.vpc_cidr
  azs      = var.azs

  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets

  map_public_ip_on_launch = var.map_public_ip_on_launch

  # ECS specific tags
  cluster_name = local.cluster_name

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-Agents"
      "Platform"    = "AWS"
      "Terraform"   = "true"
    }
  )
}

# ECS Cluster Module
module "ecs" {
  source = "../../modules/ecs"

  cluster_name = var.cluster_name
  environment  = var.environment

  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnets
  alb_security_group_id  = module.alb.security_group_id
  alb_https_listener_arn = module.alb.https_listener_arn

  acm_certificate_arn    = ""
  create_alb_rules       = true

  enable_container_insights = var.enable_container_insights
  enable_execute_command    = var.enable_execute_command
  enable_service_discovery  = true
  create_alb               = true

  # Pass the entire services configuration from variables
  services = var.ecs_services

  tags = var.tags
}

# MongoDB Cluster Module
module "mongodb" {
  source = "../../modules/mongodb"

  cluster_name = "${local.cluster_name}-mongodb"
  environment  = var.environment

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.database_subnets  # Using database subnets for MongoDB

  # Instance configuration
  replica_count    = var.mongodb_replica_count
  instance_type    = var.mongodb_instance_type
  ami_id          = var.mongodb_ami_id
  key_name        = var.mongodb_key_name

  # MongoDB configuration
  mongodb_version         = var.mongodb_version
  mongodb_admin_username  = var.mongodb_admin_username
  mongodb_admin_password  = var.mongodb_admin_password
  mongodb_keyfile_content = var.mongodb_keyfile_content
  default_database        = var.mongodb_default_database

  # Storage configuration
  root_volume_size       = var.mongodb_root_volume_size
  data_volume_size       = var.mongodb_data_volume_size
  data_volume_type       = var.mongodb_data_volume_type
  data_volume_iops       = var.mongodb_data_volume_iops
  data_volume_throughput = var.mongodb_data_volume_throughput

  # Security configuration
  create_security_group = true
  allowed_cidr_blocks  = [module.vpc.vpc_cidr_block]
  additional_security_group_ids = []
  allow_ssh            = var.mongodb_allow_ssh
  ssh_cidr_blocks      = var.mongodb_ssh_cidr_blocks

  # Monitoring and logging
  enable_monitoring  = var.mongodb_enable_monitoring
  log_retention_days = var.mongodb_log_retention_days

  # DNS configuration
  create_dns_records = var.mongodb_create_dns_records
  private_domain     = var.mongodb_private_domain

  # Backup configuration
  backup_enabled        = var.mongodb_backup_enabled
  backup_schedule       = var.mongodb_backup_schedule
  backup_retention_days = var.mongodb_backup_retention_days

  # Additional features
  store_connection_string_in_ssm = var.mongodb_store_connection_string_in_ssm
  enable_encryption_at_rest      = var.mongodb_enable_encryption_at_rest
  enable_audit_logging          = var.mongodb_enable_audit_logging

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-Agents"
      "Component"   = "MongoDB"
      "Platform"    = "AWS"
      "Terraform"   = "true"
    }
  )

  depends_on = [module.vpc]
}