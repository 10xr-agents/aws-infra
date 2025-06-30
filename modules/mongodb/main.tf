# modules/mongodb/main.tf

/**
 * # MongoDB Cluster Module
 *
 * This module creates a production-grade, self-hosted MongoDB replica set on AWS EC2.
 * It provisions EC2 instances across multiple availability zones, attaches EBS volumes,
 * configures security groups, and sets up MongoDB with automatic replica set initialization.
 */

locals {
  replica_set_name = var.replica_set_name != "" ? var.replica_set_name : "${var.cluster_name}-rs"
  common_tags = merge(
    var.tags,
    {
      Module      = "mongodb"
      ReplicaSet  = local.replica_set_name
      MongoDBVersion = var.mongodb_version
    }
  )
}

# Generate a new SSH key pair for MongoDB instances
resource "tls_private_key" "mongodb_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair from the generated private key
resource "aws_key_pair" "mongodb_key" {
  key_name   = "${var.cluster_name}-mongodb-keypair"
  public_key = tls_private_key.mongodb_key.public_key_openssh

  tags = merge(
    local.common_tags,
    {
      Name = "${var.cluster_name}-mongodb-keypair"
    }
  )
}

# Store the private key in AWS Systems Manager Parameter Store for secure access
resource "aws_ssm_parameter" "mongodb_private_key" {
  name  = "/${var.environment}/${var.cluster_name}/mongodb/ssh-private-key"
  type  = "SecureString"
  value = tls_private_key.mongodb_key.private_key_pem

  tags = local.common_tags
}

# Data source for latest Ubuntu AMI if not specified
data "aws_ami" "ubuntu" {
  count = var.ami_id == "" ? 1 : 0

  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for MongoDB
resource "aws_security_group" "mongodb" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.cluster_name}-mongodb-sg"
  description = "Security group for MongoDB replica set"
  vpc_id      = var.vpc_id

  # MongoDB port
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "MongoDB port"
  }

  # Allow MongoDB instances to communicate with each other
  ingress {
    from_port = 27017
    to_port   = 27017
    protocol  = "tcp"
    self      = true
    description = "MongoDB replica set communication"
  }

  # SSH access if specified
  dynamic "ingress" {
    for_each = var.allow_ssh && length(var.ssh_cidr_blocks) > 0 ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_cidr_blocks
      description = "SSH access"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.cluster_name}-mongodb-sg"
    }
  )
}

# IAM Role for MongoDB instances
resource "aws_iam_role" "mongodb" {
  name = "${var.cluster_name}-mongodb-role"

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

# IAM Role Policy for CloudWatch and SSM
resource "aws_iam_role_policy_attachment" "mongodb_cloudwatch" {
  role       = aws_iam_role.mongodb.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "mongodb_ssm" {
  role       = aws_iam_role.mongodb.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Role Policy for EBS Snapshots
resource "aws_iam_role_policy" "mongodb_ebs" {
  name = "${var.cluster_name}-mongodb-ebs-policy"
  role = aws_iam_role.mongodb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:DescribeSnapshots",
          "ec2:DescribeVolumes"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "mongodb" {
  name = "${var.cluster_name}-mongodb-profile"
  role = aws_iam_role.mongodb.name
}

# User data script template
data "template_file" "user_data" {
  count = var.replica_count

  template = file("${path.module}/user-data.sh")

  vars = {
    mongodb_version   = var.mongodb_version
    replica_set_name  = local.replica_set_name
    node_index        = count.index
    total_nodes       = var.replica_count
    mongodb_admin_username = var.mongodb_admin_username
    mongodb_admin_password = var.mongodb_admin_password
    mongodb_keyfile_content = var.mongodb_keyfile_content
    enable_monitoring = var.enable_monitoring
    data_volume_device = var.data_volume_device
    cluster_name      = var.cluster_name
  }
}

# EC2 Instances for MongoDB
resource "aws_instance" "mongodb" {
  count = var.replica_count

  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu[0].id
  instance_type = var.instance_type
  subnet_id     = element(var.subnet_ids, count.index)
  key_name      = aws_key_pair.mongodb_key.key_name  # Use the created key pair

  vpc_security_group_ids = concat(
      var.create_security_group ? [aws_security_group.mongodb[0].id] : [],
    var.additional_security_group_ids
  )

  iam_instance_profile = aws_iam_instance_profile.mongodb.name

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
    delete_on_termination = true
  }

  user_data = base64encode(data.template_file.user_data[count.index].rendered)

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.cluster_name}-mongodb-${count.index}"
      NodeIndex = count.index
    }
  )

  lifecycle {
    ignore_changes = [ami]
  }

  # Ensure the key pair is created before the instance
  depends_on = [aws_key_pair.mongodb_key]
}

