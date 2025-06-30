# modules/services/main.tf

/**
 * # Services Module for ECS
 *
 * This module creates multiple ECS services including:
 * - Voice Agent Service
 * - LiveKit Proxy Service
 * - Agent Analytics Service
 * - UI Console Service
 * - Agentic Framework Service
 * - Shared CloudWatch logs, service discovery, and networking
 */

# Data source for current AWS region
data "aws_region" "current" {}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "voice_agent" {
  name              = "/ecs/${var.cluster_name}/voice-agent"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-voice-agent-logs"
      Service = "voice-agent"
    }
  )
}

resource "aws_cloudwatch_log_group" "livekit_proxy" {
  name              = "/ecs/${var.cluster_name}/livekit-proxy"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-livekit-proxy-logs"
      Service = "livekit-proxy"
    }
  )
}

resource "aws_cloudwatch_log_group" "agent_analytics" {
  name              = "/ecs/${var.cluster_name}/agent-analytics"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-agent-analytics-logs"
      Service = "agent-analytics"
    }
  )
}

resource "aws_cloudwatch_log_group" "ui_console" {
  name              = "/ecs/${var.cluster_name}/ui-console"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-ui-console-logs"
      Service = "ui-console"
    }
  )
}

resource "aws_cloudwatch_log_group" "agentic_framework" {
  name              = "/ecs/${var.cluster_name}/agentic-framework"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-agentic-framework-logs"
      Service = "agentic-framework"
    }
  )
}

# Security Groups
resource "aws_security_group" "voice_agent" {
  name        = "${var.cluster_name}-voice-agent-sg"
  description = "Security group for voice agent service"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.voice_agent_port
    to_port         = var.voice_agent_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "HTTP from ALB"
  }

  ingress {
    from_port       = var.voice_agent_port
    to_port         = var.voice_agent_port
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
      Name    = "${var.cluster_name}-voice-agent-sg"
      Service = "voice-agent"
    }
  )
}

resource "aws_security_group" "livekit_proxy" {
  name        = "${var.cluster_name}-livekit-proxy-sg"
  description = "Security group for LiveKit proxy service"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.livekit_proxy_port
    to_port         = var.livekit_proxy_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "HTTP from ALB"
  }

  ingress {
    from_port       = var.livekit_proxy_port
    to_port         = var.livekit_proxy_port
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
      Name    = "${var.cluster_name}-livekit-proxy-sg"
      Service = "livekit-proxy"
    }
  )
}

resource "aws_security_group" "agent_analytics" {
  name        = "${var.cluster_name}-agent-analytics-sg"
  description = "Security group for agent analytics service"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.agent_analytics_port
    to_port         = var.agent_analytics_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "HTTP from ALB"
  }

  ingress {
    from_port       = var.agent_analytics_port
    to_port         = var.agent_analytics_port
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
      Name    = "${var.cluster_name}-agent-analytics-sg"
      Service = "agent-analytics"
    }
  )
}

resource "aws_security_group" "ui_console" {
  name        = "${var.cluster_name}-ui-console-sg"
  description = "Security group for UI console service"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.ui_console_port
    to_port         = var.ui_console_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "HTTP from ALB"
  }

  ingress {
    from_port       = var.ui_console_port
    to_port         = var.ui_console_port
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
      Name    = "${var.cluster_name}-ui-console-sg"
      Service = "ui-console"
    }
  )
}

resource "aws_security_group" "agentic_framework" {
  name        = "${var.cluster_name}-agentic-framework-sg"
  description = "Security group for agentic framework service"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.agentic_framework_port
    to_port         = var.agentic_framework_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "HTTP from ALB"
  }

  ingress {
    from_port       = var.agentic_framework_port
    to_port         = var.agentic_framework_port
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
      Name    = "${var.cluster_name}-agentic-framework-sg"
      Service = "agentic-framework"
    }
  )
}

