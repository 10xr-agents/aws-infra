# environments/nonprod/main.tf

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

# Network Load Balancer Module (for services requiring NLB)
module "nlb" {
  source = "../../modules/nlb"

  cluster_name = local.cluster_name
  environment  = var.environment

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnets

  # NLB Configuration
  enable_deletion_protection       = var.nlb_enable_deletion_protection
  enable_cross_zone_load_balancing = var.nlb_enable_cross_zone_load_balancing

  # Create NLB for TURN/WebRTC traffic
  create_turn_nlb = var.create_turn_nlb
  turn_ports = {
    udp = {
      port     = 3478
      protocol = "UDP"
    }
    tcp = {
      port     = 3480
      protocol = "TCP"
    }
  }

  # Create NLB for SIP traffic
  create_sip_nlb = var.create_sip_nlb
  sip_ports = {
    signaling = {
      port     = 5060
      protocol = "UDP"
    }
    rtp_start = {
      port     = 10000
      protocol = "UDP"
    }
    rtp_end = {
      port     = 20000
      protocol = "UDP"
    }
  }

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "LiveKit"
      "Platform"    = "ECS"
      "Component"   = "NLB"
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