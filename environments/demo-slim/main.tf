terraform {
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "1.18.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.40.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.15.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.65.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
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
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

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

  # Outbound rule for MongoDB Atlas
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.mongodb_atlas_cidr_block
    from_port  = 0
    to_port    = 65535
  }

  # Inbound rule for MongoDB Atlas
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.mongodb_atlas_cidr_block
    from_port  = 0
    to_port    = 65535
  }

  # Outbound rule for internet access (for updates, etc.)
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 201
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Inbound rule for internet access (for ALB)
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 201
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 443
    to_port    = 443
  }

  # Allow ephemeral ports for outbound connections
  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow ephemeral ports for inbound connections
  ingress {
    protocol   = "tcp"
    rule_no    = 301
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow ephemeral ports for outbound connections
  egress {
    protocol   = "udp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow ephemeral ports for inbound connections
  ingress {
    protocol   = "udp"
    rule_no    = 401
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow ephemeral ports for outbound connections
  egress {
    protocol   = "tcp"
    rule_no    = 500
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  # Allow ephemeral ports for inbound connections
  ingress {
    protocol   = "tcp"
    rule_no    = 501
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  # Allow ephemeral ports for outbound connections
  egress {
    protocol   = "udp"
    rule_no    = 600
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  # Allow ephemeral ports for inbound connections
  ingress {
    protocol   = "udp"
    rule_no    = 601
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "${var.project_name}-nacl"
  }
}

# Security Group
# ECS Security Group
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS cluster and ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound HTTP traffic"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound HTTPS traffic"
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.mongodb_atlas_cidr_block]
    description = "Allow inbound traffic from MongoDB Atlas"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-ecs-cluster"

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
          value = "${mongodbatlas_cluster.cluster.connection_strings[0].standard_srv}/${var.mongodb_database_name}?authMechanism=MONGODB-AWS&authSource=$external"
        },
        {
          name  = "MONGO_DB_URI"
          value = "${mongodbatlas_cluster.cluster.connection_strings[0].standard_srv}/${var.mongodb_database_name}?authMechanism=MONGODB-AWS&authSource=$external"
        }
        ], [
        for key, value in var.services[count.index].environment_variables :
        {
          name  = key
          value = value
        }
      ])
      # Include healthCheck only if health_check_path is defined
      healthCheck = length(var.services[count.index].health_check_path) > 0 ? {
        command     = ["CMD-SHELL", "curl -v -f http://127.0.0.1:${var.services[count.index].port}${var.services[count.index].health_check_path} || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 6
        startPeriod = 60
      } : null
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

  depends_on = [aws_lb_listener.https]
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
          "kms:Decrypt",
          "sts:AssumeRole",
          "ssm:SendCommand",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations",
          "ssm:DescribeInstanceInformation"
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

# Public Certificate
# ACM Certificate
resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  subject_alternative_names = [
    "*.${var.domain_name}",
    "services.${var.domain_name}",
    "app.${var.domain_name}",
    "api.${var.domain_name}",
    "proxy.${var.domain_name}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Cloudflare DNS record for certificate validation
resource "cloudflare_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
    if dvo.domain_name != "*.${var.domain_name}"
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  content = each.value.record
  type    = each.value.type
  ttl     = 60
  proxied = false
}

# Certificate Validation
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in cloudflare_record.cert_validation : record.hostname]
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
  port        = var.services[count.index].port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = var.services[count.index].health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 60
    interval            = 300
    matcher             = "200,301,302"
  }
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  depends_on = [aws_acm_certificate_validation.main]
}

