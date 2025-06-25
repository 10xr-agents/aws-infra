# modules/conversation-agent-ecs/main.tf

/**
 * # Conversation Agent Service Module for ECS
 *
 * This module creates an ECS service for the conversation agent with:
 * - ECS Task Definition with conversation agent container
 * - ECS Service with auto-scaling capabilities
 * - Target Group for load balancer integration
 * - Service Discovery for internal communication
 * - CloudWatch logs for monitoring
 * - Configuration matching the EKS deployment
 */

# CloudWatch Log Group for the service
resource "aws_cloudwatch_log_group" "conversation_agent" {
  name              = "/ecs/${var.cluster_name}/conversation-agent"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-conversation-agent-logs"
    }
  )
}

# Task Definition for Conversation Agent
resource "aws_ecs_task_definition" "conversation_agent" {
  family                   = "${var.cluster_name}-conversation-agent"
  network_mode             = "awsvpc"
  requires_compatibilities = var.enable_fargate ? ["FARGATE"] : ["EC2"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn           = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "conversation-agent"
      image = "${var.ecr_repository_url}:${var.image_tag}"
      
      essential = true
      
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = concat([
        {
          name  = "LOG_LEVEL"
          value = var.log_level
        },
        {
          name  = "AGENT_COLLECTION_NAME"
          value = var.agent_collection_name
        },
        {
          name  = "FRAMES_COLLECTION_NAME"
          value = var.frames_collection_name
        },
        {
          name  = "DATABASE_NAME"
          value = var.database_name
        },
        {
          name  = "LIVEKIT_HOST"
          value = "ws://${var.livekit_service_name}.${var.service_discovery_namespace}:7880"
        },
        {
          name  = "LIVEKIT_URL"
          value = "http://${var.livekit_service_name}.${var.service_discovery_namespace}:7880"
        },
        {
          name  = "MONGO_DB_URL"
          value = var.mongodb_uri
        },
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "ECS_ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "LIVEKIT_AGENT_API_KEY"
          value = var.livekit_api_key
        },
        {
          name  = "LIVEKIT_AGENT_API_SECRET"
          value = var.livekit_api_secret
        },
        {
          name  = "LK_API_KEY"
          value = var.livekit_api_key
        },
        {
          name  = "LK_API_SECRET"
          value = var.livekit_api_secret
        },
        {
          name  = "devkey"
          value = var.livekit_api_key
        },
        {
          name  = "devsecret"
          value = var.livekit_api_secret
        }
      ], [
        # Additional environment variables from the original configuration
        for key, value in var.additional_environment_variables : {
          name  = key
          value = tostring(value)
        }
      ])

      secrets = [
        {
          name      = "ANTHROPIC_API_KEY"
          valueFrom = var.anthropic_api_key_secret_arn
        },
        {
          name      = "DEEPGRAM_API_KEY"
          valueFrom = var.deepgram_api_key_secret_arn
        },
        {
          name      = "CARTESIA_API_KEY"
          valueFrom = var.cartesia_api_key_secret_arn
        },
        {
          name      = "LIVEKIT_API_KEY"
          valueFrom = var.livekit_api_key_secret_arn
        },
        {
          name      = "LIVEKIT_API_SECRET"
          valueFrom = var.livekit_api_secret_secret_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.conversation_agent.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = var.enable_health_check ? {
        command = [
          "CMD-SHELL",
          var.health_check_command
        ]
        interval    = var.health_check_interval
        timeout     = var.health_check_timeout
        retries     = var.health_check_retries
        startPeriod = var.health_check_start_period
      } : null

      # Mount EFS if enabled
      mountPoints = var.enable_efs ? [
        {
          sourceVolume  = "efs-storage"
          containerPath = var.efs_mount_path
          readOnly      = false
        }
      ] : []
    }
  ])

  # EFS volume configuration
  dynamic "volume" {
    for_each = var.enable_efs ? [1] : []
    content {
      name = "efs-storage"

      efs_volume_configuration {
        file_system_id     = var.efs_file_system_id
        transit_encryption = "ENABLED"
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-conversation-agent-task"
    }
  )
}

