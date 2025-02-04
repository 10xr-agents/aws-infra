# environment/dev/main.tf

locals {
  name = "${var.project_name}-${var.environment}"

  tags = {
    Environment     = var.environment
    Project         = var.project_name
    ManagedBy       = "10xR"
    EnvironmentType = var.environment == "prod" ? "Production" : ( var.environment == "prod" ? "QA" : "Development")
    Terraform      = "true"
  }
}

module "aws" {
  source = "../../modules/aws"

  # Core configuration
  aws_region   = var.aws_region
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr

  # ECS configurations
  services                    = var.services
  capacity_provider_strategy  = var.capacity_provider_strategy
  instance_types             = var.instance_types
  ecs_cluster_settings       = var.ecs_cluster_settings
  enable_service_discovery   = var.enable_service_discovery
  service_discovery_namespace = var.service_discovery_namespace
  enable_ecs_exec            = var.enable_ecs_exec

  # Auto Scaling configurations
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity

  # EFS configurations
  efs_throughput_mode   = var.efs_throughput_mode
  efs_performance_mode  = var.efs_performance_mode

  alarm_actions = var.alarm_actions

  # Tags configuration
  tags = merge(local.tags, var.tags, var.vpc_tags)
  public_subnet_tags = merge(
    local.tags,
    var.public_subnet_tags,
    {
      Tier = "public"
      "kubernetes.io/role/elb" = "1"
    }
  )
  private_subnet_tags = merge(
    local.tags,
    var.private_subnet_tags,
    {
      Tier = "private"
      "kubernetes.io/role/internal-elb" = "1"
    }
  )
}