# Task Definitions
resource "aws_ecs_task_definition" "voice_agent" {
  family                   = "${var.cluster_name}-voice-agent"
  network_mode             = "awsvpc"
  requires_compatibilities = var.enable_fargate ? ["FARGATE"] : ["EC2"]
  cpu                      = var.voice_agent_cpu
  memory                   = var.voice_agent_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn           = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "voice-agent"
      image = "${var.voice_agent_ecr_repository_url}:${var.voice_agent_image_tag}"
      
      essential = true
      
      portMappings = [
        {
          containerPort = var.voice_agent_port
          protocol      = "tcp"
        }
      ]

      environment = concat([
        {
          name  = "LOG_LEVEL"
          value = var.voice_agent_log_level
        },
        {
          name  = "AGENT_COLLECTION_NAME"
          value = var.voice_agent_agent_collection_name
        },
        {
          name  = "FRAMES_COLLECTION_NAME"
          value = var.voice_agent_frames_collection_name
        },
        {
          name  = "DATABASE_NAME"
          value = var.voice_agent_database_name
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
          value = var.voice_agent_mongodb_uri
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
          value = var.voice_agent_livekit_api_key
        },
        {
          name  = "LIVEKIT_AGENT_API_SECRET"
          value = var.voice_agent_livekit_api_secret
        },
        {
          name  = "LK_API_KEY"
          value = var.voice_agent_livekit_api_key
        },
        {
          name  = "LK_API_SECRET"
          value = var.voice_agent_livekit_api_secret
        },
        {
          name  = "devkey"
          value = var.voice_agent_livekit_api_key
        },
        {
          name  = "devsecret"
          value = var.voice_agent_livekit_api_secret
        }
      ], [
        for key, value in var.voice_agent_additional_environment_variables : {
          name  = key
          value = tostring(value)
        }
      ])

      secrets = concat(
        var.voice_agent_anthropic_api_key_secret_arn != "" ? [{
          name      = "ANTHROPIC_API_KEY"
          valueFrom = var.voice_agent_anthropic_api_key_secret_arn
        }] : [],
        var.voice_agent_deepgram_api_key_secret_arn != "" ? [{
          name      = "DEEPGRAM_API_KEY"
          valueFrom = var.voice_agent_deepgram_api_key_secret_arn
        }] : [],
        var.voice_agent_cartesia_api_key_secret_arn != "" ? [{
          name      = "CARTESIA_API_KEY"
          valueFrom = var.voice_agent_cartesia_api_key_secret_arn
        }] : [],
        var.voice_agent_livekit_api_key_secret_arn != "" ? [{
          name      = "LIVEKIT_API_KEY"
          valueFrom = var.voice_agent_livekit_api_key_secret_arn
        }] : [],
        var.voice_agent_livekit_api_secret_secret_arn != "" ? [{
          name      = "LIVEKIT_API_SECRET"
          valueFrom = var.voice_agent_livekit_api_secret_secret_arn
        }] : []
      )

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.voice_agent.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = var.voice_agent_enable_health_check ? {
        command = [
          "CMD-SHELL",
          var.voice_agent_health_check_command
        ]
        interval    = var.voice_agent_health_check_interval
        timeout     = var.voice_agent_health_check_timeout
        retries     = var.voice_agent_health_check_retries
        startPeriod = var.voice_agent_health_check_start_period
      } : null

      mountPoints = var.voice_agent_enable_efs ? [
        {
          sourceVolume  = "efs-storage"
          containerPath = var.voice_agent_efs_mount_path
          readOnly      = false
        }
      ] : []
    }
  ])

  dynamic "volume" {
    for_each = var.voice_agent_enable_efs ? [1] : []
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
      Name    = "${var.cluster_name}-voice-agent-task"
      Service = "voice-agent"
    }
  )
}

