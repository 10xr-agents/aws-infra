# modules/ecs-gpu/main.tf - Fixed version

locals {
  name_prefix = "${var.cluster_name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      WorkloadType = "GPU"
    }
  )

  # Process services configuration with GPU-specific defaults
  services_config = { for name, config in var.services : name => merge(
    config,
    {
      # Add computed values
      task_role_name       = "${local.name_prefix}-${name}-task-role"
      task_exec_role_name  = "${local.name_prefix}-${name}-exec-role"
      log_group_name       = "/ecs/${local.name_prefix}/${name}"
      security_group_name  = "${local.name_prefix}-${name}-sg"
      target_group_name    = "${substr(local.name_prefix, 0, 15)}-${substr(name, 0, 10)}-tg"
    }
  )}

  # GPU-optimized container definitions
  container_definitions = { for name, config in local.services_config : name =>
    jsonencode([
      {
        name  = name
        image = "${config.image}:${lookup(config, "image_tag", "latest")}"

        # Resource allocation with GPU support
        cpu    = config.cpu
        memory = config.memory
        
        # GPU resource requirements
        resourceRequirements = config.gpu_count > 0 ? [
          {
            type  = "GPU"
            value = tostring(config.gpu_count)
          }
        ] : []

        # Essential container
        essential = true

        # Port mappings
        portMappings = [
          {
            containerPort = config.port
            protocol      = "tcp"
          }
        ]

        # Environment variables - REMOVED GPU-specific variables that are auto-set by ECS
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
            # REMOVED: NVIDIA_VISIBLE_DEVICES and NVIDIA_DRIVER_CAPABILITIES
            # These are automatically set by ECS for GPU tasks
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

        # Health check configuration
        healthCheck = lookup(config, "container_health_check", null) != null ? {
          command = [
            "CMD-SHELL",
            lookup(config.container_health_check, "command", "curl -f http://localhost:${config.port}/health || exit 1")
          ]
          interval    = lookup(config.container_health_check, "interval", 30)
          timeout     = lookup(config.container_health_check, "timeout", 5)
          retries     = lookup(config.container_health_check, "retries", 3)
          startPeriod = lookup(config.container_health_check, "start_period", 120) # Longer for GPU startup
        } : null

        # Working directory
        workingDirectory = lookup(config, "working_directory", null)

        # User
        user = lookup(config, "user", null)

        # Docker labels with GPU info
        dockerLabels = merge(
          {
            "service"      = name
            "environment"  = var.environment
            "cluster"      = local.name_prefix
            "gpu-enabled"  = tostring(config.gpu_count > 0)
            "gpu-count"    = tostring(config.gpu_count)
          },
          lookup(config, "docker_labels", {})
        )

        # Ulimits for GPU workloads - check for duplicates
        ulimits = length(lookup(config, "ulimits", [])) > 0 ? [
          for ulimit in config.ulimits : {
            name      = ulimit.name
            softLimit = ulimit.soft_limit
            hardLimit = ulimit.hard_limit
          }
        ] : [
          {
            name      = "memlock"
            softLimit = -1
            hardLimit = -1
          }
        ]
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
data "aws_vpc" "main" {
  id = var.vpc_id
}

################################################################################
# ECS Cluster with GPU Support
################################################################################

resource "aws_ecs_cluster" "gpu" {
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
  tags              = local.common_tags
}

################################################################################
# EC2 Launch Template for P5 Instances
################################################################################

data "aws_ami" "ecs_gpu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-gpu-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "ecs_gpu" {
  name_prefix   = "${local.name_prefix}-"
  image_id      = data.aws_ami.ecs_gpu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.ecs_instances.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Update system
    yum update -y
    
    # Configure ECS agent
    echo ECS_CLUSTER=${aws_ecs_cluster.gpu.name} >> /etc/ecs/ecs.config
    echo ECS_ENABLE_GPU_SUPPORT=true >> /etc/ecs/ecs.config
    echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
    
    # Configure Docker daemon for GPU support
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'DOCKER_EOF'
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    },
    "log-driver": "awslogs",
    "log-opts": {
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-group": "${aws_cloudwatch_log_group.cluster.name}"
    }
}
DOCKER_EOF
    
    # Install NVIDIA drivers and container toolkit
    yum install -y nvidia-driver-latest-dkms
    yum install -y nvidia-container-toolkit
    
    # Configure nvidia-container-toolkit
    nvidia-ctk runtime configure --runtime=docker
    
    # Restart services
    systemctl restart docker
    systemctl restart ecs
    
    # Enable services
    systemctl enable docker
    systemctl enable ecs
    
    # Log GPU information
    nvidia-smi > /var/log/gpu-info.log 2>&1
    EOF
  )

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.root_volume_size
      volume_type = "gp3"
      encrypted   = true
    }
  }

  # GPU-specific settings
  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-ecs-instance"
    })
  }

  tags = local.common_tags
}

