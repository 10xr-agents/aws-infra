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
      task_role_name       = "${local.name_prefix}-${name}-task-role"
      task_exec_role_name  = "${local.name_prefix}-${name}-exec-role"
      log_group_name       = "/ecs/${local.name_prefix}/${name}"
      security_group_name  = "${local.name_prefix}-${name}-sg"
      target_group_name    = "${local.name_prefix}-${name}-tg"
    }
  )}

  # Generate container definitions for each service from JSON files
  container_definitions = { for name, config in local.services_config : name =>
    templatefile("${path.module}/task-definitions/${name}.json", {
      service_name    = name
      image          = "${config.image}:${lookup(config, "image_tag", "latest")}"
      cpu            = config.cpu
      memory         = config.memory
      port           = config.port
      environment    = var.environment
      log_group      = config.log_group_name
      aws_region     = data.aws_region.current.name
      # Pass additional variables for templating
      environment_vars = lookup(config, "environment", {})
      secrets         = lookup(config, "secrets", [])
      health_check    = lookup(config, "container_health_check", null)
      efs_config      = lookup(config, "efs_config", null)
    })
  }
}

################################################################################
# Data Sources
################################################################################

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

################################################################################
# ECS Cluster
################################################################################

resource "aws_ecs_cluster" "main" {
  name = local.name_prefix

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.cluster.name
      }
    }
  }

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = local.common_tags
}

################################################################################
# CloudWatch Log Group for Cluster
################################################################################

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

################################################################################
# ECS Capacity Providers
################################################################################

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 50
    capacity_provider = "FARGATE"
  }

  default_capacity_provider_strategy {
    base              = 0
    weight            = 50
    capacity_provider = "FARGATE_SPOT"
  }

  depends_on = [aws_ecs_cluster.main]
}

################################################################################
# IAM Roles and Policies
################################################################################

# Task Execution Role (for pulling images, logs, etc.)
resource "aws_iam_role" "task_execution_role" {
  for_each = local.services_config

  name = each.value.task_exec_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, { Service = each.key })
}

# Attach basic execution policy
resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  for_each = local.services_config

  role       = aws_iam_role.task_execution_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional execution policies for Secrets Manager, SSM, etc.
resource "aws_iam_role_policy" "task_execution_secrets" {
  for_each = {
    for name, config in local.services_config : name => config
    if length(lookup(config, "secrets", [])) > 0
  }

  name = "${each.value.task_exec_role_name}-secrets"
  role = aws_iam_role.task_execution_role[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      }
    ]
  })
}

# Task Role (for application permissions)
resource "aws_iam_role" "task_role" {
  for_each = local.services_config

  name = each.value.task_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, { Service = each.key })
}

# Attach additional task policies if specified
resource "aws_iam_role_policy_attachment" "additional_task_policies" {
  for_each = merge([
    for service_name, config in local.services_config : {
      for policy_name, policy_arn in lookup(config, "additional_task_policies", {}) :
      "${service_name}-${policy_name}" => {
        role       = aws_iam_role.task_role[service_name].name
        policy_arn = policy_arn
      }
    }
  ]...)

  role       = each.value.role
  policy_arn = each.value.policy_arn
}

################################################################################
# Security Groups
################################################################################

resource "aws_security_group" "ecs_service" {
  for_each = local.services_config

  name        = each.value.security_group_name
  description = "Security group for ECS service ${each.key}"
  vpc_id      = var.vpc_id

  # Ingress from ALB (if ALB is enabled)
  dynamic "ingress" {
    for_each = (var.create_alb || var.alb_security_group_id != "") && lookup(each.value, "enable_load_balancer", true) ? [1] : []
    content {
      from_port       = each.value.port
      to_port         = each.value.port
      protocol        = "tcp"
      security_groups = var.create_alb ? [aws_security_group.alb[0].id] : [var.alb_security_group_id]
    }
  }

  # Egress to internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name    = each.value.security_group_name
    Service = each.key
  })
}

################################################################################
# CloudWatch Log Groups for Services
################################################################################

resource "aws_cloudwatch_log_group" "service_logs" {
  for_each = local.services_config

  name              = each.value.log_group_name
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, { Service = each.key })
}

################################################################################
# ECS Task Definitions
################################################################################