resource "aws_ecs_task_definition" "livekit_proxy" {
  family                   = "${var.cluster_name}-livekit-proxy"
  network_mode             = "awsvpc"
  requires_compatibilities = var.enable_fargate ? ["FARGATE"] : ["EC2"]
  cpu                      = var.livekit_proxy_cpu
  memory                   = var.livekit_proxy_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn           = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "livekit-proxy"
      image = "${var.livekit_proxy_ecr_repository_url}:${var.livekit_proxy_image_tag}"
      
      essential = true
      
      portMappings = [
        {
          containerPort = var.livekit_proxy_port
          protocol      = "tcp"
        }
      ]

      environment = concat([
        {
          name  = "LOG_LEVEL"
          value = var.livekit_proxy_log_level
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
          name  = "LIVEKIT_HOST"
          value = "ws://${var.livekit_service_name}.${var.service_discovery_namespace}:7880"
        },
        {
          name  = "LIVEKIT_URL"
          value = "http://${var.livekit_service_name}.${var.service_discovery_namespace}:7880"
        },
        {
          name  = "LIVEKIT_API_KEY"
          value = var.livekit_proxy_livekit_api_key
        },
        {
          name  = "LIVEKIT_API_SECRET"
          value = var.livekit_proxy_livekit_api_secret
        },
        {
          name  = "LK_API_KEY"
          value = var.livekit_proxy_livekit_api_key
        },
        {
          name  = "LK_API_SECRET"
          value = var.livekit_proxy_livekit_api_secret
        },
        {
          name  = "PORT"
          value = tostring(var.livekit_proxy_port)
        }
      ], [
        for key, value in var.livekit_proxy_additional_environment_variables : {
          name  = key
          value = tostring(value)
        }
      ])

      secrets = concat(
        var.livekit_proxy_livekit_api_key_secret_arn != "" ? [{
          name      = "LIVEKIT_API_KEY"
          valueFrom = var.livekit_proxy_livekit_api_key_secret_arn
        }] : [],
        var.livekit_proxy_livekit_api_secret_secret_arn != "" ? [{
          name      = "LIVEKIT_API_SECRET"
          valueFrom = var.livekit_proxy_livekit_api_secret_secret_arn
        }] : []
      )

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.livekit_proxy.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = var.livekit_proxy_enable_health_check ? {
        command = [
          "CMD-SHELL",
          var.livekit_proxy_health_check_command
        ]
        interval    = var.livekit_proxy_health_check_interval
        timeout     = var.livekit_proxy_health_check_timeout
        retries     = var.livekit_proxy_health_check_retries
        startPeriod = var.livekit_proxy_health_check_start_period
      } : null

      mountPoints = var.livekit_proxy_enable_efs ? [
        {
          sourceVolume  = "efs-storage"
          containerPath = var.livekit_proxy_efs_mount_path
          readOnly      = false
        }
      ] : []
    }
  ])

  dynamic "volume" {
    for_each = var.livekit_proxy_enable_efs ? [1] : []
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
      Name    = "${var.cluster_name}-livekit-proxy-task"
      Service = "livekit-proxy"
    }
  )
}

# Agent Analytics Task Definition
resource "aws_ecs_task_definition" "agent_analytics" {
  family                   = "${var.cluster_name}-agent-analytics"
  network_mode             = "awsvpc"
  requires_compatibilities = var.enable_fargate ? ["FARGATE"] : ["EC2"]
  cpu                      = var.agent_analytics_cpu
  memory                   = var.agent_analytics_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn           = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "agent-analytics"
      image = "${var.agent_analytics_ecr_repository_url}:${var.agent_analytics_image_tag}"
      
      essential = true
      
      portMappings = [
        {
          containerPort = var.agent_analytics_port
          protocol      = "tcp"
        }
      ]

      environment = concat([
        {
          name  = "LOG_LEVEL"
          value = var.agent_analytics_log_level
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
          name  = "PORT"
          value = tostring(var.agent_analytics_port)
        },
        {
          name  = "MONGO_DB_URL"
          value = var.agent_analytics_mongodb_uri
        }
      ], [
        for key, value in var.agent_analytics_additional_environment_variables : {
          name  = key
          value = tostring(value)
        }
      ])

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.agent_analytics.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = var.agent_analytics_enable_health_check ? {
        command = [
          "CMD-SHELL",
          var.agent_analytics_health_check_command
        ]
        interval    = var.agent_analytics_health_check_interval
        timeout     = var.agent_analytics_health_check_timeout
        retries     = var.agent_analytics_health_check_retries
        startPeriod = var.agent_analytics_health_check_start_period
      } : null

      mountPoints = var.agent_analytics_enable_efs ? [
        {
          sourceVolume  = "efs-storage"
          containerPath = var.agent_analytics_efs_mount_path
          readOnly      = false
        }
      ] : []
    }
  ])

  dynamic "volume" {
    for_each = var.agent_analytics_enable_efs ? [1] : []
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
      Name    = "${var.cluster_name}-agent-analytics-task"
      Service = "agent-analytics"
    }
  )
}

