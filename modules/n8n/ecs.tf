#------------------------------------------------------------------------------
# n8n Module - ECS Task Definitions and Services
# Three services: main (UI), webhook (external triggers), worker (job processing)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# n8n Main Service - UI and API
#------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "n8n_main" {
  family                   = local.main_service_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.main_cpu
  memory                   = var.main_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.n8n_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "n8n-main"
      image     = "${var.n8n_image}:${var.n8n_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.n8n_port
          hostPort      = var.n8n_port
          protocol      = "tcp"
        }
      ]

      environment = [
        for key, value in merge(local.common_environment, {
          # Main-specific configuration
          N8N_HOST                                 = "0.0.0.0"
          N8N_PORT                                 = tostring(var.n8n_port)
          N8N_PROTOCOL                             = "https"
          N8N_EDITOR_BASE_URL                      = "https://${var.main_host_header}"
          WEBHOOK_URL                              = "https://${var.webhook_host_header}"
          N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN = "true"
          }) : {
          name  = key
          value = value
        }
      ]

      secrets = [
        for secret in local.all_secrets : {
          name      = secret.name
          valueFrom = secret.valueFrom
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.n8n_main.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "n8n-main"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:${var.n8n_port}${var.health_check_path} || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(local.default_tags, {
    Service = "n8n-main"
  })
}

resource "aws_ecs_service" "n8n_main" {
  name                               = local.main_service_name
  cluster                            = var.ecs_cluster_id
  task_definition                    = aws_ecs_task_definition.n8n_main.arn
  desired_count                      = var.main_desired_count
  launch_type                        = "FARGATE"
  platform_version                   = "LATEST"
  health_check_grace_period_seconds  = 120
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.n8n_main.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.n8n_main.arn
    container_name   = "n8n-main"
    container_port   = var.n8n_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(local.default_tags, {
    Service = "n8n-main"
  })

  depends_on = [aws_lb_listener_rule.n8n_main]
}

#------------------------------------------------------------------------------
# n8n Webhook Service - External Webhook Processing
#------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "n8n_webhook" {
  family                   = local.webhook_service_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.webhook_cpu
  memory                   = var.webhook_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.n8n_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "n8n-webhook"
      image     = "${var.n8n_image}:${var.n8n_image_tag}"
      essential = true
      command   = ["webhook"]

      portMappings = [
        {
          containerPort = var.n8n_port
          hostPort      = var.n8n_port
          protocol      = "tcp"
        }
      ]

      environment = [
        for key, value in merge(local.common_environment, {
          # Webhook-specific configuration
          N8N_HOST                  = "0.0.0.0"
          N8N_PORT                  = tostring(var.n8n_port)
          QUEUE_HEALTH_CHECK_ACTIVE = "true"
          N8N_DISABLE_UI            = "true"
          }) : {
          name  = key
          value = value
        }
      ]

      secrets = [
        for secret in local.all_secrets : {
          name      = secret.name
          valueFrom = secret.valueFrom
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.n8n_webhook.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "n8n-webhook"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:${var.n8n_port}${var.health_check_path} || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(local.default_tags, {
    Service = "n8n-webhook"
  })
}

resource "aws_ecs_service" "n8n_webhook" {
  name                               = local.webhook_service_name
  cluster                            = var.ecs_cluster_id
  task_definition                    = aws_ecs_task_definition.n8n_webhook.arn
  desired_count                      = var.webhook_desired_count
  launch_type                        = "FARGATE"
  platform_version                   = "LATEST"
  health_check_grace_period_seconds  = 120
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.n8n_webhook.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.n8n_webhook.arn
    container_name   = "n8n-webhook"
    container_port   = var.n8n_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(local.default_tags, {
    Service = "n8n-webhook"
  })

  depends_on = [aws_lb_listener_rule.n8n_webhook]
}

#------------------------------------------------------------------------------
# n8n Worker Service - Background Job Processing
#------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "n8n_worker" {
  family                   = local.worker_service_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.worker_cpu
  memory                   = var.worker_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.n8n_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "n8n-worker"
      image     = "${var.n8n_image}:${var.n8n_image_tag}"
      essential = true
      command   = ["worker"]

      # Worker doesn't expose any ports - internal only
      portMappings = []

      environment = [
        for key, value in merge(local.common_environment, {
          # Worker-specific configuration
          EXECUTIONS_PROCESS               = "main"
          N8N_CONCURRENCY_PRODUCTION_LIMIT = tostring(var.worker_concurrency)
          N8N_DISABLE_UI                   = "true"
          }) : {
          name  = key
          value = value
        }
      ]

      secrets = [
        for secret in local.all_secrets : {
          name      = secret.name
          valueFrom = secret.valueFrom
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.n8n_worker.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "n8n-worker"
        }
      }

      # Worker health check via process check (no HTTP endpoint)
      healthCheck = {
        command     = ["CMD-SHELL", "pgrep -f 'n8n' || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(local.default_tags, {
    Service = "n8n-worker"
  })
}

resource "aws_ecs_service" "n8n_worker" {
  name                               = local.worker_service_name
  cluster                            = var.ecs_cluster_id
  task_definition                    = aws_ecs_task_definition.n8n_worker.arn
  desired_count                      = var.worker_desired_count
  launch_type                        = "FARGATE"
  platform_version                   = "LATEST"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.n8n_worker.id]
    assign_public_ip = false
  }

  # Worker has no load balancer - internal processing only

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(local.default_tags, {
    Service = "n8n-worker"
  })
}

#------------------------------------------------------------------------------
# Auto Scaling - n8n Main
#------------------------------------------------------------------------------

resource "aws_appautoscaling_target" "n8n_main" {
  count = var.main_enable_auto_scaling ? 1 : 0

  max_capacity       = var.main_max_capacity
  min_capacity       = var.main_min_capacity
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.n8n_main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "n8n_main_cpu" {
  count = var.main_enable_auto_scaling ? 1 : 0

  name               = "${local.main_service_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.n8n_main[0].resource_id
  scalable_dimension = aws_appautoscaling_target.n8n_main[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.n8n_main[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

#------------------------------------------------------------------------------
# Auto Scaling - n8n Webhook
#------------------------------------------------------------------------------

resource "aws_appautoscaling_target" "n8n_webhook" {
  count = var.webhook_enable_auto_scaling ? 1 : 0

  max_capacity       = var.webhook_max_capacity
  min_capacity       = var.webhook_min_capacity
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.n8n_webhook.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "n8n_webhook_cpu" {
  count = var.webhook_enable_auto_scaling ? 1 : 0

  name               = "${local.webhook_service_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.n8n_webhook[0].resource_id
  scalable_dimension = aws_appautoscaling_target.n8n_webhook[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.n8n_webhook[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

#------------------------------------------------------------------------------
# Auto Scaling - n8n Worker
#------------------------------------------------------------------------------

resource "aws_appautoscaling_target" "n8n_worker" {
  count = var.worker_enable_auto_scaling ? 1 : 0

  max_capacity       = var.worker_max_capacity
  min_capacity       = var.worker_min_capacity
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.n8n_worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "n8n_worker_cpu" {
  count = var.worker_enable_auto_scaling ? 1 : 0

  name               = "${local.worker_service_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.n8n_worker[0].resource_id
  scalable_dimension = aws_appautoscaling_target.n8n_worker[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.n8n_worker[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
