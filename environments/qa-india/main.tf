# environments/qa-india/main.tf

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.99.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.40.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

locals {
  name_prefix = "${var.cluster_name}-${var.environment}"
}

# VPC with a public subnet
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# Public Subnets across multiple AZs
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-public-subnet-${count.index + 1}"
  })
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

# Route Table Association for Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Network ACL for Public Subnets
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  # Inbound rules
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 8080
    to_port    = 8080
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 9000
    to_port    = 9000
  }

  # Allow ephemeral ports for return traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 150
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all UDP traffic (for potential LiveKit WebRTC)
  ingress {
    protocol   = "udp"
    rule_no    = 160
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "icmp"
    rule_no    = 170
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Outbound rules
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-public-nacl"
  })
}

# Security Group for EC2 instance
resource "aws_security_group" "ec2" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "Security group for LiveKit proxy EC2 instance"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr_blocks
    description = "SSH access"
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # Alternative HTTP port (8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Alternative HTTP access"
  }

  # LiveKit proxy port
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "LiveKit proxy port"
  }

  # WebRTC UDP ports for LiveKit (if needed)
  ingress {
    from_port   = 50000
    to_port     = 60000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "WebRTC UDP ports for LiveKit"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-ec2-sg"
  })
}

# IAM Role for EC2 to access ECR
resource "aws_iam_role" "ec2_ecr_role" {
  name = "${local.name_prefix}-ec2-ecr-role"

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

# Create IAM policy for cross-region ECR access
resource "aws_iam_policy" "ecr_cross_region_policy" {
  name        = "${local.name_prefix}-ecr-cross-region-policy"
  description = "Policy for EC2 instance to access ECR in us-east-1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # ECR permissions for cross-region access
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages",

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

          # Systems Manager (for remote management and debugging)
          "ssm:UpdateInstanceInformation",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:DescribeInstanceInformation",
          "ssm:DescribeInstanceAssociations",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach ECR policy to the IAM role
resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Attach SSM policy for debugging
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach custom ECR policy to the IAM role
resource "aws_iam_role_policy_attachment" "ecr_custom_policy_attachment" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = aws_iam_policy.ecr_cross_region_policy.arn
}

# Create instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_ecr_role.name
}

# SSH Key Pair
resource "aws_key_pair" "ec2" {
  key_name   = "${local.name_prefix}-key"
  public_key = var.ssh_public_key

  tags = var.tags
}

# Elastic IP for EC2 instance (must be created before instance for cloud-init)
resource "aws_eip" "livekit_proxy" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-eip"
  })
}

# CloudWatch Log Group for LiveKit logs
resource "aws_cloudwatch_log_group" "livekit" {
  name              = "/aws/ec2/livekit/${var.cluster_name}-${var.environment}"
  retention_in_days = 7

  tags = var.tags
}

# EC2 Instance
resource "aws_instance" "livekit_proxy" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  key_name               = aws_key_pair.ec2.key_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # Use cloud-init configuration with improved template
  user_data_base64 = base64gzip(templatefile("${path.module}/livekit-cloud-init.yml", {
    domain_name = var.domain_name
    elastic_ip  = aws_eip.livekit_proxy.public_ip
  }))

  # EBS volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.ec2_root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = merge(var.tags, {
      Name = "${local.name_prefix}-root-volume"
    })
  }

  # Enhanced metadata options for better security
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  monitoring = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-livekit-proxy"
  })

  # Ensure EIP is created first
  depends_on = [
    aws_eip.livekit_proxy,
    aws_cloudwatch_log_group.livekit
  ]

  lifecycle {
    ignore_changes = [
      ami,
      user_data_base64
    ]
  }
}

resource "aws_eip_association" "livekit_proxy_eip_association" {
  instance_id   = aws_instance.livekit_proxy.id
  allocation_id = aws_eip.livekit_proxy.id
}

# Cloudflare DNS record
resource "cloudflare_record" "livekit_proxy_cname" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  value   = aws_eip.livekit_proxy.public_ip
  type    = "A"
  proxied = false
  ttl     = 300

  comment = "LiveKit Proxy - QA India Environment"
}