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

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  map_public_ip_on_launch = var.map_public_ip_on_launch

  # ECS specific tags
  cluster_name = local.cluster_name

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "LiveKit"
      "Platform"    = "ECS"
      "Terraform"   = "true"
    }
  )
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
      "Project"     = "LiveKit"
      "Component"   = "MongoDB"
      "Platform"    = "ECS"
      "Terraform"   = "true"
    }
  )

  depends_on = [module.vpc]
}

# ECS Cluster Module
module "ecs" {
  source = "../../modules/ecs"

  cluster_name    = local.cluster_name
  environment     = var.environment

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  public_subnet_ids  = module.vpc.public_subnets

  # Container Insights
  enable_container_insights = var.enable_container_insights

  # Capacity Providers
  enable_fargate           = var.enable_fargate
  enable_fargate_spot      = var.enable_fargate_spot
  enable_ec2               = var.enable_ec2

  # EC2 Capacity Provider settings (if enabled)
  ec2_asg_min_size         = var.ec2_asg_min_size
  ec2_asg_max_size         = var.ec2_asg_max_size
  ec2_asg_desired_capacity = var.ec2_asg_desired_capacity
  ec2_instance_types       = var.ec2_instance_types
  ec2_ami_id              = var.ec2_ami_id

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "LiveKit"
      "Platform"    = "ECS"
      "Terraform"   = "true"
    }
  )

  depends_on = [module.vpc]
}

# Application Load Balancer Module
module "alb" {
  source = "../../modules/alb"

  cluster_name = local.cluster_name
  environment  = var.environment

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnets

  # ALB Configuration
  enable_deletion_protection = var.alb_enable_deletion_protection
  enable_http2              = var.alb_enable_http2
  idle_timeout              = var.alb_idle_timeout

  # Security
  create_security_group = true
  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from anywhere"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from anywhere"
    }
  ]

  # Target Group defaults
  target_group_defaults = {
    port                          = 80
    protocol                      = "HTTP"
    target_type                   = var.enable_fargate ? "ip" : "instance"
    deregistration_delay          = 30
    health_check_enabled          = true
    health_check_interval         = 30
    health_check_path             = "/health"
    health_check_timeout          = 5
    health_check_healthy_threshold   = 2
    health_check_unhealthy_threshold = 3
    health_check_matcher          = "200"
  }

  # Certificate (optional)
  certificate_arn = var.acm_certificate_arn

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "LiveKit"
      "Platform"    = "ECS"
      "Component"   = "ALB"
      "Terraform"   = "true"
    }
  )

  depends_on = [module.vpc]
}

# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${local.cluster_name}.local"
  description = "Service discovery namespace for ${local.cluster_name}"
  vpc         = module.vpc.vpc_id

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "LiveKit"
      "Platform"    = "ECS"
      "Component"   = "ServiceDiscovery"
      "Terraform"   = "true"
    }
  )
}

# Storage Module (EFS for shared storage)
module "storage" {
  source = "../../modules/storage-ecs"

  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnets
  cluster_name          = local.cluster_name
  environment           = var.environment

  # EFS configuration
  efs_performance_mode  = var.efs_performance_mode
  efs_throughput_mode   = var.efs_throughput_mode
  efs_provisioned_throughput = var.efs_provisioned_throughput

  # S3 configuration for recordings
  create_recordings_bucket   = var.create_recordings_bucket
  recordings_bucket_name     = "${var.cluster_name}-livekit-recordings"
  recordings_expiration_days = var.recordings_expiration_days

  # Security
  ecs_security_group_id = module.ecs.ecs_security_group_id

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "LiveKit"
      "Platform"    = "ECS"
      "Terraform"   = "true"
    }
  )

  depends_on = [module.ecs]
}

# Services Module (Voice Agent + LiveKit Proxy)
module "services" {
  source = "../../modules/services"

  cluster_name = local.cluster_name
  cluster_id   = module.ecs.cluster_id
  environment  = var.environment

  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnets
  alb_security_group_id     = module.alb.alb_security_group_id
  ecs_security_group_id     = module.ecs.ecs_security_group_id
  task_execution_role_arn   = module.ecs.task_execution_role_arn
  task_role_arn            = module.storage.task_role_arn

  enable_fargate = var.enable_fargate
  enable_execute_command = var.enable_execute_command