# UI Console Task Definition
resource "aws_ecs_task_definition" "ui_console" {
  family                   = "${var.cluster_name}-ui-console"
  network_mode             = "awsvpc"
  requires_compatibilities = var.enable_fargate ? ["FARGATE"] : ["EC2"]
  cpu                      = var.ui_console_cpu
  memory                   = var.ui_console_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn           = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "ui-console"
      image = "${var.ui_console_ecr_repository_url}:${var.ui_console_image_tag}"
      
      essential = true
      
      portMappings = [
        {
          containerPort = var.ui_console_port
          protocol      = "tcp"
        }
      ]

      environment = concat([
        {
          name  = "LOG_LEVEL"
          value = var.ui_console_log_level
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
          name  = "PORT"
          value = tostring(var.ui_console_port)
        }
      ], [
        for key, value in var.ui_console_additional_environment_variables : {
          name  = key
          value = tostring(value)
        }
      ])

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ui_console.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = var.ui_console_enable_health_check ? {
        command = [
          "CMD-SHELL",
          var.ui_console_health_check_command
        ]
        interval    = var.ui_console_health_check_interval
        timeout     = var.ui_console_health_check_timeout
        retries     = var.ui_console_health_check_retries
        startPeriod = var.ui_console_health_check_start_period
      } : null

      mountPoints = var.ui_console_enable_efs ? [
        {
          sourceVolume  = "efs-storage"
          containerPath = var.ui_console_efs_mount_path
          readOnly      = false
        }
      ] : []
    }
  ])

  dynamic "volume" {
    for_each = var.ui_console_enable_efs ? [1] : []
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
      Name    = "${var.cluster_name}-ui-console-task"
      Service = "ui-console"
    }
  )
}

# Agentic Framework Task Definition
resource "aws_ecs_task_definition" "agentic_framework" {
  family                   = "${var.cluster_name}-agentic-framework"
  network_mode             = "awsvpc"
  requires_compatibilities = var.enable_fargate ? ["FARGATE"] : ["EC2"]
  cpu                      = var.agentic_framework_cpu
  memory                   = var.agentic_framework_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn           = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "agentic-framework"
      image = "${var.agentic_framework_ecr_repository_url}:${var.agentic_framework_image_tag}"
      
      essential = true
      
      portMappings = [
        {
          containerPort = var.agentic_framework_port
          protocol      = "tcp"
        }
      ]

      environment = concat([
        {
          name  = "LOG_LEVEL"
          value = var.agentic_framework_log_level
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
          name  = "PORT"
          value = tostring(var.agentic_framework_port)
        },
        {
          name  = "MONGO_DB_URL"
          value = var.agentic_framework_mongodb_uri
        }
      ], [
        for key, value in var.agentic_framework_additional_environment_variables : {
          name  = key
          value = tostring(value)
        }
      ])

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.agentic_framework.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = var.agentic_framework_enable_health_check ? {
        command = [
          "CMD-SHELL",
          var.agentic_framework_health_check_command
        ]
        interval    = var.agentic_framework_health_check_interval
        timeout     = var.agentic_framework_health_check_timeout
        retries     = var.agentic_framework_health_check_retries
        startPeriod = var.agentic_framework_health_check_start_period
      } : null

      mountPoints = var.agentic_framework_enable_efs ? [
        {
          sourceVolume  = "efs-storage"
          containerPath = var.agentic_framework_efs_mount_path
          readOnly      = false
        }
      ] : []
    }
  ])

  dynamic "volume" {
    for_each = var.agentic_framework_enable_efs ? [1] : []
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
      Name    = "${var.cluster_name}-agentic-framework-task"
      Service = "agentic-framework"
    }
  )
}

