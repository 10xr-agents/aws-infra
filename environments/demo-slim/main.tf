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
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.26.0"
    }
  }
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Provider configuration
provider "aws" {
  region = var.aws_region
}

provider "random" {}

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

  # Inbound rule for internet access (for updates, etc.)
  ingress {
    protocol   = "tcp"
    rule_no    = 900
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 901
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 903
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # Outbound rule for internet access (for updates, etc.)
  egress {
    protocol   = "tcp"
    rule_no    = 900
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 901
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

  ingress {
    protocol   = "tcp"
    rule_no    = 201
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 203
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 6379
    to_port    = 6379
  }


  egress {
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

  egress {
    protocol   = "tcp"
    rule_no    = 203
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 6379
    to_port    = 6379
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
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound HTTP traffic"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound HTTP traffic"
  }

  ingress {
    from_port   = 9800
    to_port     = 9800
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound HTTP traffic"
  }

  ingress {
    from_port   = 9600
    to_port     = 9600
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound HTTP traffic"
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound HTTP traffic"
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
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
  count = length(var.services)
  family             = "${var.project_name}-${var.services[count.index].name}"
  network_mode       = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                = var.services[count.index].cpu
  memory             = var.services[count.index].memory
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role[count.index].arn

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
        command = [
          "CMD-SHELL",
          "curl -v -f http://127.0.0.1:${var.services[count.index].port}${var.services[count.index].health_check_path} || exit 1"
        ]
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
  count = length(var.services)
  name            = "${var.project_name}-${var.services[count.index].name}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service[count.index].arn
  desired_count   = var.services[count.index].desired_count

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups = [aws_security_group.ecs_sg.id]
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
  name = "${var.project_name}-${var.services[count.index].name}-task-role"

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
  count = length(var.services)
  role       = aws_iam_role.ecs_task_role[count.index].name
  policy_arn = aws_iam_policy.ecs_task_policy[count.index].arn
}

resource "aws_iam_policy" "ecs_task_policy" {
  count = length(var.services)
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
      [
        for policy_arn in var.services[count.index].additional_policies :
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
    "livekit.${var.domain_name}",
    "livekit-turn.${var.domain_name}",
    "livekit-whip.${var.domain_name}",
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
  security_groups = [aws_security_group.ecs_sg.id, aws_security_group.global_accelerator_endpoint.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "alb-logs"
    enabled = true
  }

  connection_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "alb-logs"
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "service" {
  count = length(var.services)
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
  count = length(var.services)
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
      },
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "globalaccelerator.amazonaws.com"
        },
        "Action" : "s3:PutObject",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.alb_logs.id}/*",
        "Condition" : {
          "StringEquals" : {
            "aws:SourceAccount" : "${data.aws_caller_identity.current.account_id}"
          }
        }
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
  cloud_backup = true
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

# Create a MongoDB Atlas database user with AWS IAM authentication
resource "mongodbatlas_database_user" "aws_iam_user" {
  count = length(var.services)
  project_id         = var.mongodb_atlas_project_id
  auth_database_name = "$external"
  username           = aws_iam_role.ecs_task_role[count.index].arn
  aws_iam_type       = "ROLE"

  roles {
    role_name     = "readWrite"
    database_name = "admin"
  }

  roles {
    role_name     = "dbAdmin"
    database_name = "admin"
  }

  roles {
    role_name     = "readWrite"
    database_name = var.mongodb_database_name
  }

  roles {
    role_name     = "dbAdmin"
    database_name = var.mongodb_database_name
  }


  scopes {
    name = mongodbatlas_cluster.cluster.name
    type = "CLUSTER"
  }
}

# Ensure the ECS task role has the necessary permissions to assume the MongoDB Atlas role
resource "aws_iam_role_policy" "ecs_task_mongodb_policy" {
  count = length(var.services)
  name = "${var.services[count.index].name}-mongodb-policy"
  role = aws_iam_role.ecs_task_role[count.index].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Resource = aws_iam_role.ecs_task_role[count.index].arn
      }
    ]
  })
}

resource "cloudflare_record" "global_accelerator_dns" {
  zone_id = var.cloudflare_zone_id
  name    = var.environment
  content = aws_globalaccelerator_accelerator.main.dns_name
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "api_global_accelerator_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "api.${var.environment}"
  content = aws_globalaccelerator_accelerator.main.dns_name
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "proxy_global_accelerator_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "proxy.${var.environment}"
  content = aws_globalaccelerator_accelerator.main.dns_name
  type    = "CNAME"
  proxied = false
}

# S3 Bucket for external access
resource "aws_s3_bucket" "external_access" {
  bucket        = "${var.project_name}-external-access"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-external-access"
  }
}

# Bucket public access block
resource "aws_s3_bucket_public_access_block" "external_access" {
  bucket = aws_s3_bucket.external_access.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM User for programmatic access
resource "aws_iam_user" "s3_external_access" {
  name = "${var.project_name}-s3-external-access"
}

# IAM Policy for S3 access
resource "aws_iam_policy" "s3_external_access" {
  name        = "${var.project_name}-s3-external-access-policy"
  description = "Policy for external S3 access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.external_access.arn,
          "${aws_s3_bucket.external_access.arn}/*"
        ]
      }
    ]
  })
}

# Attach policy to IAM user
resource "aws_iam_user_policy_attachment" "s3_external_access" {
  user       = aws_iam_user.s3_external_access.name
  policy_arn = aws_iam_policy.s3_external_access.arn
}

# Generate access keys for the IAM user
resource "aws_iam_access_key" "s3_external_access" {
  user = aws_iam_user.s3_external_access.name
}

# Global Accelerator
resource "aws_globalaccelerator_accelerator" "main" {
  name            = "${var.project_name}-accelerator"
  ip_address_type = "IPV4"
  enabled         = true

  attributes {
    flow_logs_enabled   = true
    flow_logs_s3_bucket = aws_s3_bucket.alb_logs.id
    flow_logs_s3_prefix = "global-accelerator-flow-logs"
  }
}

# Global Accelerator Listener
resource "aws_globalaccelerator_listener" "main" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.id
  client_affinity = "NONE"
  protocol        = "TCP"

  port_range {
    from_port = 80
    to_port   = 80
  }

  port_range {
    from_port = 443
    to_port   = 443
  }
}

# Global Accelerator Endpoint Group
resource "aws_globalaccelerator_endpoint_group" "main" {
  listener_arn = aws_globalaccelerator_listener.main.id

  endpoint_configuration {
    endpoint_id = aws_lb.main.arn
    weight      = 100
  }

  health_check_path             = "/"
  health_check_protocol         = "HTTP"
  health_check_port             = 80
  health_check_interval_seconds = 30
  traffic_dial_percentage       = 100
}

resource "aws_security_group" "global_accelerator_endpoint" {
  name        = "${var.project_name}-global-accelerator-endpoint-sg"
  description = "Allow traffic from Global Accelerator to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################################################################################################################
########################################################################################################################
########################################################################################################################
########################################################################################################################

### elastic cache ###

resource "random_password" "redis_auth_token" {
  length  = 64
  special = false
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "livekit" {
  name       = "cache-subnet-${var.project_name}"
  subnet_ids = aws_subnet.public[*].id
}

# ElastiCache Security Group
resource "aws_security_group" "redis" {
  name        = "redis-sg-${var.project_name}"
  description = "Security group for Redis cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    security_groups = [aws_security_group.livekit.id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ElastiCache Redis Cluster
resource "aws_elasticache_cluster" "livekit" {
  cluster_id           = "redis-${var.project_name}"
  engine               = "redis"
  node_type = "cache.t3.micro"  # Adjust as needed
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.redis_auth.name
  engine_version       = "7.0"
  port                 = 6379

  subnet_group_name = aws_elasticache_subnet_group.livekit.name
  security_group_ids = [aws_security_group.redis.id]
}

# ElastiCache Parameter Group for Redis authentication
resource "aws_elasticache_parameter_group" "redis_auth" {
  family = "redis7"
  name   = "redis-auth-${var.project_name}"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon
}


# Private Certificate
# Generate private key
resource "tls_private_key" "livekit" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.livekit.private_key_pem
  email_address   = var.email_address
}


# Create Certificate Signing Request (CSR)
resource "acme_certificate" "livekit" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = "livekit.${var.domain_name}"
  subject_alternative_names = [
    "livekit-turn.${var.domain_name}",
    "livekit-whip.${var.domain_name}",
  ]

  dns_challenge {
    provider = "cloudflare"
    config = {
      CF_API_EMAIL = var.email_address
      CF_API_KEY   = var.cloudflare_api_token
    }
  }
}

resource "aws_acm_certificate" "livekit" {
  private_key        = acme_certificate.livekit.private_key_pem
  certificate_body   = acme_certificate.livekit.certificate_pem
  certificate_chain  = acme_certificate.livekit.issuer_pem

  lifecycle {
    create_before_destroy = true
  }
}

# Cloudflare DNS record for certificate validation
resource "cloudflare_record" "cert_livekit_validation" {
  for_each = {
    for dvo in aws_acm_certificate.livekit.domain_validation_options : dvo.domain_name => {
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

  depends_on = [aws_acm_certificate.livekit]
}

# Certificate Validation
resource "aws_acm_certificate_validation" "livekit" {
  certificate_arn         = aws_acm_certificate.livekit.arn
  validation_record_fqdns = [for record in cloudflare_record.cert_livekit_validation : record.hostname]
}

# S3 bucket for certificate storage
resource "aws_s3_bucket" "cert_bucket" {
  bucket = "livekit-certificates-${var.project_name}"
}

resource "aws_s3_bucket_policy" "cert_bucket_policy" {
  bucket = aws_s3_bucket.cert_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ec2-role-${var.project_name}"
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.cert_bucket.id}/*"
      }
    ]
  })
}

# Creating Lambda Function archive/zip file
data "archive_file" "init" {
  type        = "zip"
  source_dir  = "${path.module}/../../python"
  output_path = "${path.module}/deployment_package.zip"
}

# Lambda function to export ACM cert
resource "aws_lambda_function" "export_cert" {
  filename      = data.archive_file.init.output_path
  function_name = "export_acm_cert_${var.project_name}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "acm_cert_uploader.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.init.output_path)
  runtime       = "python3.8"
  timeout       = 300

  environment {
    variables = {
      S3_BUCKET       = aws_s3_bucket.cert_bucket.id
      CERTIFICATE_ARN = aws_acm_certificate.livekit.arn
    }
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role_${var.project_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_exec_policy" {
  name = "lambda_exec_policy_${var.project_name}"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "acm:ExportCertificate",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_invocation" "invoke_lambda" {
  function_name = aws_lambda_function.export_cert.function_name
  input = jsonencode({
    certificate_arn = aws_acm_certificate.livekit.arn
    s3_bucket       = aws_s3_bucket.cert_bucket.id
  })

  depends_on = [aws_acm_certificate.livekit, aws_lambda_function.export_cert]
}

# LiveKit EC2 Instances
resource "aws_instance" "livekit" {
  count                = 3
  ami                  = data.aws_ami.amazon_linux_2.id
  instance_type        = "t3.2xlarge"
  key_name             = aws_key_pair.livekit.key_name
  vpc_security_group_ids = [aws_security_group.livekit.id]
  subnet_id            = aws_subnet.public[count.index % 2].id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = templatefile("${path.module}/../templates/cloud_init.amazon.yaml.tpl", {
    redis_address      = "${aws_elasticache_cluster.livekit.cache_nodes[0].address}:${aws_elasticache_cluster.livekit.cache_nodes[0].port}"
    redis_username     = "default"
    redis_password     = random_password.redis_auth_token.result
    livekit_domain     = "livekit.${var.domain_name}"
    turn_domain        = "livekit-turn.${var.domain_name}"
    whip_domain        = "livekit-whip.${var.domain_name}"
    api_key            = var.livekit_api_key
    api_secret         = var.livekit_api_secret
    webhook_events_url = "https://proxy.${var.domain_name}/api/v1/live-kit/webhook-events"
    cert_bucket        = aws_s3_bucket.cert_bucket.id
    aws_region         = var.aws_region
  })

  root_block_device {
    volume_size = 32
    volume_type = "gp3"
  }

  tags = {
    Name = "LiveKit-Instance-${count.index + 1}"
  }

  depends_on = [aws_lambda_invocation.invoke_lambda]
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "livekit" {
  name              = "/ec2/livekit"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "caddy" {
  name              = "/ec2/caddy"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "livekit_egress" {
  name              = "/ec2/livekit-egress"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "livekit_ingress" {
  name              = "/ec2/livekit-ingress"
  retention_in_days = 30
}

# IAM role for EC2 instances to access CloudWatch
resource "aws_iam_role" "ec2" {
  name = "ec2-role-${var.project_name}"

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

# Attach CloudWatch policy to the role
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.ec2.name
}

resource "aws_iam_role_policy" "livekit_ec2_policy" {
  name = "livekit-ec2-${var.project_name}-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # CloudWatch Logs
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:GetLogEvents",

          # CloudWatch Metrics
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",

          # EC2 Describe Actions (for self-discovery and debugging)
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeTags",

          # ACM (for certificate management)
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:GetCertificate",

          # Systems Manager (for remote management and debugging)
          "ssm:UpdateInstanceInformation",
          "ssm:ListInstanceAssociations",
          "ssm:DescribeInstanceAssociations",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",

          # S3 (if you decide to use S3 for log storage or config files)
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",

          # SNS (for potential notifications)
          "sns:Publish",

          # SQS (if you use queues for any inter-instance communication)
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",

          # KMS (if you use custom encryption keys)
          "kms:Decrypt",
          "kms:GenerateDataKey",

          # ElastiCache (for describing Redis cluster)
          "elasticache:DescribeCacheClusters",
          "elasticache:ListTagsForResource",

          # Route53 (if instances need to update DNS records)
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets",
          "route53:ListHostedZones",

          # ECS (if you're using containers)
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:DescribeContainerInstances",
          "ecs:ListContainerInstances",

          # ECR (if you're using private Docker repositories)
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",

          # X-Ray (for distributed tracing)
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
          "xray:GetSamplingStatisticSummaries",

          # Systems Manager Parameter Store (for storing config securely)
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",

          # IAM (for describing roles, useful for debugging)
          "iam:GetRole",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create an instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile-${var.project_name}"
  role = aws_iam_role.ec2.name
}

# Security Group for LiveKit
resource "aws_security_group" "livekit" {
  name        = "livekit-sg-${var.project_name}"
  description = "Security group for LiveKit servers"
  vpc_id      = aws_vpc.main.id

  # SSH ingress rule
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Be cautious with this. Ideally, restrict to your IP.
    description = "Allow SSH access"
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 7880
    to_port   = 7880
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 7881
    to_port   = 7881
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 3478
    to_port   = 3478
    protocol  = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 50000
    to_port   = 60000
    protocol  = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 7885
    to_port   = 7885
    protocol  = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 1935
    to_port   = 1935
    protocol  = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 1935
    to_port   = 1935
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Key Pair for SSH access
resource "aws_key_pair" "livekit" {
  key_name = "livekit-key"
  public_key = file("${path.module}/livekit_key.pub")  # Make sure to create this key
}

# Global Accelerator
resource "aws_globalaccelerator_accelerator" "livekit" {
  name            = "${var.project_name}-livekit-accelerator"
  ip_address_type = "IPV4"
  enabled         = true

  attributes {
    flow_logs_enabled   = true
    flow_logs_s3_bucket = aws_s3_bucket.accelerator_logs.bucket
    flow_logs_s3_prefix = "flow-logs/"
  }
}

# S3 bucket for Global Accelerator logs
resource "aws_s3_bucket" "accelerator_logs" {
  bucket = "livekit-accelerator-logs-${data.aws_caller_identity.current.account_id}"
}

# Global Accelerator Listener
locals {
  protocols = ["tcp", "udp"]
}

resource "aws_globalaccelerator_endpoint_group" "livekit" {
  count = length(local.protocols)
  listener_arn = aws_globalaccelerator_listener.livekit[count.index].id

  dynamic "endpoint_configuration" {
    for_each = aws_instance.livekit
    content {
      endpoint_id                    = endpoint_configuration.value.id
      weight                         = 100
      client_ip_preservation_enabled = true
    }
  }

  health_check_path       = "/"
  health_check_port       = 7880
  health_check_protocol   = "HTTP"
  threshold_count         = 3
  traffic_dial_percentage = 100
}

# Global Accelerator Listeners
resource "aws_globalaccelerator_listener" "livekit" {
  count = length(local.protocols)
  accelerator_arn = aws_globalaccelerator_accelerator.livekit.id
  client_affinity = "SOURCE_IP"
  protocol = upper(local.protocols[count.index])

  port_range {
    from_port = 80
    to_port   = 80
  }

  port_range {
    from_port = 443
    to_port   = 443
  }

  port_range {
    from_port = 7880
    to_port   = 7880
  }

  port_range {
    from_port = 7881
    to_port   = 7881
  }

  port_range {
    from_port = 3478
    to_port   = 3478
  }

  port_range {
    from_port = 50000
    to_port   = 60000
  }

  port_range {
    from_port = 1935
    to_port   = 1935
  }

  port_range {
    from_port = 7885
    to_port   = 7885
  }
}

# Global Accelerator DNS entries
resource "cloudflare_record" "livekit_global" {
  zone_id = var.cloudflare_zone_id
  name    = "livekit.${var.environment}"
  content = aws_globalaccelerator_accelerator.livekit.dns_name
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "livekit_turn_global" {
  zone_id = var.cloudflare_zone_id
  name    = "livekit-turn.${var.environment}"
  content = aws_globalaccelerator_accelerator.livekit.dns_name
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "livekit_whip_global" {
  zone_id = var.cloudflare_zone_id
  name    = "livekit-whip.${var.environment}"
  content = aws_globalaccelerator_accelerator.livekit.dns_name
  type    = "CNAME"
  proxied = false
}