resource "aws_ecs_task_definition" "service" {
  for_each = local.services_config

  family                   = "${local.name_prefix}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.task_execution_role[each.key].arn
  task_role_arn           = aws_iam_role.task_role[each.key].arn

  container_definitions = local.container_definitions[each.key]

  # EFS Volume configuration (if enabled)
  dynamic "volume" {
    for_each = lookup(each.value, "efs_config", null) != null && each.value.efs_config.enabled ? [1] : []
    content {
      name = "efs-storage"
      efs_volume_configuration {
        file_system_id = var.efs_file_system_id
        root_directory = "/"
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = var.efs_access_point_id
          iam             = "ENABLED"
        }
      }
    }
  }

  tags = merge(local.common_tags, { Service = each.key })
}

################################################################################
# ALB Target Groups
################################################################################

resource "aws_lb_target_group" "service" {
  for_each = {
    for name, config in local.services_config : name => config
    if lookup(config, "enable_load_balancer", true) && var.create_alb
  }

  name        = each.value.target_group_name
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = lookup(each.value.health_check, "healthy_threshold", 2)
    interval            = lookup(each.value.health_check, "interval", 30)
    matcher             = lookup(each.value.health_check, "matcher", "200")
    path                = lookup(each.value.health_check, "path", "/health")
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = lookup(each.value.health_check, "timeout", 20)
    unhealthy_threshold = lookup(each.value.health_check, "unhealthy_threshold", 3)
  }

  deregistration_delay = lookup(each.value, "deregistration_delay", 30)

  tags = merge(local.common_tags, {
    Name    = each.value.target_group_name
    Service = each.key
  })
}

################################################################################
# ECS Services
################################################################################

resource "aws_ecs_service" "service" {
  for_each = local.services_config

  name            = each.key
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  # Enable ECS Exec if specified
  enable_execute_command = var.enable_execute_command

  # Network configuration
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_service[each.key].id]
    assign_public_ip = false
  }

  # Capacity provider strategy (override default if specified)
  dynamic "capacity_provider_strategy" {
    for_each = lookup(each.value, "capacity_provider_strategy", [])
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight           = capacity_provider_strategy.value.weight
      base             = capacity_provider_strategy.value.base
    }
  }

  # Load balancer configuration
  dynamic "load_balancer" {
    for_each = lookup(each.value, "enable_load_balancer", true) && (var.create_alb || var.target_group_arns != {}) ? [1] : []
    content {
      target_group_arn = var.target_group_arns != {} && lookup(var.target_group_arns, each.key, null) != null ? var.target_group_arns[each.key] : aws_lb_target_group.service[each.key].arn
      container_name   = each.key
      container_port   = each.value.port
    }
  }

  # Service discovery
  dynamic "service_registries" {
    for_each = var.enable_service_discovery && lookup(each.value, "enable_service_discovery", true) ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.services[each.key].arn
    }
  }

  # Add these top-level arguments:
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  # Force new deployment on task definition changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_ecs_task_definition.service[each.key].revision,
      aws_ecs_task_definition.service[each.key].container_definitions,
    ]))
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.main,
    aws_lb_target_group.service
  ]

  tags = merge(local.common_tags, { Service = each.key })
}

################################################################################
# Auto Scaling
################################################################################

resource "aws_appautoscaling_target" "ecs_target" {
  for_each = {
    for name, config in local.services_config : name => config
    if lookup(config, "enable_auto_scaling", true)
  }

  max_capacity       = lookup(each.value, "auto_scaling_max_capacity", 10)
  min_capacity       = lookup(each.value, "auto_scaling_min_capacity", 1)
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.service[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.service]

  tags = merge(local.common_tags, { Service = each.key })
}

# CPU-based auto scaling policy
resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  for_each = {
    for name, config in local.services_config : name => config
    if lookup(config, "enable_auto_scaling", true)
  }

  name               = "${local.name_prefix}-${each.key}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = lookup(each.value, "auto_scaling_cpu_target", 70)
  }
}

# Memory-based auto scaling policy
resource "aws_appautoscaling_policy" "ecs_memory_policy" {
  for_each = {
    for name, config in local.services_config : name => config
    if lookup(config, "enable_auto_scaling", true)
  }

  name               = "${local.name_prefix}-${each.key}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = lookup(each.value, "auto_scaling_memory_target", 80)
  }
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