  # Service Discovery
  service_discovery_namespace    = aws_service_discovery_private_dns_namespace.main.name
  service_discovery_namespace_id = aws_service_discovery_private_dns_namespace.main.id
  livekit_service_name          = var.voice_agent_livekit_service

  # EFS Storage
  efs_file_system_id = module.storage.efs_id

  # Capacity Provider Strategy
  capacity_provider_strategy = var.enable_fargate_spot ? [
    {
      capacity_provider = "FARGATE_SPOT"
      weight           = 1
      base             = 0
    },
    {
      capacity_provider = "FARGATE"
      weight           = 1
      base             = 1
    }
  ] : [
    {
      capacity_provider = "FARGATE"
      weight           = 1
      base             = 1
    }
  ]

  # Voice Agent Configuration
  voice_agent_ecr_repository_url = var.voice_agent_ecr_repository_url
  voice_agent_image_tag          = var.voice_agent_image_tag
  voice_agent_port               = var.voice_agent_port
  voice_agent_cpu                = var.voice_agent_cpu
  voice_agent_memory             = var.voice_agent_memory
  voice_agent_desired_count      = var.voice_agent_desired_count

  # Voice Agent Application Configuration
  voice_agent_log_level               = var.voice_agent_log_level
  voice_agent_agent_collection_name   = var.voice_agent_agent_collection_name
  voice_agent_frames_collection_name  = var.voice_agent_frames_collection_name
  voice_agent_database_name          = var.voice_agent_database_name
  voice_agent_mongodb_uri            = var.voice_agent_mongodb_uri
  voice_agent_livekit_api_key        = var.voice_agent_livekit_api_key
  voice_agent_livekit_api_secret     = var.voice_agent_livekit_api_secret

  # Voice Agent Secrets Configuration
  voice_agent_anthropic_api_key_secret_arn    = var.voice_agent_anthropic_api_key_secret_arn
  voice_agent_deepgram_api_key_secret_arn     = var.voice_agent_deepgram_api_key_secret_arn
  voice_agent_cartesia_api_key_secret_arn     = var.voice_agent_cartesia_api_key_secret_arn
  voice_agent_livekit_api_key_secret_arn      = var.voice_agent_livekit_api_key_secret_arn
  voice_agent_livekit_api_secret_secret_arn   = var.voice_agent_livekit_api_secret_secret_arn

  # Voice Agent Additional Configuration
  voice_agent_additional_environment_variables = var.voice_agent_additional_environment_variables
  voice_agent_enable_health_check              = var.voice_agent_enable_health_check
  voice_agent_health_check_command            = var.voice_agent_health_check_command
  voice_agent_health_check_interval           = var.voice_agent_health_check_interval
  voice_agent_health_check_timeout            = var.voice_agent_health_check_timeout
  voice_agent_health_check_start_period       = var.voice_agent_health_check_start_period

  # Voice Agent Auto Scaling Configuration
  voice_agent_enable_auto_scaling        = var.voice_agent_enable_auto_scaling
  voice_agent_auto_scaling_min_capacity  = var.voice_agent_min_capacity
  voice_agent_auto_scaling_max_capacity  = var.voice_agent_max_capacity
  voice_agent_auto_scaling_cpu_target    = var.voice_agent_cpu_target
  voice_agent_auto_scaling_memory_target = var.voice_agent_memory_target

  # Voice Agent Service Discovery and EFS
  voice_agent_enable_service_discovery = var.voice_agent_enable_service_discovery
  voice_agent_enable_efs               = var.voice_agent_enable_efs
  voice_agent_efs_mount_path           = var.voice_agent_efs_mount_path

  # LiveKit Proxy Configuration
  livekit_proxy_ecr_repository_url = var.livekit_proxy_ecr_repository_url
  livekit_proxy_image_tag          = var.livekit_proxy_image_tag
  livekit_proxy_port               = var.livekit_proxy_port
  livekit_proxy_cpu                = var.livekit_proxy_cpu
  livekit_proxy_memory             = var.livekit_proxy_memory
  livekit_proxy_desired_count      = var.livekit_proxy_desired_count

  # LiveKit Proxy Application Configuration
  livekit_proxy_log_level            = var.livekit_proxy_log_level
  livekit_proxy_livekit_api_key      = var.livekit_proxy_livekit_api_key
  livekit_proxy_livekit_api_secret   = var.livekit_proxy_livekit_api_secret

