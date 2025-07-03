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
      target_group_name    = "${name}-tg"
    }
  )}

  # Generate container definitions for each service directly in Terraform
  container_definitions = { for name, config in local.services_config : name =>
    jsonencode([
      {
        name  = name
        image = "${config.image}:${lookup(config, "image_tag", "latest")}"

        # Resource allocation
        cpu    = config.cpu
        memory = config.memory

        # Essential container
        essential = true

        # Port mappings
        portMappings = [
          {
            containerPort = config.port
            protocol      = "tcp"
          }
        ]

        # Environment variables
        environment = concat(
          [
            {
              name  = "ENVIRONMENT"
              value = var.environment
            },
            {
              name  = "AWS_REGION"
              value = data.aws_region.current.name
            },
            {
              name  = "SERVICE_NAME"
              value = name
            }
          ],
          [
            for key, value in lookup(config, "environment", {}) : {
            name  = key
            value = tostring(value)
          }
          ]
        )

        # Secrets from AWS Secrets Manager or SSM Parameter Store
        secrets = [
          for secret in lookup(config, "secrets", []) : {
            name      = secret.name
            valueFrom = secret.value_from
          }
        ]

        # Logging configuration
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = config.log_group_name
            "awslogs-region"        = data.aws_region.current.name
            "awslogs-stream-prefix" = "ecs"
          }
        }

        # Health check configuration - FIXED
        healthCheck = lookup(config, "container_health_check", null) != null ? {
          command = [
            "CMD-SHELL",
            lookup(config.container_health_check, "command", "curl -f http://localhost:${config.port}/health || exit 1")
          ]
          interval    = lookup(config.container_health_check, "interval", 30)
          timeout     = lookup(config.container_health_check, "timeout", 5)
          retries     = lookup(config.container_health_check, "retries", 3)
          startPeriod = lookup(config.container_health_check, "start_period", 0)
        } : null

        # Mount points for EFS (if enabled)
        mountPoints = lookup(config, "efs_config", null) != null && config.efs_config.enabled ? [
          {
            sourceVolume  = "efs-storage"
            containerPath = lookup(config.efs_config, "container_path", "/mnt/efs")
            readOnly      = lookup(config.efs_config, "read_only", false)
          }
        ] : []

        # Volume from (if needed)
        volumesFrom = []

        # Working directory
        workingDirectory = lookup(config, "working_directory", null)

        # Entry point and command
        entryPoint = lookup(config, "entry_point", null)
        command    = lookup(config, "command", null)

        # User
        user = lookup(config, "user", null)

        # Hostname
        hostname = lookup(config, "hostname", null)

        # Domain name servers
        dnsServers = lookup(config, "dns_servers", null)

        # DNS search domains
        dnsSearchDomains = lookup(config, "dns_search_domains", null)

        # Extra hosts
        extraHosts = lookup(config, "extra_hosts", null)

        # Docker security options
        dockerSecurityOptions = lookup(config, "docker_security_options", null)

        # Interactive and pseudo-TTY
        interactive = lookup(config, "interactive", false)
        pseudoTerminal = lookup(config, "pseudo_terminal", false)

        # Docker labels
        dockerLabels = merge(
          {
            "service"     = name
            "environment" = var.environment
            "cluster"     = local.name_prefix
          },
          lookup(config, "docker_labels", {})
        )

        # Ulimits
        ulimits = lookup(config, "ulimits", null) != null ? [
          for ulimit in config.ulimits : {
            name      = ulimit.name
            softLimit = ulimit.soft_limit
            hardLimit = ulimit.hard_limit
          }
        ] : null

        # Repository credentials
        repositoryCredentials = lookup(config, "repository_credentials", null) != null ? {
          credentialsParameter = config.repository_credentials.credentials_parameter
        } : null

        # System controls
        systemControls = lookup(config, "system_controls", null) != null ? [
          for control in config.system_controls : {
            namespace = control.namespace
            value     = control.value
          }
        ] : null

        # Resource requirements
        resourceRequirements = lookup(config, "resource_requirements", null) != null ? [
          for requirement in config.resource_requirements : {
            type  = requirement.type
            value = requirement.value
          }
        ] : null

        # FireLens configuration for log routing
        firelensConfiguration = lookup(config, "firelens_configuration", null) != null ? {
          type    = config.firelens_configuration.type
          options = lookup(config.firelens_configuration, "options", {})
        } : null

        # Dependencies on other containers
        dependsOn = lookup(config, "depends_on", null) != null ? [
          for dependency in config.depends_on : {
            containerName = dependency.container_name
            condition     = dependency.condition
          }
        ] : null

        # Start timeout
        startTimeout = lookup(config, "start_timeout", null)

        # Stop timeout
        stopTimeout = lookup(config, "stop_timeout", null)

        # Linux parameters
        linuxParameters = lookup(config, "linux_parameters", null) != null ? {
          capabilities = lookup(config.linux_parameters, "capabilities", null) != null ? {
            add  = lookup(config.linux_parameters.capabilities, "add", null)
            drop = lookup(config.linux_parameters.capabilities, "drop", null)
          } : null
          devices = lookup(config.linux_parameters, "devices", null) != null ? [
            for device in config.linux_parameters.devices : {
              hostPath      = device.host_path
              containerPath = device.container_path
              permissions   = lookup(device, "permissions", null)
            }
          ] : null
          initProcessEnabled = lookup(config.linux_parameters, "init_process_enabled", null)
          maxSwap           = lookup(config.linux_parameters, "max_swap", null)
          sharedMemorySize  = lookup(config.linux_parameters, "shared_memory_size", null)
          swappiness        = lookup(config.linux_parameters, "swappiness", null)
          tmpfs = lookup(config.linux_parameters, "tmpfs", null) != null ? [
            for tmpf in config.linux_parameters.tmpfs : {
              containerPath = tmpf.container_path
              size          = tmpf.size
              mountOptions  = lookup(tmpf, "mount_options", null)
            }
          ] : null
        } : null
      }
    ])
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

  # Ingress for service-to-service communication within VPC
  ingress {
    description = "Service to service communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # Ingress from other ECS services (for service discovery)
  dynamic "ingress" {
    for_each = var.enable_service_discovery ? [1] : []
    content {
      description = "Service discovery communication"
      from_port   = each.value.port
      to_port     = each.value.port
      protocol    = "tcp"
      self        = true
    }
  }

  # Egress to internet
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress to Redis (if Redis security group is provided)
  dynamic "egress" {
    for_each = var.redis_security_group_id != "" ? [1] : []
    content {
      description     = "To Redis cluster"
      from_port       = 6379
      to_port         = 6379
      protocol        = "tcp"
      security_groups = [var.redis_security_group_id]
    }
  }

  # Egress to MongoDB (if MongoDB security group is provided)
  dynamic "egress" {
    for_each = var.mongodb_security_group_id != "" ? [1] : []
    content {
      description     = "To MongoDB cluster"
      from_port       = 27017
      to_port         = 27017
      protocol        = "tcp"
      security_groups = [var.mongodb_security_group_id]
    }
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
# ALB Target Groups - ONLY CREATE IF ALB IS ENABLED
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

  # CRITICAL: Wait for ALB to be created before creating target groups
  depends_on = [
    aws_lb.main
  ]
}

################################################################################
# ECS Services - UPDATED WITH PROPER DEPENDENCIES
################################################################################

resource "aws_ecs_service" "service" {
  for_each = local.services_config

  name            = each.key
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  desired_count   = each.value.desired_count

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

  # Load balancer configuration - FIXED DEPENDENCY
  dynamic "load_balancer" {
    for_each = lookup(each.value, "enable_load_balancer", true) && var.create_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.service[each.key].arn
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

  # Deployment configuration
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  # Force new deployment on task definition changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_ecs_task_definition.service[each.key].revision,
      aws_ecs_task_definition.service[each.key].container_definitions,
    ]))
  }

  # CRITICAL: Proper dependencies
  depends_on = [
    aws_ecs_cluster_capacity_providers.main,
    aws_lb_target_group.service,
    aws_lb_listener.http,
    aws_lb_listener.https
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