resource "aws_lb_listener_rule" "service" {
  count        = length(var.services)
  listener_arn = aws_lb_listener.https.arn

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

# Listener Rule for demo.10xr.co
resource "aws_lb_listener_rule" "demo_subdomain" {
  listener_arn = aws_lb_listener.https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[index(var.services[*].name, "cnvrs-ui")].arn
  }

  condition {
    host_header {
      values = ["${var.environment}.10xr.co"]
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# Listener Rule for api.demo.10xr.co
resource "aws_lb_listener_rule" "api_demo_subdomain" {
  listener_arn = aws_lb_listener.https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[index(var.services[*].name, "cnvrs-srv")].arn
  }

  condition {
    host_header {
      values = ["api.${var.environment}.10xr.co"]
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# Listener Rule for proxy.demo.10xr.co
resource "aws_lb_listener_rule" "proxy_demo_subdomain" {
  listener_arn = aws_lb_listener.https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[index(var.services[*].name, "livkt-prxy")].arn
  }

  condition {
    host_header {
      values = ["proxy.${var.environment}.10xr.co"]
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
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
  name                   = var.project_name
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

resource "mongodbatlas_project_ip_access_list" "ip_access_list" {
  project_id = var.mongodb_atlas_project_id
  cidr_block = var.vpc_cidr
  comment    = "CIDR block for AWS VPC"
}

# MongoDB Atlas IAM Authentication Setup
# Create a MongoDB Atlas federated database instance
# MongoDB Atlas Federated Database Instance
# resource "mongodbatlas_federated_database_instance" "main" {
#   project_id = var.mongodb_atlas_project_id
#   name       = "federated-instance"
#
#   cloud_provider_config {
#     aws {
#       role_id              = aws_iam_role.mongodb_atlas_access.id
#       test_s3_bucket       = aws_s3_bucket.federated_data.id
#     }
#   }
#
#   storage_stores {
#     name         = "atlas-store"
#     cluster_name = mongodbatlas_cluster.cluster.name
#     project_id   = var.mongodb_atlas_project_id
#     provider     = "atlas"
#     read_preference {
#       mode = "secondary"
#     }
#   }
# }

# Create a MongoDB Atlas database user with AWS IAM authentication
resource "mongodbatlas_database_user" "aws_iam_user" {
  count              = length(var.services)
  project_id         = var.mongodb_atlas_project_id
  auth_database_name = "$external"
  username           = aws_iam_role.ecs_task_role[count.index].arn
  aws_iam_type       = "ROLE"

  roles {
    role_name     = "dbAdmin"
    database_name = var.mongodb_database_name
  }

  roles {
    role_name     = "readAnyDatabase"
    database_name = "admin"
  }

  scopes {
    name = mongodbatlas_cluster.cluster.name
    type = "CLUSTER"
  }
}

# eks cluster for livekit
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids         = aws_subnet.public[*].id
    security_group_ids = [aws_security_group.eks_cluster.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSVPCResourceController,
  ]
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# EKS Node Groups
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 2
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEC2ContainerRegistryReadOnly,
  ]
}

# EKS Node IAM Role
resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-eks-node-role"

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

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# IAM Role for LiveKit Pods
resource "aws_iam_role" "livekit_pods_role" {
  name = "${var.project_name}-livekit-pods-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity",
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        },
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:${kubernetes_namespace.livekit.metadata[0].name}:livekit-service-account"
          }
        }
      }
    ]
  })
}


# IAM Policy for LiveKit Pods
resource "aws_iam_policy" "livekit_pods_policy" {
  name        = "${var.project_name}-livekit-pods-policy"
  description = "IAM policy for LiveKit pods to access AWS services"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "elasticache:DescribeReplicationGroups",
          "elasticache:DescribeCacheClusters",
          "elasticache:ListTagsForResource",
          "sts:AssumeRole",
          "sts:AssumeRoleWithWebIdentity",
          "sts:GetCallerIdentity",
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "livekit_pods_policy_attachment" {
  policy_arn = aws_iam_policy.livekit_pods_policy.arn
  role       = aws_iam_role.livekit_pods_role.name
}

# Kubernetes Service Account for LiveKit
resource "kubernetes_service_account" "livekit_service_account" {
  metadata {
    name      = "livekit-service-account"
    namespace = kubernetes_namespace.livekit.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.livekit_pods_role.arn
    }
  }
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-gw-${count.index + 1}"
  }
}

resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  }
}

# Network Load Balancer
resource "aws_lb" "nlb" {
  name               = "${var.project_name}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-nlb"
  }
}

# NLB Target Group for LiveKit
resource "aws_lb_target_group" "livekit" {
  name        = "${var.project_name}-livekit-tg"
  port        = 7880
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    protocol = "HTTP"
    path     = "/health"
    port     = "traffic-port"
  }
}

# NLB Listener for LiveKit
resource "aws_lb_listener" "livekit" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 7880
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.livekit.arn
  }
}

# NLB Listener for HTTP traffic
resource "aws_lb_listener" "nlb_http" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.livekit_http.arn
  }
}

# NLB Listener for HTTPS traffic
resource "aws_acm_certificate" "nlb" {
  domain_name       = var.livekit_domain_name # Single domain for NLB
  validation_method = "DNS"
  subject_alternative_names = [
    "*.${var.livekit_domain_name}",
    var.livekit_turn_domain_name
  ]
  lifecycle {
    create_before_destroy = true
  }
}

# Cloudflare DNS record for certificate validation
resource "cloudflare_record" "nlb_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.nlb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
    if dvo.domain_name != "*.${var.livekit_domain_name}"
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  content = each.value.record
  type    = each.value.type
  ttl     = 60
  proxied = false
}

# Certificate Validation
resource "aws_acm_certificate_validation" "nlb_validation" {
  certificate_arn         = aws_acm_certificate.nlb.arn
  validation_record_fqdns = [for record in cloudflare_record.nlb_cert_validation : record.hostname]
}


resource "aws_lb_listener" "nlb_https" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 443
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.nlb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.livekit_https.arn
  }
}

# NLB Listener for WebRTC traffic
resource "aws_lb_listener" "nlb_webrtc" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 7882
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.livekit_webrtc.arn
  }
}

resource "aws_lb_listener" "livekit_rtmp" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 1935
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.livekit_rtmp.arn
  }
}

resource "aws_lb_listener" "livekit_whip" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 8080
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.livekit_whip.arn
  }
}

# NLB Target Group for HTTP traffic
resource "aws_lb_target_group" "livekit_http" {
  name        = "${var.project_name}-livekit-http"
  port        = 7880
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/health"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
}

# NLB Target Group for HTTPS traffic
resource "aws_lb_target_group" "livekit_https" {
  name        = "${var.project_name}-livekit-https"
  port        = 7880
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "HTTPS"
    path                = "/health"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
}

# NLB Target Group for WebRTC traffic
resource "aws_lb_target_group" "livekit_webrtc" {
  name        = "${var.project_name}-livekit-webrtc"
  port        = 7882
  protocol    = "UDP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = 7880
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
}

resource "aws_lb_target_group" "livekit_rtmp" {
  name        = "${var.project_name}-livekit-rtmp"
  port        = 1935
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
}

resource "aws_lb_target_group" "livekit_whip" {
  name        = "${var.project_name}-livekit-whip"
  port        = 8080
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/health"
    port                = "7888"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
}

# Security Group for EKS
# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow inbound traffic from NLB"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Allow inbound HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound LiveKit traffic"
    from_port   = 7880
    to_port     = 7882
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound LiveKit RTC traffic"
    from_port   = 40000
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound LiveKit TURN traffic"
    from_port   = 3478
    to_port     = 3478
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound LiveKit TURN TLS traffic"
    from_port   = 5349
    to_port     = 5349
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound LiveKit RTMP traffic"
    from_port   = 1935
    to_port     = 1935
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound LiveKit WHIP traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-eks-cluster-sg"
  }
}

# Helm provider
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
      command     = "aws"
    }
  }
}

# Kubernetes provider
provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
    command     = "aws"
  }
}