# Target Groups
resource "aws_lb_target_group" "voice_agent" {
  name        = trim(substr(replace("${var.cluster_name}-voice-agent-tg", "_", "-"), 0, 32), "-")
  port        = var.voice_agent_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = var.enable_fargate ? "ip" : "instance"

  health_check {
    enabled             = true
    healthy_threshold   = var.voice_agent_target_group_health_check_healthy_threshold
    unhealthy_threshold = var.voice_agent_target_group_health_check_unhealthy_threshold
    timeout             = var.voice_agent_target_group_health_check_timeout
    interval            = var.voice_agent_target_group_health_check_interval
    path                = var.voice_agent_target_group_health_check_path
    matcher             = var.voice_agent_target_group_health_check_matcher
    protocol            = "HTTP"
    port                = "traffic-port"
  }

  deregistration_delay = var.voice_agent_target_group_deregistration_delay

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-voice-agent-tg"
      Service = "voice-agent"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "livekit_proxy" {
  name        = trim(substr(replace("${var.cluster_name}-livekit-proxy-tg", "_", "-"), 0, 32), "-")
  port        = var.livekit_proxy_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = var.enable_fargate ? "ip" : "instance"

  health_check {
    enabled             = true
    healthy_threshold   = var.livekit_proxy_target_group_health_check_healthy_threshold
    unhealthy_threshold = var.livekit_proxy_target_group_health_check_unhealthy_threshold
    timeout             = var.livekit_proxy_target_group_health_check_timeout
    interval            = var.livekit_proxy_target_group_health_check_interval
    path                = var.livekit_proxy_target_group_health_check_path
    matcher             = var.livekit_proxy_target_group_health_check_matcher
    protocol            = "HTTP"
    port                = "traffic-port"
  }

  deregistration_delay = var.livekit_proxy_target_group_deregistration_delay

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-livekit-proxy-tg"
      Service = "livekit-proxy"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "agent_analytics" {
  name        = trim(substr(replace("${var.cluster_name}-agent-analytics-tg", "_", "-"), 0, 32), "-")
  port        = var.agent_analytics_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = var.enable_fargate ? "ip" : "instance"

  health_check {
    enabled             = true
    healthy_threshold   = var.agent_analytics_target_group_health_check_healthy_threshold
    unhealthy_threshold = var.agent_analytics_target_group_health_check_unhealthy_threshold
    timeout             = var.agent_analytics_target_group_health_check_timeout
    interval            = var.agent_analytics_target_group_health_check_interval
    path                = var.agent_analytics_target_group_health_check_path
    matcher             = var.agent_analytics_target_group_health_check_matcher
    protocol            = "HTTP"
    port                = "traffic-port"
  }

  deregistration_delay = var.agent_analytics_target_group_deregistration_delay

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-agent-analytics-tg"
      Service = "agent-analytics"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "ui_console" {
  name        = trim(substr(replace("${var.cluster_name}-ui-console-tg", "_", "-"), 0, 32), "-")
  port        = var.ui_console_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = var.enable_fargate ? "ip" : "instance"

  health_check {
    enabled             = true
    healthy_threshold   = var.ui_console_target_group_health_check_healthy_threshold
    unhealthy_threshold = var.ui_console_target_group_health_check_unhealthy_threshold
    timeout             = var.ui_console_target_group_health_check_timeout
    interval            = var.ui_console_target_group_health_check_interval
    path                = var.ui_console_target_group_health_check_path
    matcher             = var.ui_console_target_group_health_check_matcher
    protocol            = "HTTP"
    port                = "traffic-port"
  }

  deregistration_delay = var.ui_console_target_group_deregistration_delay

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-ui-console-tg"
      Service = "ui-console"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "agentic_framework" {
  name        = trim(substr(replace("${var.cluster_name}-agentic-framework-tg", "_", "-"), 0, 32), "-")
  port        = var.agentic_framework_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = var.enable_fargate ? "ip" : "instance"

  health_check {
    enabled             = true
    healthy_threshold   = var.agentic_framework_target_group_health_check_healthy_threshold
    unhealthy_threshold = var.agentic_framework_target_group_health_check_unhealthy_threshold
    timeout             = var.agentic_framework_target_group_health_check_timeout
    interval            = var.agentic_framework_target_group_health_check_interval
    path                = var.agentic_framework_target_group_health_check_path
    matcher             = var.agentic_framework_target_group_health_check_matcher
    protocol            = "HTTP"
    port                = "traffic-port"
  }

  deregistration_delay = var.agentic_framework_target_group_deregistration_delay

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-agentic-framework-tg"
      Service = "agentic-framework"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Service Discovery Services
resource "aws_service_discovery_service" "voice_agent" {
  count = var.voice_agent_enable_service_discovery ? 1 : 0

  name = "voice-agent"

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
      Name    = "${var.cluster_name}-voice-agent-discovery"
      Service = "voice-agent"
    }
  )
}

resource "aws_service_discovery_service" "livekit_proxy" {
  count = var.livekit_proxy_enable_service_discovery ? 1 : 0

  name = "livekit-proxy"

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
      Name    = "${var.cluster_name}-livekit-proxy-discovery"
      Service = "livekit-proxy"
    }
  )
}

resource "aws_service_discovery_service" "agent_analytics" {
  count = var.agent_analytics_enable_service_discovery ? 1 : 0

  name = "agent-analytics"

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
      Name    = "${var.cluster_name}-agent-analytics-discovery"
      Service = "agent-analytics"
    }
  )
}

