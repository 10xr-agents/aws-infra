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

  # Allow ICMP
  ingress {
    protocol   = "icmp"
    rule_no    = 170
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    icmp_type  = -1
    icmp_code  = -1
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
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
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

# EC2 Instance
resource "aws_instance" "livekit_proxy" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  key_name               = aws_key_pair.ec2.key_name
  subnet_id              = aws_subnet.public[0].id  # Use the first subnet
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # User data script to install Docker and run LiveKit proxy
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    # Log everything
    exec > >(tee /var/log/user-data.log) 2>&1
    echo "Starting user data script at $(date)"

    # Update the system
    apt-get update
    apt-get upgrade -y

    # Install Docker
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl enable docker
    systemctl start docker

    # Add ubuntu user to docker group
    usermod -aG docker ubuntu

    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Install AWS CLI
    apt-get install -y awscli

    # Create directory for LiveKit proxy
    mkdir -p /opt/livekit-proxy
    chown ubuntu:ubuntu /opt/livekit-proxy

    # Create docker-compose.yml file
    cat > /opt/livekit-proxy/docker-compose.yml <<EOL
    version: '3.8'
    services:
      livekit-proxy:
        image: 761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/livekit-proxy-service:0.1.0
        ports:
          - "9000:9000"
          - "8080:8080"
        environment:
          - SERVICE_PORT=9000
          - REGION=india
        restart: always
        healthcheck:
          test: ["CMD", "curl", "-f", "http://localhost:9000/api/v1/management/health", "||", "curl", "-f", "http://localhost:9000/health", "||", "curl", "-f", "http://localhost:9000/"]
          interval: 30s
          timeout: 10s
          retries: 5
          start_period: 60s
        logging:
          driver: "json-file"
          options:
            max-size: "10m"
            max-file: "3"
    EOL

    # Create startup script
    cat > /opt/livekit-proxy/start.sh <<EOL
    #!/bin/bash
    set -e

    # Authenticate with ECR
    echo "Authenticating with ECR..."
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 761018882607.dkr.ecr.us-east-1.amazonaws.com

    # Pull the latest image
    echo "Pulling Docker image..."
    docker-compose pull

    # Start the service
    echo "Starting LiveKit proxy service..."
    docker-compose up -d

    # Show status
    echo "Service status:"
    docker-compose ps
    docker-compose logs
EOL

    chmod +x /opt/livekit-proxy/start.sh
    chown ubuntu:ubuntu /opt/livekit-proxy/start.sh

    # Authenticate with ECR and start service
    cd /opt/livekit-proxy
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 761018882607.dkr.ecr.us-east-1.amazonaws.com

    # Start the service
    docker-compose up -d

    # Install Nginx as a reverse proxy
    apt-get install -y nginx certbot python3-certbot-nginx

    # Configure Nginx
    cat > /etc/nginx/sites-available/livekit-proxy <<EOL
    server {
        listen 80;
        server_name ${var.domain_name} ${aws_eip.livekit_proxy.public_ip};

        # Health check endpoint
        location /health {
            return 200 'OK';
            add_header Content-Type text/plain;
        }

        # Proxy all requests to the application
        location / {
            proxy_pass http://localhost:9000;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # Alternative port proxy
        location /alt/ {
            proxy_pass http://localhost:8080/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
EOL

    # Remove default nginx site
    rm -f /etc/nginx/sites-enabled/default

    # Enable the site
    ln -s /etc/nginx/sites-available/livekit-proxy /etc/nginx/sites-enabled/

    # Test nginx configuration
    nginx -t

    # Reload nginx
    systemctl reload nginx
    systemctl enable nginx

    # Create a systemd service for the LiveKit proxy
    cat > /etc/systemd/system/livekit-proxy.service <<EOL
    [Unit]
    Description=LiveKit Proxy Service
    Requires=docker.service
    After=docker.service

    [Service]
    Type=oneshot
    RemainAfterExit=yes
    WorkingDirectory=/opt/livekit-proxy
    ExecStart=/opt/livekit-proxy/start.sh
    ExecStop=/usr/local/bin/docker-compose down
    TimeoutStartSec=300

    [Install]
    WantedBy=multi-user.target
EOL

    # Enable and start the service
    systemctl daemon-reload
    systemctl enable livekit-proxy.service

    # Wait a bit for Docker to be ready
    sleep 30

    # Check if everything is running
    echo "Final status check:"
    systemctl status docker
    systemctl status nginx
    cd /opt/livekit-proxy && docker-compose ps

    echo "User data script completed at $(date)"
  EOF
  )

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

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-livekit-proxy"
  })
}

# Elastic IP for EC2 instance
resource "aws_eip" "livekit_proxy" {
  instance = aws_instance.livekit_proxy.id
  domain   = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-eip"
  })
}

# Cloudflare DNS record - Using CNAME instead of A record for better flexibility
resource "cloudflare_record" "livekit_proxy_cname" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  value   = aws_eip.livekit_proxy.public_ip
  type    = "A"  # We'll keep A record since we have a static IP
  proxied = false  # Disable proxy initially for debugging
  ttl     = 300   # 5 minutes TTL for faster updates

  comment = "LiveKit Proxy - QA India Environment"
}

# Alternative CNAME record (commented out, use if you prefer CNAME)
# resource "cloudflare_record" "livekit_proxy_cname" {
#   zone_id = var.cloudflare_zone_id
#   name    = var.subdomain
#   value   = "${aws_eip.livekit_proxy.public_ip}.nip.io"  # Using nip.io for CNAME to IP
#   type    = "CNAME"
#   proxied = false
#   ttl     = 300
# }