provider "kubectl" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
    command     = "aws"
  }
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(
      [
        {
          rolearn  = aws_iam_role.eks_nodes.arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups   = ["system:bootstrappers", "system:nodes"]
        },
      ]
    )
    mapUsers = yamlencode(
      [
        {
          userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          username = "root"
          groups   = ["system:masters"]
        },
        {
          userarn  = data.aws_caller_identity.current.arn
          username = "creator"
          groups   = ["system:masters"]
        }
      ]
    )
  }

  depends_on = [aws_iam_role.eks_nodes]
}

# Helm LiveKit provider

# Create a namespace for LiveKit
resource "kubernetes_namespace" "livekit" {
  metadata {
    name = "livekit"
  }
}

resource "random_password" "livekit_api_secret" {
  length  = 256
  special = false
}

# Add CoreDNS add-on
resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "coredns"
  addon_version = "v1.11.3-eksbuild.1"

  depends_on = [
    aws_eks_node_group.main
  ]
}

# Add kube-proxy add-on
resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "kube-proxy"
  addon_version = "v1.30.3-eksbuild.2"

  depends_on = [
    aws_eks_node_group.main
  ]
}

# Add vpc-cni add-on
resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "vpc-cni"
  addon_version = "v1.18.3-eksbuild.2"

  depends_on = [
    aws_eks_node_group.main
  ]
}

# LiveKit Helm Chart
# LiveKit Server Helm Chart
# resource "kubernetes_service" "livekit_udp_range" {
#   metadata {
#     name      = "livekit-udp-range"
#     namespace = kubernetes_namespace.livekit.metadata[0].name
#   }
#
#   spec {
#     selector = {
#       app = "livekit-server"
#     }
#
#     // Dynamic block to iterate over a range of ports
#     dynamic "port" {
#       for_each = range(40000, 65535) # Loop from 40000 to 65535 (60001 is exclusive)
#
#       content {
#         name        = "udp-${port.value}"
#         port        = port.value
#         target_port = port.value
#         protocol    = "UDP"
#       }
#     }
#
#     type                    = "NodePort"
#     external_traffic_policy = "Local"
#   }
# }

resource "helm_release" "livekit_server" {
  name       = "livekit-server"
  repository = "https://helm.livekit.io"
  chart      = "livekit-server"
  namespace  = kubernetes_namespace.livekit.metadata[0].name

  values = [
    templatefile("${path.module}/templates/livekit-server-values.yaml", {
      livekit_api_key          = var.livekit_api_key
      livekit_api_secret       = random_password.livekit_api_secret.result
      livekit_turn_domain_name = var.livekit_turn_domain_name
      aws_redis_cluster        = "${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"
      livekit_redis_username   = "default"
      livekit_redis_password   = random_password.redis_auth_token.result
      livekit_secret_name      = kubernetes_secret.tls_cert.metadata[0].name
      acm_certificate_arn      = aws_acm_certificate.nlb.arn
      livekit_pods_role        = aws_iam_role.livekit_pods_role.arn
    })
  ]

  depends_on = [aws_eks_node_group.main, helm_release.aws_load_balancer_controller]
}

# LiveKit Ingress Helm Chart
resource "helm_release" "livekit_ingress" {
  name       = "livekit-ingress"
  repository = "https://helm.livekit.io"
  chart      = "ingress"
  namespace  = kubernetes_namespace.livekit.metadata[0].name

  values = [
    templatefile("${path.module}/templates/livekit-ingress-values.yaml", {
      livekit_api_key        = var.livekit_api_key
      livekit_api_secret     = random_password.livekit_api_secret.result
      livekit_domain_name    = var.livekit_domain_name
      aws_redis_cluster      = "${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"
      livekit_redis_username = "default"
      livekit_redis_password = random_password.redis_auth_token.result
      livekit_secret_name    = kubernetes_secret.tls_cert.metadata[0].name
      livekit_pods_role      = aws_iam_role.livekit_pods_role.arn
    })
  ]

  depends_on = [helm_release.livekit_server]
}