resource "aws_service_discovery_service" "ui_console" {
  count = var.ui_console_enable_service_discovery ? 1 : 0

  name = "ui-console"

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
      Name    = "${var.cluster_name}-ui-console-discovery"
      Service = "ui-console"
    }
  )
}

resource "aws_service_discovery_service" "agentic_framework" {
  count = var.agentic_framework_enable_service_discovery ? 1 : 0

  name = "agentic-framework"

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
      Name    = "${var.cluster_name}-agentic-framework-discovery"
      Service = "agentic-framework"
    }
  )
}

# ECS Services
resource "aws_ecs_service" "voice_agent" {
  name            = "voice-agent"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.voice_agent.arn
  desired_count   = var.voice_agent_desired_count

  deployment_minimum_healthy_percent = var.voice_agent_deployment_minimum_healthy_percent
  deployment_maximum_percent        = var.voice_agent_deployment_maximum_percent
  
  enable_execute_command = var.enable_execute_command

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.voice_agent.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.voice_agent.arn
    container_name   = "voice-agent"
    container_port   = var.voice_agent_port
  }

  dynamic "service_registries" {
    for_each = var.voice_agent_enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.voice_agent[0].arn
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

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-voice-agent-service"
      Service = "voice-agent"
    }
  )

  depends_on = [aws_lb_target_group.voice_agent]

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_ecs_service" "livekit_proxy" {
  name            = "livekit-proxy"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.livekit_proxy.arn
  desired_count   = var.livekit_proxy_desired_count

  deployment_minimum_healthy_percent = var.livekit_proxy_deployment_minimum_healthy_percent
  deployment_maximum_percent        = var.livekit_proxy_deployment_maximum_percent
  
  enable_execute_command = var.enable_execute_command

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.livekit_proxy.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.livekit_proxy.arn
    container_name   = "livekit-proxy"
    container_port   = var.livekit_proxy_port
  }

  dynamic "service_registries" {
    for_each = var.livekit_proxy_enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.livekit_proxy[0].arn
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

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-livekit-proxy-service"
      Service = "livekit-proxy"
    }
  )

  depends_on = [aws_lb_target_group.livekit_proxy]

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_ecs_service" "agent_analytics" {
  name            = "agent-analytics"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.agent_analytics.arn
  desired_count   = var.agent_analytics_desired_count

  deployment_minimum_healthy_percent = var.agent_analytics_deployment_minimum_healthy_percent
  deployment_maximum_percent        = var.agent_analytics_deployment_maximum_percent
  
  enable_execute_command = var.enable_execute_command

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.agent_analytics.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.agent_analytics.arn
    container_name   = "agent-analytics"
    container_port   = var.agent_analytics_port
  }

  dynamic "service_registries" {
    for_each = var.agent_analytics_enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.agent_analytics[0].arn
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

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-agent-analytics-service"
      Service = "agent-analytics"
    }
  )

  depends_on = [aws_lb_target_group.agent_analytics]

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_ecs_service" "ui_console" {
  name            = "ui-console"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.ui_console.arn
  desired_count   = var.ui_console_desired_count

  deployment_minimum_healthy_percent = var.ui_console_deployment_minimum_healthy_percent
  deployment_maximum_percent        = var.ui_console_deployment_maximum_percent
  
  enable_execute_command = var.enable_execute_command

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ui_console.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ui_console.arn
    container_name   = "ui-console"
    container_port   = var.ui_console_port
  }

  dynamic "service_registries" {
    for_each = var.ui_console_enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.ui_console[0].arn
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

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-ui-console-service"
      Service = "ui-console"
    }
  )

  depends_on = [aws_lb_target_group.ui_console]

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_ecs_service" "agentic_framework" {
  name            = "agentic-framework"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.agentic_framework.arn
  desired_count   = var.agentic_framework_desired_count

  deployment_minimum_healthy_percent = var.agentic_framework_deployment_minimum_healthy_percent
  deployment_maximum_percent        = var.agentic_framework_deployment_maximum_percent
  
  enable_execute_command = var.enable_execute_command

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.agentic_framework.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.agentic_framework.arn
    container_name   = "agentic-framework"
    container_port   = var.agentic_framework_port
  }

  dynamic "service_registries" {
    for_each = var.agentic_framework_enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.agentic_framework[0].arn
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

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-agentic-framework-service"
      Service = "agentic-framework"
    }
  )

  depends_on = [aws_lb_target_group.agentic_framework]

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# Auto Scaling Targets
resource "aws_appautoscaling_target" "voice_agent" {
  count = var.voice_agent_enable_auto_scaling ? 1 : 0

  max_capacity       = var.voice_agent_auto_scaling_max_capacity
  min_capacity       = var.voice_agent_auto_scaling_min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.voice_agent.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = merge(var.tags, { Service = "voice-agent" })
}