  # LiveKit Proxy Secrets Configuration
  livekit_proxy_livekit_api_key_secret_arn      = var.livekit_proxy_livekit_api_key_secret_arn
  livekit_proxy_livekit_api_secret_secret_arn   = var.livekit_proxy_livekit_api_secret_secret_arn

  # LiveKit Proxy Additional Configuration
  livekit_proxy_additional_environment_variables = var.livekit_proxy_additional_environment_variables
  livekit_proxy_enable_health_check              = var.livekit_proxy_enable_health_check
  livekit_proxy_health_check_command            = var.livekit_proxy_health_check_command
  livekit_proxy_health_check_interval           = var.livekit_proxy_health_check_interval
  livekit_proxy_health_check_timeout            = var.livekit_proxy_health_check_timeout
  livekit_proxy_health_check_start_period       = var.livekit_proxy_health_check_start_period

  # LiveKit Proxy Auto Scaling Configuration
  livekit_proxy_enable_auto_scaling        = var.livekit_proxy_enable_auto_scaling
  livekit_proxy_auto_scaling_min_capacity  = var.livekit_proxy_min_capacity
  livekit_proxy_auto_scaling_max_capacity  = var.livekit_proxy_max_capacity
  livekit_proxy_auto_scaling_cpu_target    = var.livekit_proxy_cpu_target
  livekit_proxy_auto_scaling_memory_target = var.livekit_proxy_memory_target

  # LiveKit Proxy Service Discovery and EFS
  livekit_proxy_enable_service_discovery = var.livekit_proxy_enable_service_discovery
  livekit_proxy_enable_efs               = var.livekit_proxy_enable_efs
  livekit_proxy_efs_mount_path           = var.livekit_proxy_efs_mount_path

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "LiveKit"
      "Platform"    = "ECS"
      "Component"   = "Services"
      "Terraform"   = "true"
    }
  )

  depends_on = [module.ecs, module.alb, module.storage, module.mongodb]
}

# Data source to retrieve MongoDB connection string from SSM (if using self-hosted MongoDB)
data "aws_ssm_parameter" "mongodb_connection_string" {
  count = var.mongodb_store_connection_string_in_ssm ? 1 : 0
  name  = module.mongodb.ssm_parameter_name
}

# Security Group Rule to allow Conversation Agent to access MongoDB
resource "aws_security_group_rule" "conversation_agent_to_mongodb" {
  count = var.mongodb_replica_count > 0 ? 1 : 0

  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = module.conversation_agent.security_group_id
  security_group_id        = module.mongodb.security_group_id
  description              = "Allow Conversation Agent ECS tasks to access MongoDB"
}

# ALB Listener Rule for Voice Agent
resource "aws_lb_listener_rule" "voice_agent" {
  listener_arn = module.alb.http_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = module.services.voice_agent_target_group_arn
  }

  condition {
    path_pattern {
      values = ["/voice/*"]
    }
  }

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Service"     = "voice-agent"
      "Terraform"   = "true"
    }
  )
}

# ALB Listener Rule for LiveKit Proxy
resource "aws_lb_listener_rule" "livekit_proxy" {
  listener_arn = module.alb.http_listener_arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = module.services.livekit_proxy_target_group_arn
  }

  condition {
    path_pattern {
      values = ["/proxy/*", "/livekit/*"]
    }
  }

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Service"     = "livekit-proxy"
      "Terraform"   = "true"
    }
  )
}

# HTTPS Listener Rule for Voice Agent (if certificate is provided)
resource "aws_lb_listener_rule" "voice_agent_https" {
  count = var.acm_certificate_arn != "" ? 1 : 0

  listener_arn = module.alb.https_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = module.services.voice_agent_target_group_arn
  }

  condition {
    path_pattern {
      values = ["/voice/*"]
    }
  }

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Service"     = "voice-agent"
      "Terraform"   = "true"
    }
  )
}

# HTTPS Listener Rule for LiveKit Proxy (if certificate is provided)
resource "aws_lb_listener_rule" "livekit_proxy_https" {
  count = var.acm_certificate_arn != "" ? 1 : 0

  listener_arn = module.alb.https_listener_arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = module.services.livekit_proxy_target_group_arn
  }

  condition {
    path_pattern {
      values = ["/proxy/*", "/livekit/*"]
    }
  }

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Service"     = "livekit-proxy"
      "Terraform"   = "true"
    }
  )
}