# LiveKit Egress Helm Chart
resource "helm_release" "livekit_egress" {
  name       = "livekit-egress"
  repository = "https://helm.livekit.io"
  chart      = "egress"
  namespace  = kubernetes_namespace.livekit.metadata[0].name

  values = [
    templatefile("${path.module}/templates/livekit-egress-values.yaml", {
      livekit_api_key        = var.livekit_api_key
      livekit_api_secret     = random_password.livekit_api_secret.result
      livekit_domain_name    = var.livekit_domain_name
      aws_redis_cluster      = "${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"
      livekit_redis_username = "default"
      livekit_redis_password = random_password.redis_auth_token.result
      livekit_secret_name    = kubernetes_secret.tls_cert.metadata[0].name
      livekit_pods_role      = aws_iam_role.livekit_pods_role.arn
    })
  ]

  depends_on = [helm_release.livekit_server]
}

# ALB Ingress Controller
# Helm release for AWS Load Balancer Controller
# AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  namespace        = "kube-system"
  create_namespace = true
  version          = "1.8.2"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.eks_nodes.arn
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = aws_vpc.main.id
  }

  set {
    name  = "enableShield"
    value = "false"
  }

  set {
    name  = "enableWaf"
    value = "false"
  }

  set {
    name  = "enableWafv2"
    value = "false"
  }

  timeout = 900 # 15 minutes

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main,
    kubernetes_config_map.aws_auth
  ]
}

resource "null_resource" "wait_for_alb_controller" {
  triggers = {
    helm_release = helm_release.aws_load_balancer_controller.id
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
    KUBECONFIG_FILE=$(mktemp)
    aws eks get-token --cluster-name ${aws_eks_cluster.main.name} | kubectl config view --raw -o yaml | sed 's/''/''/g' > $KUBECONFIG_FILE
    kubectl --kubeconfig $KUBECONFIG_FILE wait --for=condition=available --timeout=900s deployment/aws-load-balancer-controller -n kube-system
    rm $KUBECONFIG_FILE
  EOT
  }

  depends_on = [helm_release.aws_load_balancer_controller]
}

# Install Metrics Server using Helm
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.11.0" # Ensure this version is compatible with your Kubernetes version

  set {
    name  = "args[0]"
    value = "--kubelet-preferred-address-types=InternalIP"
  }

  set {
    name  = "args[1]"
    value = "--kubelet-insecure-tls"
  }

  depends_on = [aws_eks_cluster.main]
}

