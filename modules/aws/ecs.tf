locals {
  container_definitions = {
    for service in var.services : service.name => {
      cpu       = service.cpu
      memory    = service.memory
      essential = true
      image     = service.ecr_repo

      port_mappings = [
        {
          name          = service.name
          containerPort = service.port
          hostPort      = service.port
          protocol      = "tcp"
        }
      ]

      mount_points = [
        {
          sourceVolume  = "${service.name}-storage"
          containerPath = service.storage_mount_path
          readOnly      = false
        }
      ]

      environment = [
        for key, value in service.environment_variables : {
          name  = key
          value = value
        }
      ]

      secrets = [
        for key, value in service.secrets : {
          name      = key
          valueFrom = value
        }
      ]

      # Add container-level auto-scaling configurations
      docker_labels = {
        "com.amazonaws.ecs.capacity-provider-preference" = jsonencode(service.capacity_provider_strategy)
        "com.amazonaws.ecs.task-definition-version" = "$${ECS_CONTAINER_METADATA_FILE}"
      }

      health_check = length(service.health_check_path) > 0 ? {
        command = ["CMD-SHELL", "curl -f http://localhost:${service.port}${service.health_check_path} || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 6
        startPeriod = 60
      } : null

      enable_cloudwatch_logging = true
      # Enhanced logging configuration
      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group           = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region          = var.aws_region
          awslogs-stream-prefix   = service.name
          awslogs-datetime-format = "%Y-%m-%d %H:%M:%S"
          max-size                = "100m"
          max-file                = "3"
        }
      }

      # System controls for container
      systemControls = [
        {
          namespace = "net.core.somaxconn"
          value     = "1024"
        }
      ]

      # Resource limits
      ulimits = [
        {
          name      = "nofile"
          softLimit = 65536
          hardLimit = 65536
        }
      ]

    }
  }

  service_definitions = {
    for service in var.services : service.name => {
      cpu = service.cpu
      memory = service.memory

      # Container definition(s)
      container_definitions = {
        (service.name) = local.container_definitions[service.name]
      }

      service_connect_configuration = var.enable_service_discovery ? {
        namespace = aws_service_discovery_http_namespace.this[0].arn
        service = {
          client_alias = {
            port     = service.port
            dns_name = service.name
          }
          port_name      = service.name
          discovery_name = service.name
        }
      } : null

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups[index(var.services[*].name, service.name)].arn
          container_name   = service.name
          container_port   = service.port
        }
      }

      subnet_ids = module.vpc.public_subnets
      security_group_rules = {
        alb_ingress = {
          type                     = "ingress"
          from_port                = service.port
          to_port                  = service.port
          protocol                 = "tcp"
          description              = "Service port"
          source_security_group_id = aws_security_group.ecs_sg.id
        }
        egress_all = {
          type      = "egress"
          from_port = 0
          to_port   = 0
          protocol  = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }

      capacity_provider_strategy = {
        for strategy in service.capacity_provider_strategy : strategy.capacity_provider => {
          weight = strategy.weight
          base   = strategy.base
        }
      }

      volume = {
        "${service.name}-storage" = {
          efs_volume_configuration = {
            file_system_id     = module.efs.id
            root_directory     = "/"
            transit_encryption = "ENABLED"
            authorization_config = {
              access_point_id = module.efs.access_points[index(var.services[*].name, service.name)].id
              iam             = "ENABLED"
            }
          }
        }
      }

      tasks_iam_role_name        = "${local.name}-${service.name}-tasks"
      tasks_iam_role_description = "Task role for ${service.name}"
      tasks_iam_role_policies    = {
        for policy in service.additional_policies : basename(policy) => policy
      }

      enable_execute_command = var.enable_ecs_exec
    }
  }
}

# Main ECS Module
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.12.0"

  cluster_name = local.name

  # Capacity provider - both Fargate and EC2
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = var.capacity_provider_strategy[1].weight
        base   = var.capacity_provider_strategy[1].base
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = var.capacity_provider_strategy[0].weight
        base   = var.capacity_provider_strategy[0].base
      }
    }
  }

  # EC2 capacity providers with autoscaling groups
  autoscaling_capacity_providers = {
    # On-demand instances
    on_demand = {
      auto_scaling_group_arn         = module.autoscaling["on_demand"].autoscaling_group_arn
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 5
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 60
      }

      default_capacity_provider_strategy = {
        weight = 40
        base   = 1
      }
    }
    # Spot instances
    spot = {
      auto_scaling_group_arn         = module.autoscaling["spot"].autoscaling_group_arn
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 5
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 90
      }

      default_capacity_provider_strategy = {
        weight = 60
        base   = 0
      }
    }
  }

  services = local.service_definitions

  # Existing CloudWatch log group
  cluster_settings = var.ecs_cluster_settings

  tags = local.tags
}

