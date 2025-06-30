# modules/ecs/main.tf

locals {
  # Environment-specific naming
  name_prefix = "${var.cluster_name}-${var.environment}"

  # Common tags
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )

  # Process services configuration
  services_config = { for name, config in var.services : name => merge(
    config,
    {
      # Add computed values
      task_role_name      = "${local.name_prefix}-${name}-task"
      task_exec_role_name = "${local.name_prefix}-${name}-exec"
      log_group_name      = "/ecs/${local.name_prefix}/${name}"
    }
  )}
}

################################################################################
# ECS Cluster with Fargate Capacity Providers
################################################################################
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.11.0"

  cluster_name = local.name_prefix

  # Cluster configuration
  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/${local.name_prefix}"
      }
    }
  }

  # Container Insights
  cluster_settings = [
    {
      name  = "containerInsights"
      value = var.enable_container_insights ? "enabled" : "disabled"
    }
  ]

  # Fargate Capacity Providers
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 1
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 0
      }
    }
  }

  # Dynamic Services Configuration
  services = { for name, config in local.services_config : name => {
    # Service configuration
    desired_count          = config.desired_count
    enable_execute_command = var.enable_execute_command
    launch_type           = "FARGATE"

    # Network configuration
    subnet_ids = var.private_subnet_ids
    security_group_rules = merge(
      {
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      },
        var.alb_security_group_id != "" ? {
        ingress_alb = {
          type                     = "ingress"
          from_port               = config.port
          to_port                 = config.port
          protocol                = "tcp"
          source_security_group_id = var.alb_security_group_id
        }
      } : {}
    )

    # Task definition
    create_task_definition = true
    cpu                   = config.cpu
    memory                = config.memory

    # Container definition from JSON
    container_definitions = local.container_definitions[name]

    # IAM Roles
    create_iam_role      = true
    task_role_name       = config.task_role_name
    task_exec_role_name  = config.task_exec_role_name
    task_exec_iam_role_policies = merge(
      {
        AmazonECSTaskExecutionRolePolicy = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
      },
      lookup(config, "additional_task_policies", {})
    )

    # Capacity provider strategy
    capacity_provider_strategy = config.capacity_provider_strategy

    # Service discovery
    service_registries = var.enable_service_discovery && lookup(config, "enable_service_discovery", true) ? {
      registry_arn = aws_service_discovery_service.services[name].arn
    } : {}

    # Load balancer - use external target groups if provided
    load_balancer = var.target_group_arns != null && lookup(var.target_group_arns, name, null) != null ? {
      service = {
        target_group_arn = var.target_group_arns[name]
        container_name   = name
        container_port   = config.port
      }
    } : {}

    # Auto scaling
    enable_autoscaling       = lookup(config, "enable_auto_scaling", true)
    autoscaling_min_capacity = lookup(config, "auto_scaling_min_capacity", 1)
    autoscaling_max_capacity = lookup(config, "auto_scaling_max_capacity", 10)

    autoscaling_policies = lookup(config, "enable_auto_scaling", true) ? {
      cpu = {
        policy_type = "TargetTrackingScaling"
        target_tracking_scaling_policy_configuration = {
          predefined_metric_specification = {
            predefined_metric_type = "ECSServiceAverageCPUUtilization"
          }
          target_value = lookup(config, "auto_scaling_cpu_target", 70)
        }
      }
      memory = {
        policy_type = "TargetTrackingScaling"
        target_tracking_scaling_policy_configuration = {
          predefined_metric_specification = {
            predefined_metric_type = "ECSServiceAverageMemoryUtilization"
          }
          target_value = lookup(config, "auto_scaling_memory_target", 80)
        }
      }
    } : {}

    tags = merge(local.common_tags, { Service = name })
  }}

  tags = local.common_tags
}

################################################################################
# Service Discovery
################################################################################

resource "aws_service_discovery_private_dns_namespace" "main" {
  count = var.enable_service_discovery ? 1 : 0

  name        = "${local.name_prefix}.local"
  description = "Service discovery namespace for ${local.name_prefix}"
  vpc         = var.vpc_id

  tags = local.common_tags
}

resource "aws_service_discovery_service" "services" {
  for_each = var.enable_service_discovery ? {
    for name, config in local.services_config : name => config
    if lookup(config, "enable_service_discovery", true)
  } : {}

  name = each.key

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = merge(local.common_tags, { Service = each.key })
}

################################################################################
# Data Sources
################################################################################

data "aws_region" "current" {}