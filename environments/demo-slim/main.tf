terraform {
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "1.18.1"
    }
  }
}

# Provider configuration
provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Subnets
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  route {
    cidr_block                = var.mongodb_atlas_cidr_block
    vpc_peering_connection_id = mongodbatlas_network_peering.peering.connection_id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Network ACL
resource "aws_network_acl" "main" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project_name}-nacl"
  }
}

# Security Group
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS cluster and ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Allow internal communication between services"
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Allow internal communication between services"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  dynamic "setting" {
    for_each = var.ecs_cluster_settings
    content {
      name  = setting.key
      value = setting.value
    }
  }
}

# ECS Task Definitions
resource "aws_ecs_task_definition" "service" {
  count                    = length(var.services)
  family                   = "${var.project_name}-${var.services[count.index].name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.services[count.index].cpu
  memory                   = var.services[count.index].memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role[count.index].arn

  container_definitions = jsonencode([
    {
      name  = var.services[count.index].name
      image = var.services[count.index].ecr_repo
      portMappings = [
        {
          containerPort = var.services[count.index].port
          hostPort      = var.services[count.index].port
        }
      ]
      environment = concat([
        {
          name  = "SPRING_DATA_MONGODB_URI"
          value = mongodbatlas_cluster.cluster.mongo_uri_with_options
        }
        ], [
        for key, value in var.services[count.index].environment_variables :
        {
          name  = key
          value = value
        }
      ])
      secrets = [
        for key, value in var.services[count.index].secrets :
        {
          name      = key
          valueFrom = value
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = var.services[count.index].name
        }
      }
    }
  ])
}

# ECS Services
resource "aws_ecs_service" "service" {
  count           = length(var.services)
  name            = "${var.project_name}-${var.services[count.index].name}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service[count.index].arn
  desired_count   = var.services[count.index].desired_count

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.service[count.index].arn
    container_name   = var.services[count.index].name
    container_port   = var.services[count.index].port
  }

  dynamic "capacity_provider_strategy" {
    for_each = var.services[count.index].capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = capacity_provider_strategy.value.base
    }
  }

  dynamic "service_registries" {
    for_each = var.enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.service[count.index].arn
    }
  }

  enable_execute_command = var.enable_ecs_exec

  depends_on = [aws_lb_listener.front_end]
}

# Service Discovery
resource "aws_service_discovery_private_dns_namespace" "main" {
  count       = var.enable_service_discovery ? 1 : 0
  name        = var.service_discovery_namespace
  description = "Service Discovery namespace for ECS services"
  vpc         = aws_vpc.main.id
}

resource "aws_service_discovery_service" "service" {
  count = var.enable_service_discovery ? length(var.services) : 0
  name  = var.services[count.index].name

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
}

# IAM Roles
resource "aws_iam_role" "ecs_task_role" {
  count = length(var.services)
  name  = "${var.project_name}-${var.services[count.index].name}-task-role"

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
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  count      = length(var.services)
  role       = aws_iam_role.ecs_task_role[count.index].name
  policy_arn = aws_iam_policy.ecs_task_policy[count.index].arn
}

resource "aws_iam_policy" "ecs_task_policy" {
  count       = length(var.services)
  name        = "${var.project_name}-${var.services[count.index].name}-task-policy"
  path        = "/"
  description = "IAM policy for ECS task"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
      ],
      [for policy_arn in var.services[count.index].additional_policies :
        {
          Effect   = "Allow"
          Action   = "*"
          Resource = "*"
        }
    ])
  })
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "alb-logs"
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "service" {
  count       = length(var.services)
  name        = "${var.project_name}-tg-${var.services[count.index].name}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 60
    interval            = 300
    matcher             = "200,301,302"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "service" {
  count        = length(var.services)
  listener_arn = aws_lb_listener.front_end.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[count.index].arn
  }

  condition {
    path_pattern {
      values = ["/${var.services[count.index].name}*"]
    }
  }
}

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# Auto Scaling Groups
resource "aws_autoscaling_group" "ecs_asg" {
  for_each = toset(["on_demand", "spot"])

  name                = "${var.project_name}-asg-${each.key}"
  vpc_zone_identifier = aws_subnet.public[*].id
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity

  launch_template {
    id      = each.key == "on_demand" ? aws_launch_template.on_demand.id : aws_launch_template.spot.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  protect_from_scale_in = true
}

# Launch Templates
resource "aws_launch_template" "on_demand" {
  name_prefix   = "${var.project_name}-lt-on-demand"
  image_id      = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type = var.instance_types["medium"] # Default to medium, can be adjusted

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ecs_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-ecs-instance-on-demand"
    }
  }
}

