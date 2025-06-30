# modules/ecs-refactored/task-definitions.tf

locals {
  # Generate container definitions for each service
  container_definitions = { for name, config in local.services_config : name => jsonencode([
    {
      name  = name
      image = "${config.image}:${lookup(config, "image_tag", "latest")}"

      cpu    = config.cpu
      memory = config.memory

      essential = true

      portMappings = [
        {
          containerPort = config.port
          hostPort      = config.port
          protocol      = "tcp"
        }
      ]

      environment = concat(
        # Standard environment variables
        [
          for k, v in lookup(config, "environment", {}) : {
          name  = k
          value = tostring(v)
        }
        ],
        # Add any common environment variables
        [
          {
            name  = "SERVICE_NAME"
            value = name
          },
          {
            name  = "ENVIRONMENT"
            value = var.environment
          }
        ]
      )

      secrets = [
        for secret in lookup(config, "secrets", []) : {
          name      = secret.name
          valueFrom = secret.value_from
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = config.log_group_name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }

      healthCheck = lookup(config, "container_health_check", null) != null ? {
        command     = ["CMD-SHELL", config.container_health_check.command]
        interval    = lookup(config.container_health_check, "interval", 30)
        timeout     = lookup(config.container_health_check, "timeout", 20)
        retries     = lookup(config.container_health_check, "retries", 3)
        startPeriod = lookup(config.container_health_check, "start_period", 90)
      } : null

      mountPoints = lookup(config, "efs_config", null) != null && config.efs_config.enabled ? [
        {
          sourceVolume  = "efs-storage"
          containerPath = config.efs_config.mount_path
          readOnly      = false
        }
      ] : []

      # Additional container settings
      linuxParameters = lookup(config, "linux_parameters", null)
      ulimits         = lookup(config, "ulimits", null)

      # Resource reservations
      memoryReservation = lookup(config, "memory_reservation", null)
    }
  ])}
}