# Autoscaling Groups for EC2 instances
module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 6.5"

  for_each = {
    # On-demand instances
    on_demand = {
      instance_type              = var.instance_types["large"]
      use_mixed_instances_policy = false
      user_data                  = <<-EOT
        #!/bin/bash
        cat <<'EOF' >> /etc/ecs/ecs.config
        ECS_CLUSTER=${local.name}
        ECS_LOGLEVEL=debug
        ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(local.tags)}
        ECS_ENABLE_TASK_IAM_ROLE=true
        EOF
      EOT
    }
    # Spot instances
    spot = {
      instance_type              = var.instance_types["medium"]
      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 0
          spot_allocation_strategy                 = "price-capacity-optimized"
        }
        override = [
          {
            instance_type     = var.instance_types["medium"]
            weighted_capacity = "1"
          },
          {
            instance_type     = var.instance_types["large"]
            weighted_capacity = "2"
          },
        ]
      }
      user_data = <<-EOT
        #!/bin/bash
        cat <<'EOF' >> /etc/ecs/ecs.config
        ECS_CLUSTER=${local.name}
        ECS_LOGLEVEL=debug
        ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(local.tags)}
        ECS_ENABLE_TASK_IAM_ROLE=true
        ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
        EOF
      EOT
    }
  }

  name = "${local.name}-${each.key}"

  image_id      = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type = each.value.instance_type

  security_groups = [aws_security_group.ecs_sg.id]
  user_data = base64encode(each.value.user_data)
  ignore_desired_capacity_changes = true

  create_iam_instance_profile = true
  iam_role_name               = "${local.name}-${each.key}"
  iam_role_description        = "ECS role for ${local.name}-${each.key}"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier = module.vpc.public_subnets
  health_check_type   = "EC2"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  # Required for managed_termination_protection = "ENABLED"
  protect_from_scale_in = true

  # Spot instances configuration
  use_mixed_instances_policy = each.value.use_mixed_instances_policy
  mixed_instances_policy     = each.value.mixed_instances_policy

  tags = local.tags
}

# Get latest ECS-optimized AMI
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# Security group for EC2 instances
resource "aws_security_group" "ecs_sg" {
  name        = "${local.name}-ecs-sg"
  description = "Security group for ECS EC2 instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    security_groups = [module.alb.security_group_id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# Service Discovery (if enabled)
resource "aws_service_discovery_http_namespace" "this" {
  count = var.enable_service_discovery ? 1 : 0
  name  = var.service_discovery_namespace
  tags  = local.tags
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${local.name}"
  retention_in_days = 30
  tags              = local.tags
}


# Add Application Auto Scaling
resource "aws_appautoscaling_target" "ecs_target" {
  for_each = {for service in var.services : service.name => service}

  max_capacity = lookup(each.value, "max_capacity", 10)
  min_capacity = lookup(each.value, "min_capacity", 1)
  resource_id        = "service/${local.name}/${each.key}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU-based Auto Scaling
resource "aws_appautoscaling_policy" "ecs_cpu" {
  for_each = {for service in var.services : service.name => service}

  name               = "${each.key}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Memory-based Auto Scaling
resource "aws_appautoscaling_policy" "ecs_memory" {
  for_each = {for service in var.services : service.name => service}

  name               = "${each.key}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}

# Add CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "ecs" {
  dashboard_name = "${local.name}-ecs-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", local.name],
            [".", "MemoryUtilization", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Cluster CPU and Memory Utilization"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EFS", "BurstCreditBalance", "FileSystemId", module.efs.id],
            [".", "StorageBytes", ".", "."],
            [".", "ClientConnections", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EFS Metrics"
        }
      }
    ]
  })
}

# Add Container Insights
resource "aws_ecs_cluster_capacity_providers" "insights" {
  cluster_name = module.ecs.cluster_id
}

# Add Capacity Provider Alarms
resource "aws_cloudwatch_metric_alarm" "capacity_provider_alarm" {
  for_each = toset(["FARGATE", "FARGATE_SPOT"])

  alarm_name          = "${local.name}-${each.key}-capacity"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CapacityProviderReservation"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ${each.key} capacity provider reservation"
  alarm_actions       = var.alarm_actions

  dimensions = {
    ClusterName          = local.name
    CapacityProviderName = each.key
  }
}