# EBS Volumes for MongoDB data
resource "aws_ebs_volume" "mongodb_data" {
  count = var.replica_count

  availability_zone = data.aws_subnet.selected[count.index].availability_zone
  size              = var.data_volume_size
  type              = var.data_volume_type
  iops              = var.data_volume_type == "gp3" || var.data_volume_type == "io1" || var.data_volume_type == "io2" ? var.data_volume_iops : null
  throughput        = var.data_volume_type == "gp3" ? var.data_volume_throughput : null
  encrypted         = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.cluster_name}-mongodb-data-${count.index}"
      NodeIndex = count.index
    }
  )
}

# Attach EBS volumes to instances
resource "aws_volume_attachment" "mongodb_data" {
  count = var.replica_count

  device_name = var.data_volume_device
  volume_id   = aws_ebs_volume.mongodb_data[count.index].id
  instance_id = aws_instance.mongodb[count.index].id
}

# Data source for subnet information
data "aws_subnet" "selected" {
  count = var.replica_count
  id    = element(var.subnet_ids, count.index)
}

# CloudWatch Log Group for MongoDB logs
resource "aws_cloudwatch_log_group" "mongodb" {
  count = var.enable_monitoring ? 1 : 0

  name              = "/aws/ec2/mongodb/${var.cluster_name}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

# Route53 Private Hosted Zone (optional)
resource "aws_route53_zone" "mongodb" {
  count = var.create_dns_records ? 1 : 0

  name = var.private_domain != "" ? var.private_domain : "${var.cluster_name}.mongodb.local"

  vpc {
    vpc_id = var.vpc_id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.cluster_name}-mongodb-zone"
    }
  )
}

# DNS Records for MongoDB instances
resource "aws_route53_record" "mongodb_nodes" {
  count = var.create_dns_records ? var.replica_count : 0

  zone_id = aws_route53_zone.mongodb[0].zone_id
  name    = "mongo-${count.index}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.mongodb[count.index].private_ip]
}

# DNS Record for MongoDB replica set
resource "aws_route53_record" "mongodb_rs" {
  count = var.create_dns_records ? 1 : 0

  zone_id = aws_route53_zone.mongodb[0].zone_id
  name    = "mongodb-rs"
  type    = "A"
  ttl     = "60"

  set_identifier = "multivalue"
  multivalue_answer_routing_policy = true

  records = aws_instance.mongodb[*].private_ip
}

# Systems Manager Parameter for connection string
resource "aws_ssm_parameter" "mongodb_connection_string" {
  count = var.store_connection_string_in_ssm ? 1 : 0

  name  = "/${var.environment}/${var.cluster_name}/mongodb/connection-string"
  type  = "SecureString"
  value = local.connection_string

  tags = local.common_tags
}

locals {
  # Build MongoDB connection string
  connection_string = format(
    "mongodb://%s:%s@%s/%s?replicaSet=%s&authSource=admin",
    var.mongodb_admin_username,
    var.mongodb_admin_password,
    join(",", formatlist("%s:27017", aws_instance.mongodb[*].private_ip)),
    var.default_database,
    local.replica_set_name
  )

  # Build SRV connection string if DNS is enabled
  srv_connection_string = var.create_dns_records ? format(
    "mongodb+srv://%s:%s@%s/%s?replicaSet=%s&authSource=admin",
    var.mongodb_admin_username,
    var.mongodb_admin_password,
      var.private_domain != "" ? var.private_domain : "${var.cluster_name}.mongodb.local",
    var.default_database,
    local.replica_set_name
  ) : ""
}