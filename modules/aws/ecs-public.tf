locals {
  name = "${var.project_name}-${var.environment}"

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
          readOnly     = false
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

      health_check = length(service.health_check_path) > 0 ? {
        command = ["CMD-SHELL", "curl -f http://localhost:${service.port}${service.health_check_path} || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 6
        startPeriod = 60
      } : null

      enable_cloudwatch_logging = true
      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = service.name
        }
      }
    }
  }

  service_definitions = {
    for service in var.services : service.name => {
      cpu    = service.cpu
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
          target_group_arn = aws_lb_target_group.service[index(var.services[*].name, service.name)].arn
          container_name   = service.name
          container_port   = service.port
        }
      }

      subnet_ids = module.vpc.private_subnets
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
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
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
            file_system_id = aws_efs_file_system.ecs_storage.id
            root_directory = "/"
            transit_encryption = "ENABLED"
            authorization_config = {
              access_point_id = aws_efs_access_point.service[index(var.services[*].name, service.name)].id
              iam            = "ENABLED"
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
  version = "~> 5.0"

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

  security_groups                 = [aws_security_group.ecs_sg.id]
  user_data                      = base64encode(each.value.user_data)
  ignore_desired_capacity_changes = true

  create_iam_instance_profile = true
  iam_role_name              = "${local.name}-${each.key}"
  iam_role_description       = "ECS role for ${local.name}-${each.key}"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier = module.vpc.private_subnets
  health_check_type   = "EC2"
  min_size           = var.asg_min_size
  max_size           = var.asg_max_size
  desired_capacity   = var.asg_desired_capacity

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
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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