resource "aws_appautoscaling_target" "livekit_proxy" {
  count = var.livekit_proxy_enable_auto_scaling ? 1 : 0

  max_capacity       = var.livekit_proxy_auto_scaling_max_capacity
  min_capacity       = var.livekit_proxy_auto_scaling_min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.livekit_proxy.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = merge(var.tags, { Service = "livekit-proxy" })
}

resource "aws_appautoscaling_target" "agent_analytics" {
  count = var.agent_analytics_enable_auto_scaling ? 1 : 0

  max_capacity       = var.agent_analytics_auto_scaling_max_capacity
  min_capacity       = var.agent_analytics_auto_scaling_min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.agent_analytics.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = merge(var.tags, { Service = "agent-analytics" })
}

resource "aws_appautoscaling_target" "ui_console" {
  count = var.ui_console_enable_auto_scaling ? 1 : 0

  max_capacity       = var.ui_console_auto_scaling_max_capacity
  min_capacity       = var.ui_console_auto_scaling_min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.ui_console.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = merge(var.tags, { Service = "ui-console" })
}

resource "aws_appautoscaling_target" "agentic_framework" {
  count = var.agentic_framework_enable_auto_scaling ? 1 : 0

  max_capacity       = var.agentic_framework_auto_scaling_max_capacity
  min_capacity       = var.agentic_framework_auto_scaling_min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.agentic_framework.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = merge(var.tags, { Service = "agentic-framework" })
}

