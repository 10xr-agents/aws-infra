# modules/ecs/main.tf

/**
 * # ECS Module for LiveKit Deployment
 *
 * This module creates an Amazon ECS cluster with support for both Fargate and EC2 capacity providers.
 * It's designed to run containerized LiveKit components with proper networking and scaling capabilities.
 *
 * The module creates:
 * - ECS cluster with Container Insights
 * - Capacity providers (Fargate, Fargate Spot, and/or EC2)
 * - Auto Scaling Group for EC2 instances (if enabled)
 * - Security groups for ECS tasks
 * - IAM roles and policies
 */

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )
}

# Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = concat(
    var.enable_fargate ? ["FARGATE"] : [],
    var.enable_fargate_spot ? ["FARGATE_SPOT"] : [],
    var.enable_ec2 ? [aws_ecs_capacity_provider.ec2[0].name] : []
  )

  dynamic "default_capacity_provider_strategy" {
    for_each = var.enable_fargate ? [1] : []
    content {
      capacity_provider = "FARGATE"
      weight           = 1
      base             = 1
    }
  }
}

# EC2 Capacity Provider (if enabled)
resource "aws_ecs_capacity_provider" "ec2" {
  count = var.enable_ec2 ? 1 : 0

  name = "${var.cluster_name}-ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs[0].arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 10
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-ec2-capacity-provider"
    }
  )
}

# Launch Template for EC2 instances (if EC2 is enabled)
resource "aws_launch_template" "ecs" {
  count = var.enable_ec2 ? 1 : 0

  name_prefix   = "${var.cluster_name}-ecs-"
  image_id      = var.ec2_ami_id != "" ? var.ec2_ami_id : data.aws_ami.ecs_optimized[0].id
  instance_type = var.ec2_instance_types[0]

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_instance[0].arn
  }

  vpc_security_group_ids = [aws_security_group.ecs_instances[0].id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
    echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
    echo ECS_ENABLE_SPOT_INSTANCE_DRAINING=true >> /etc/ecs/ecs.config
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.cluster_name}-ecs-instance"
      }
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for EC2 instances (if EC2 is enabled)
resource "aws_autoscaling_group" "ecs" {
  count = var.enable_ec2 ? 1 : 0

  name                = "${var.cluster_name}-ecs-asg"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = var.ec2_asg_min_size
  max_size            = var.ec2_asg_max_size
  desired_capacity    = var.ec2_asg_desired_capacity

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ecs[0].id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = var.ec2_instance_types
        content {
          instance_type = override.value
        }
      }
    }

    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = var.ec2_on_demand_percentage
      spot_allocation_strategy                 = "capacity-optimized"
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Data source for ECS optimized AMI
data "aws_ami" "ecs_optimized" {
  count = var.enable_ec2 && var.ec2_ami_id == "" ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# Security Group for ECS instances (if EC2 is enabled)
resource "aws_security_group" "ecs_instances" {
  count = var.enable_ec2 ? 1 : 0

  name        = "${var.cluster_name}-ecs-instances"
  description = "Security group for ECS instances"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-ecs-instances-sg"
    }
  )
}

# Security Group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.cluster_name}-ecs-tasks"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-ecs-tasks-sg"
    }
  )
}

# Allow communication between ECS instances and tasks
resource "aws_security_group_rule" "ecs_instances_from_tasks" {
  count = var.enable_ec2 ? 1 : 0

  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_tasks.id
  security_group_id        = aws_security_group.ecs_instances[0].id
}

# IAM role for ECS instances (if EC2 is enabled)
resource "aws_iam_role" "ecs_instance" {
  count = var.enable_ec2 ? 1 : 0

  name = "${var.cluster_name}-ecs-instance-role"

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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  count = var.enable_ec2 ? 1 : 0

  role       = aws_iam_role.ecs_instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ssm" {
  count = var.enable_ec2 ? 1 : 0

  role       = aws_iam_role.ecs_instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_instance" {
  count = var.enable_ec2 ? 1 : 0

  name = "${var.cluster_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance[0].name
}

# IAM role for ECS task execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.cluster_name}-ecs-task-execution-role"

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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for pulling images from ECR
resource "aws_iam_role_policy" "ecs_task_execution_ecr" {
  name = "${var.cluster_name}-ecs-task-execution-ecr"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}