################################################################################
# Auto Scaling Group for P5 Instances - FIXED
################################################################################

resource "aws_autoscaling_group" "ecs_gpu" {
  name                = "${local.name_prefix}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = []
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # Use mixed instances for cost optimization if needed
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ecs_gpu.id
        version            = "$Latest"
      }

      # Allow different P5 instance types if available
      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type = override.value
        }
      }
    }

    instances_distribution {
      on_demand_base_capacity                  = var.on_demand_base_capacity
      on_demand_percentage_above_base_capacity = var.on_demand_percentage
      # FIXED: Use valid spot allocation strategy
      spot_allocation_strategy                 = "capacity-optimized"
    }
  }

  # Instance refresh for updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  depends_on = [aws_ecs_cluster.gpu]
}

################################################################################
# ECS Capacity Provider
################################################################################

resource "aws_ecs_capacity_provider" "gpu" {
  name = "${local.name_prefix}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_gpu.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = var.target_capacity
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 3
    }
  }

  tags = local.common_tags
}

resource "aws_ecs_cluster_capacity_providers" "gpu" {
  cluster_name = aws_ecs_cluster.gpu.name

  capacity_providers = [aws_ecs_capacity_provider.gpu.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.gpu.name
  }

  depends_on = [aws_ecs_capacity_provider.gpu]
}

################################################################################
# IAM Roles and Policies
################################################################################

# ECS Instance Role
resource "aws_iam_role" "ecs_instance" {
  name = "${local.name_prefix}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_instance_profile" "ecs_instance" {
  name = "${local.name_prefix}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance.name
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Additional policy for GPU instances
resource "aws_iam_role_policy" "ecs_instance_gpu" {
  name = "${local.name_prefix}-ecs-instance-gpu-policy"
  role = aws_iam_role.ecs_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Task Execution Role
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

resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  for_each = local.services_config

  role       = aws_iam_role.task_execution_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Role
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

################################################################################
# Security Groups
################################################################################

resource "aws_security_group" "ecs_instances" {
  name        = "${local.name_prefix}-ecs-instances"
  description = "Security group for ECS GPU instances"
  vpc_id      = var.vpc_id

  # Allow inbound traffic from ALB
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = var.alb_security_group_ids
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecs-instances"
  })
}

resource "aws_security_group" "ecs_service" {
  for_each = local.services_config

  name        = each.value.security_group_name
  description = "Security group for ECS service ${each.key}"
  vpc_id      = var.vpc_id

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
  network_mode             = "bridge"  # Required for GPU instances
  requires_compatibilities = ["EC2"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.task_execution_role[each.key].arn
  task_role_arn           = aws_iam_role.task_role[each.key].arn

  container_definitions = local.container_definitions[each.key]

  tags = merge(local.common_tags, { Service = each.key })
}

################################################################################
# ECS Services
################################################################################

resource "aws_ecs_service" "service" {
  for_each = local.services_config

  name            = each.key
  cluster         = aws_ecs_cluster.gpu.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  desired_count   = each.value.desired_count

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.gpu.name
    weight           = 100
    base             = 1
  }

  # Placement constraints for GPU instances
  dynamic "placement_constraints" {
    for_each = each.value.gpu_count > 0 ? [1] : []
    content {
      type       = "memberOf"
      expression = "attribute:ecs.instance-type =~ p5.*"
    }
  }

  # Load balancer configuration if enabled
  dynamic "load_balancer" {
    for_each = lookup(each.value, "enable_load_balancer", true) && var.create_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.service[each.key].arn
      container_name   = each.key
      container_port   = each.value.port
    }
  }

  depends_on = [aws_ecs_cluster_capacity_providers.gpu]

  tags = merge(local.common_tags, { Service = each.key })
}

################################################################################
# ALB Target Groups (if ALB is enabled)
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
  target_type = "instance"

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