# Auto Scaling Policies - CPU
resource "aws_appautoscaling_policy" "voice_agent_cpu" {
  count = var.voice_agent_enable_auto_scaling ? 1 : 0

  name               = "${var.cluster_name}-voice-agent-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.voice_agent[0].resource_id
  scalable_dimension = aws_appautoscaling_target.voice_agent[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.voice_agent[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.voice_agent_auto_scaling_cpu_target
    scale_in_cooldown  = var.voice_agent_auto_scaling_scale_in_cooldown
    scale_out_cooldown = var.voice_agent_auto_scaling_scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "livekit_proxy_cpu" {
  count = var.livekit_proxy_enable_auto_scaling ? 1 : 0

  name               = "${var.cluster_name}-livekit-proxy-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.livekit_proxy[0].resource_id
  scalable_dimension = aws_appautoscaling_target.livekit_proxy[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.livekit_proxy[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.livekit_proxy_auto_scaling_cpu_target
    scale_in_cooldown  = var.livekit_proxy_auto_scaling_scale_in_cooldown
    scale_out_cooldown = var.livekit_proxy_auto_scaling_scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "agent_analytics_cpu" {
  count = var.agent_analytics_enable_auto_scaling ? 1 : 0

  name               = "${var.cluster_name}-agent-analytics-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.agent_analytics[0].resource_id
  scalable_dimension = aws_appautoscaling_target.agent_analytics[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.agent_analytics[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.agent_analytics_auto_scaling_cpu_target
    scale_in_cooldown  = var.agent_analytics_auto_scaling_scale_in_cooldown
    scale_out_cooldown = var.agent_analytics_auto_scaling_scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "ui_console_cpu" {
  count = var.ui_console_enable_auto_scaling ? 1 : 0

  name               = "${var.cluster_name}-ui-console-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ui_console[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ui_console[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ui_console[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.ui_console_auto_scaling_cpu_target
    scale_in_cooldown  = var.ui_console_auto_scaling_scale_in_cooldown
    scale_out_cooldown = var.ui_console_auto_scaling_scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "agentic_framework_memory" {
  count = var.agentic_framework_enable_auto_scaling ? 1 : 0

  name               = "${var.cluster_name}-agentic-framework-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.agentic_framework[0].resource_id
  scalable_dimension = aws_appautoscaling_target.agentic_framework[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.agentic_framework[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.agentic_framework_auto_scaling_memory_target
    scale_in_cooldown  = var.agentic_framework_auto_scaling_scale_in_cooldown
    scale_out_cooldown = var.agentic_framework_auto_scaling_scale_out_cooldown
  }
}console_auto_scaling_scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "agentic_framework_cpu" {
  count = var.agentic_framework_enable_auto_scaling ? 1 : 0

  name               = "${var.cluster_name}-agentic-framework-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.agentic_framework[0].resource_id
  scalable_dimension = aws_appautoscaling_target.agentic_framework[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.agentic_framework[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.agentic_framework_auto_scaling_cpu_target
    scale_in_cooldown  = var.agentic_framework_auto_scaling_scale_in_cooldown
    scale_out_cooldown = var.agentic_framework_auto_scaling_scale_out_cooldown
  }
}

# Auto Scaling Policies - Memory
resource "aws_appautoscaling_policy" "voice_agent_memory" {
  count = var.voice_agent_enable_auto_scaling ? 1 : 0

  name               = "${var.cluster_name}-voice-agent-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.voice_agent[0].resource_id
  scalable_dimension = aws_appautoscaling_target.voice_agent[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.voice_agent[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.voice_agent_auto_scaling_memory_target
    scale_in_cooldown  = var.voice_agent_auto_scaling_scale_in_cooldown
    scale_out_cooldown = var.voice_agent_auto_scaling_scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "livekit_proxy_memory" {
  count = var.livekit_proxy_enable_auto_scaling ? 1 : 0

  name               = "${var.cluster_name}-livekit-proxy-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.livekit_proxy[0].resource_id
  scalable_dimension = aws_appautoscaling_target.livekit_proxy[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.livekit_proxy[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.livekit_proxy_auto_scaling_memory_target
    scale_in_cooldown  = var.livekit_proxy_auto_scaling_scale_in_cooldown
    scale_out_cooldown = var.livekit_proxy_auto_scaling_scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "agent_analytics_memory" {
  count = var.agent_analytics_enable_auto_scaling ? 1 : 0

  name               = "${var.cluster_name}-agent-analytics-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.agent_analytics[0].resource_id
  scalable_dimension = aws_appautoscaling_target.agent_analytics[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.agent_analytics[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.agent_analytics_auto_scaling_memory_target
    scale_in_cooldown  = var.agent_analytics_auto_scaling_scale_in_cooldown
    scale_out_cooldown = var.agent_analytics_auto_scaling_scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "ui_console_memory" {
  count = var.ui_console_enable_auto_scaling ? 1 : 0

  name               = "${var.cluster_name}-ui-console-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ui_console[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ui_console[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ui_console[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.ui_console_auto_scaling_memory_target
    scale_in_cooldown  = var.ui_console_auto_scaling_scale_in_cooldown
    scale_out_cooldown = var.ui_