resource "aws_launch_template" "spot" {
  name_prefix   = "${var.project_name}-lt-spot"
  image_id      = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type = var.instance_types["medium"] # Default to medium, can be adjusted

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ecs_sg.id]

  instance_market_options {
    market_type = "spot"
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-ecs-instance-spot"
    }
  }
}

# ECS Capacity Providers
resource "aws_ecs_capacity_provider" "ec2" {
  for_each = toset(["on_demand", "spot"])

  name = "${var.project_name}-${each.key}"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg[each.key].arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

# Update ECS Cluster to use both EC2 and Fargate capacity providers
resource "aws_ecs_cluster_capacity_providers" "cluster_capacity_providers" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = concat(
    ["FARGATE", "FARGATE_SPOT"],
    [for cp in aws_ecs_capacity_provider.ec2 : cp.name]
  )

  default_capacity_provider_strategy {
    capacity_provider = var.capacity_provider_strategy[0].capacity_provider
    weight            = var.capacity_provider_strategy[0].weight
    base              = var.capacity_provider_strategy[0].base
  }
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role"

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
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Instance Role
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.project_name}-ecs-instance-role"

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
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# ECS Instance Profile
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.project_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 30
}

# S3 Bucket for ALB Logs
resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.project_name}-alb-logs"

  force_destroy = true
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = ["s3:GetBucketLocation", "s3:ListBucket", "s3:GetObject"]
        Resource = [
          aws_s3_bucket.alb_logs.arn,
          "${aws_s3_bucket.alb_logs.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_cloudwatch_log_resource_policy" "root_access" {
  policy_name = "${var.project_name}-root-access-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.account_id
        }
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ecs_logs.arn}:*"
      }
    ]
  })
}

data "aws_elb_service_account" "main" {}

# Data source to get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

#mongo atlas setup

provider "mongodbatlas" {
  public_key  = var.mongodb_atlas_public_key
  private_key = var.mongodb_atlas_private_key
}

resource "mongodbatlas_cluster" "cluster" {
  project_id             = var.mongodb_atlas_project_id
  name                   = "10xr-demo"
  mongo_db_major_version = "7.0"
  cluster_type           = "REPLICASET"
  replication_specs {
    num_shards = 1
    regions_config {
      region_name     = var.mongodb_atlas_region
      electable_nodes = 3
      priority        = 7
      read_only_nodes = 0
    }
  }
  cloud_backup                 = true
  auto_scaling_disk_gb_enabled = true

  # Provider Settings "block"
  provider_name               = "AWS"
  provider_instance_size_name = "M30"
}

# VPC Peering
resource "mongodbatlas_network_peering" "peering" {
  project_id             = var.mongodb_atlas_project_id
  container_id           = mongodbatlas_cluster.cluster.container_id
  provider_name          = "AWS"
  accepter_region_name   = var.mongodb_atlas_region
  route_table_cidr_block = var.vpc_cidr
  vpc_id                 = aws_vpc.main.id
  aws_account_id         = data.aws_caller_identity.current.account_id
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = mongodbatlas_network_peering.peering.connection_id
  auto_accept               = true
}

# resource "mongodbatlas_project_ip_access_list" "ip_access_list" {
#   project_id = var.mongodb_atlas_project_id
#   cidr_block = var.vpc_cidr
#   comment    = "CIDR block for AWS VPC"
# }

resource "aws_security_group_rule" "allow_mongodb_atlas" {
  type              = "egress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  cidr_blocks       = [var.mongodb_atlas_cidr_block]
  security_group_id = aws_security_group.ecs_sg.id
}