# IAM Policy for ALB Ingress Controller
resource "aws_iam_policy" "alb_ingress_controller" {
  name        = "${var.project_name}-alb-ingress-controller"
  path        = "/"
  description = "IAM policy for ALB Ingress Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = "arn:aws:ec2:*:*:security-group/*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "CreateSecurityGroup"
          }
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "arn:aws:ec2:*:*:security-group/*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ]
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]
        Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the ALB Ingress Controller policy to the EKS node role
resource "aws_iam_role_policy_attachment" "alb_ingress_controller" {
  policy_arn = aws_iam_policy.alb_ingress_controller.arn
  role       = aws_iam_role.eks_nodes.name
}

# Create an ElastiCache subnet group
resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-${var.project_name}-subnet-group"
  subnet_ids = aws_subnet.public[*].id
}

# If you don't already have a CloudWatch log group, create one
resource "aws_cloudwatch_log_group" "redis_logs" {
  name              = "/aws/elasticache/${var.project_name}-redis"
  retention_in_days = 30  # Adjust retention period as needed
}


# Redis Security Group
resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Security group for Redis cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
    description     = "Allow inbound Redis traffic from EKS cluster"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

# Add this rule to allow EKS to access Redis
resource "aws_security_group_rule" "eks_to_redis" {
  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.redis.id
  security_group_id        = aws_security_group.eks_cluster.id
  description              = "Allow outbound traffic from EKS to Redis"
}

# Create the ElastiCache Redis cluster
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "redis-${var.project_name}"
  description                = "Redis cluster for ${var.project_name}"
  node_type                  = "cache.t3.micro"
  num_cache_clusters         = 2
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  automatic_failover_enabled = true

  engine               = "redis"
  engine_version       = "7.1"
  parameter_group_name = "default.redis7"

  transit_encryption_enabled = false
  auth_token                 = random_password.redis_auth_token.result

  # Enable logging
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_logs.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_logs.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  # Important: Apply changes immediately
  apply_immediately = true
}

resource "aws_vpc_endpoint" "elasticache" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.elasticache"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.eks_cluster.id]
  subnet_ids         = aws_subnet.public[*].id

  private_dns_enabled = true
}

# Generate a random auth token for Redis
resource "random_password" "redis_auth_token" {
  length  = 32
  special = false
}

# Create an IAM role for EKS pods to access Redis
resource "aws_iam_role" "eks_redis_access" {
  name = "${var.project_name}-eks-redis-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# Create an IAM policy for Redis access
resource "aws_iam_policy" "redis_access" {
  name        = "${var.project_name}-redis-access-policy"
  description = "IAM policy for Redis access from EKS pods"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticache:DescribeReplicationGroups",
          "elasticache:DescribeCacheClusters",
          "elasticache:ListTagsForResource"
        ]
        Resource = aws_elasticache_replication_group.redis.arn
      }
    ]
  })
}

# Attach the Redis access policy to the EKS Redis access role
resource "aws_iam_role_policy_attachment" "eks_redis_access" {
  policy_arn = aws_iam_policy.redis_access.arn
  role       = aws_iam_role.eks_redis_access.name
}

# Update the EKS node role to allow assuming the Redis access role
resource "aws_iam_role_policy_attachment" "eks_node_redis_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

# Create a Kubernetes secret for Redis credentials
resource "kubernetes_secret" "redis_credentials" {
  metadata {
    name      = "redis-credentials"
    namespace = kubernetes_namespace.livekit.metadata[0].name
  }

  data = {
    host     = aws_elasticache_replication_group.redis.primary_endpoint_address
    port     = "6379"
    password = random_password.redis_auth_token.result
  }
}

# Generate a private key
resource "tls_private_key" "cert_private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create a self-signed certificate
resource "tls_self_signed_cert" "cert" {
  private_key_pem = tls_private_key.cert_private_key.private_key_pem

  subject {
    common_name  = "*.${var.domain_name}"
    organization = var.project_name
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Create a Kubernetes secret for the certificate
resource "kubernetes_secret" "tls_cert" {
  metadata {
    name      = "${var.project_name}-tls-cert"
    namespace = kubernetes_namespace.livekit.metadata[0].name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.cert.cert_pem
    "tls.key" = tls_private_key.cert_private_key.private_key_pem
  }
}

# ELB for ALB & NLB

# Cloudflare DNS record for ALB
resource "cloudflare_record" "alb_dns" {
  zone_id = var.cloudflare_zone_id
  name    = var.environment
  content = aws_lb.main.dns_name
  type    = "CNAME"
  proxied = false
}

# Cloudflare DNS record for ALB
resource "cloudflare_record" "api_alb_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "api.${var.environment}"
  content = aws_lb.main.dns_name
  type    = "CNAME"
  proxied = false
}

# Cloudflare DNS record for ALB
resource "cloudflare_record" "proxy_alb_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "proxy.${var.environment}"
  content = aws_lb.main.dns_name
  type    = "CNAME"
  proxied = false
}

# Cloudflare DNS record for NLB
resource "cloudflare_record" "nlb_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "livekit.${var.environment}"
  content = aws_lb.nlb.dns_name
  type    = "CNAME"
  proxied = false
}