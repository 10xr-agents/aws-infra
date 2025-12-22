# modules/bastion/main.tf

################################################################################
# Local Variables
################################################################################

locals {
  name_prefix = "${var.cluster_name}-${var.environment}"
}

################################################################################
# Get Latest Amazon Linux 2023 AMI
################################################################################

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    # Use standard AMI with SSM agent pre-installed (exclude minimal)
    values = ["al2023-ami-2023.*-kernel-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

################################################################################
# IAM Role for Bastion Host (SSM Access)
################################################################################

resource "aws_iam_role" "bastion" {
  name = "${local.name_prefix}-bastion-role"

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

  tags = merge(var.tags, {
    Name      = "${local.name_prefix}-bastion-role"
    Component = "Bastion"
  })
}

# Attach SSM Managed Instance Core policy for Session Manager access
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch Agent policy for logging
resource "aws_iam_role_policy_attachment" "bastion_cloudwatch" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "bastion" {
  name = "${local.name_prefix}-bastion-profile"
  role = aws_iam_role.bastion.name

  tags = merge(var.tags, {
    Name      = "${local.name_prefix}-bastion-profile"
    Component = "Bastion"
  })
}

################################################################################
# Security Group for Bastion Host
################################################################################

resource "aws_security_group" "bastion" {
  name        = "${local.name_prefix}-bastion-sg"
  description = "Security group for bastion host - SSM access only, no SSH"
  vpc_id      = var.vpc_id

  # No inbound rules needed - SSM Session Manager doesn't require inbound access

  # Allow all outbound traffic (needed for SSM, database connections, etc.)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name      = "${local.name_prefix}-bastion-sg"
    Component = "Bastion"
  })
}

################################################################################
# Bastion Host EC2 Instance
################################################################################

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = concat([aws_security_group.bastion.id], var.additional_security_group_ids)
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  # No public IP - access via SSM Session Manager only
  associate_public_ip_address = false

  # Enable detailed monitoring for better observability
  monitoring = var.enable_detailed_monitoring

  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true

    tags = merge(var.tags, {
      Name      = "${local.name_prefix}-bastion-root"
      Component = "Bastion"
    })
  }

  # User data script to install useful tools
  user_data_base64 = base64encode(<<-EOF
    #!/bin/bash
    set -e

    # Update system
    dnf update -y

    # Install useful tools for database connectivity
    dnf install -y \
      mongodb-mongosh \
      redis6 \
      postgresql15 \
      mysql \
      jq \
      wget \
      curl \
      telnet \
      nc

    # Download AWS DocumentDB CA certificate
    mkdir -p /home/ec2-user/.documentdb
    wget -O /home/ec2-user/.documentdb/global-bundle.pem \
      https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
    chown -R ec2-user:ec2-user /home/ec2-user/.documentdb

    # Create helpful connection scripts
    cat > /home/ec2-user/connect-documentdb.sh << 'SCRIPT'
    #!/bin/bash
    # Usage: ./connect-documentdb.sh <endpoint> <username> <password> [database]
    ENDPOINT=$${1:-"localhost"}
    USERNAME=$${2:-"docdbadmin"}
    PASSWORD=$${3}
    DATABASE=$${4:-"admin"}

    if [ -z "$PASSWORD" ]; then
      echo "Usage: ./connect-documentdb.sh <endpoint> <username> <password> [database]"
      echo "Example: ./connect-documentdb.sh my-cluster.cluster-xxx.us-east-1.docdb.amazonaws.com docdbadmin mypassword"
      exit 1
    fi

    mongosh "mongodb://$${USERNAME}:$${PASSWORD}@$${ENDPOINT}:27017/$${DATABASE}?tls=true&tlsCAFile=/home/ec2-user/.documentdb/global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
    SCRIPT
    chmod +x /home/ec2-user/connect-documentdb.sh
    chown ec2-user:ec2-user /home/ec2-user/connect-documentdb.sh

    # Create Redis connection script
    cat > /home/ec2-user/connect-redis.sh << 'SCRIPT'
    #!/bin/bash
    # Usage: ./connect-redis.sh <endpoint> [port] [auth-token]
    ENDPOINT=$${1:-"localhost"}
    PORT=$${2:-6379}
    AUTH=$${3}

    if [ -z "$AUTH" ]; then
      redis6-cli -h $ENDPOINT -p $PORT --tls
    else
      redis6-cli -h $ENDPOINT -p $PORT --tls -a $AUTH
    fi
    SCRIPT
    chmod +x /home/ec2-user/connect-redis.sh
    chown ec2-user:ec2-user /home/ec2-user/connect-redis.sh

    # Signal completion
    echo "Bastion host setup complete" > /home/ec2-user/setup-complete.txt
  EOF
  )

  tags = merge(var.tags, {
    Name      = "${local.name_prefix}-bastion"
    Component = "Bastion"
  })

  lifecycle {
    ignore_changes = [ami] # Don't recreate on AMI updates
  }
}

################################################################################
# CloudWatch Log Group for Session Manager Logs
################################################################################

resource "aws_cloudwatch_log_group" "bastion_sessions" {
  count = var.enable_session_logging ? 1 : 0

  name              = "/aws/ssm/${local.name_prefix}-bastion-sessions"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name      = "${local.name_prefix}-bastion-sessions"
    Component = "Bastion"
  })
}
