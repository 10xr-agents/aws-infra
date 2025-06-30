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

# Voice Agent Service
module "voice_agent" {
  source = "../../modules/conversation-agent-ecs"

  cluster_name = local.cluster_name
  cluster_id   = module.ecs.cluster_id
  environment  = var.environment

  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnets
  alb_security_group_id     = module.alb.alb_security_group_id
  ecs_security_group_id     = module.ecs.ecs_security_group_id
  task_execution_role_arn   = module.ecs.task_execution_role_arn
  task_role_arn            = module.storage.task_role_arn

  # Container Configuration (matching nonprod EKS deployment)
  ecr_repository_url = var.voice_agent_ecr_repository_url
  image_tag         = var.voice_agent_image_tag
  container_port    = var.voice_agent_port
  task_cpu         = var.voice_agent_cpu
  task_memory      = var.voice_agent_memory
  enable_fargate   = var.enable_fargate

  # Service Configuration
  desired_count = var.voice_agent_desired_count

  # Application Configuration (matching EKS variables)
  log_level               = var.voice_agent_log_level
  agent_collection_name   = var.voice_agent_agent_collection_name
  frames_collection_name  = var.voice_agent_frames_collection_name
  database_name          = var.voice_agent_database_name
  mongodb_uri            = var.voice_agent_mongodb_uri

  # LiveKit Configuration
  livekit_service_name         = var.voice_agent_livekit_service
  service_discovery_namespace  = aws_service_discovery_private_dns_namespace.main.name
  livekit_api_key             = var.voice_agent_livekit_api_key
  livekit_api_secret          = var.voice_agent_livekit_api_secret

  # Secrets Configuration (use these in production)
  anthropic_api_key_secret_arn    = var.voice_agent_anthropic_api_key_secret_arn
  deepgram_api_key_secret_arn     = var.voice_agent_deepgram_api_key_secret_arn
  cartesia_api_key_secret_arn     = var.voice_agent_cartesia_api_key_secret_arn
  livekit_api_key_secret_arn      = var.voice_agent_livekit_api_key_secret_arn
  livekit_api_secret_secret_arn   = var.voice_agent_livekit_api_secret_secret_arn

  # Additional Environment Variables
  additional_environment_variables = var.voice_agent_additional_environment_variables

  # Health Check Configuration
  enable_health_check              = var.voice_agent_enable_health_check
  health_check_command            = var.voice_agent_health_check_command
  health_check_path               = var.voice_agent_health_check_path
  health_check_interval           = var.voice_agent_health_check_interval
  health_check_timeout            = var.voice_agent_health_check_timeout
  health_check_start_period       = var.voice_agent_health_check_start_period

  # Auto Scaling Configuration
  enable_auto_scaling        = var.voice_agent_enable_auto_scaling
  auto_scaling_min_capacity  = var.voice_agent_min_capacity
  auto_scaling_max_capacity  = var.voice_agent_max_capacity
  auto_scaling_cpu_target    = var.voice_agent_cpu_target
  auto_scaling_memory_target = var.voice_agent_memory_target

  # Service Discovery
  enable_service_discovery      = var.voice_agent_enable_service_discovery
  service_discovery_namespace_id = aws_service_discovery_private_dns_namespace.main.id

  # EFS Storage (if needed)
  enable_efs           = var.voice_agent_enable_efs
  efs_file_system_id   = module.storage.efs_id
  efs_access_point_id  = module.storage.livekit_access_point_id
  efs_mount_path      = var.voice_agent_efs_mount_path

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

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "LiveKit"
      "Platform"    = "ECS"
      "Component"   = "VoiceAgent"
      "Terraform"   = "true"
    }
  )

  depends_on = [module.ecs, module.alb, module.storage]
}

# ALB Listener Rule for Voice Agent
resource "aws_lb_listener_rule" "voice_agent" {
  listener_arn = module.alb.http_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = module.voice_agent.target_group_arn
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

# HTTPS Listener Rule for Voice Agent (if certificate is provided)
resource "aws_lb_listener_rule" "voice_agent_https" {
  count = var.acm_certificate_arn != "" ? 1 : 0

  listener_arn = module.alb.https_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = module.voice_agent.target_group_arn
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