# Target Group for ALB
resource "aws_lb_target_group" "conversation_agent" {
  name        = format("%.32s", "${var.cluster_name}-conv-agent-tg")
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = var.enable_fargate ? "ip" : "instance"

  health_check {
    enabled             = true
    healthy_threshold   = var.target_group_health_check_healthy_threshold
    unhealthy_threshold = var.target_group_health_check_unhealthy_threshold
    timeout             = var.target_group_health_check_timeout
    interval            = var.target_group_health_check_interval
    path                = var.target_group_health_check_path
    matcher             = var.target_group_health_check_matcher
    protocol            = "HTTP"
    port                = "traffic-port"
  }

  deregistration_delay = var.target_group_deregistration_delay

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-conversation-agent-tg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Service Discovery Service
resource "aws_service_discovery_service" "conversation_agent" {
  count = var.enable_service_discovery ? 1 : 0

  name = "conversation-agent"

  dns_config {
    namespace_id = var.service_discovery_namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-conversation-agent-discovery"
    }
  )
}

# ECS Service
resource "aws_ecs_service" "conversation_agent" {
  name            = "conversation-agent"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.conversation_agent.arn
  desired_count   = var.desired_count

  deployment_configuration {
    minimum_healthy_percent         = var.deployment_minimum_healthy_percent
    maximum_percent                = var.deployment_maximum_percent
    deployment_circuit_breaker {
      enable   = true
      rollback = true
    }
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.conversation_agent.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.conversation_agent.arn
    container_name   = "conversation-agent"
    container_port   = var.container_port
  }

  dynamic "service_registries" {
    for_each = var.enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.conversation_agent[0].arn
    }
  }

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight           = capacity_provider_strategy.value.weight
      base             = capacity_provider_strategy.value.base
    }
  }

  # Enable execute command for debugging
  enable_execute_command = var.enable_execute_command

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-conversation-agent-service"
    }
  )

  depends_on = [aws_lb_target_group.conversation_agent]

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# Security Group for Conversation Agent
resource "aws_security_group" "conversation_agent" {
  name        = "${var.cluster_name}-conversation-agent-sg"
  description = "Security group for conversation agent service"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "HTTP from ALB"
  }

  # Allow communication with other services in the cluster
  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
    description     = "HTTP from other ECS services"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-conversation-agent-sg"
    }
  )
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "conversation_agent" {
  count = var.enable_auto_scaling ? 1 : 0

  max_capacity       = var.auto_scaling_max_capacity
  min_capacity       = var.auto_scaling_min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.conversation_agent.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = var.tags
}

# Auto Scaling Policy - CPU
resource "aws_appautoscaling_policy" "conversation_agent_cpu" {
  count = var.enable_auto_scaling ? 1 : 0

  name               = "${var.cluster_name}-conversation-agent-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.conversation_agent[0].resource_id
  scalable_dimension = aws_appautoscaling_target.conversation_agent[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.conversation_agent[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.auto_scaling_cpu_target
    scale_in_cooldown  = var.auto_scaling_scale_in_cooldown
    scale_out_cooldown = var.auto_scaling_scale_out_cooldown
  }
}

# Auto Scaling Policy - Memory
resource "aws_appautoscaling_policy" "conversation_agent_memory" {
  count = var.enable_auto_scaling ? 1 : 0

  name               = "${var.cluster_name}-conversation-agent-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.conversation_agent[0].resource_id
  scalable_dimension = aws_appautoscaling_target.conversation_agent[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.conversation_agent[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.auto_scaling_memory_target
    scale_in_cooldown  = var.auto_scaling_scale_in_cooldown
    scale_out_cooldown = var.auto_scaling_scale_out_cooldown
  }
}

# Data source for current AWS region
data "aws_region" "current" {}