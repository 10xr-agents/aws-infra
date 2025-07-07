# modules/mongodb/main.tf - UPDATED VERSION

/**
 * # MongoDB 8.0 Cluster Module - Updated
 *
 * This module creates a production-grade, self-hosted MongoDB 8.0 replica set on AWS EC2.
 * It provisions EC2 instances across multiple availability zones, attaches EBS volumes,
 * configures security groups, and sets up MongoDB with automatic replica set initialization.
 *
 * Key improvements:
 * - Fixed MongoDB 8.0 installation for Ubuntu 22.04
 * - Improved device detection for both NVMe and traditional EBS volumes
 * - Better error handling and logging
 * - Enhanced authentication setup
 * - Improved node discovery and coordination
 */

locals {
  replica_set_name = var.replica_set_name != "" ? var.replica_set_name : "${var.cluster_name}-rs"
  common_tags = merge(
    var.tags,
    {
      Module         = "mongodb"
      ReplicaSet     = local.replica_set_name
      MongoDBVersion = var.mongodb_version
      Environment    = var.environment
    }
  )
}

# Generate SSH key pair for MongoDB instances
resource "tls_private_key" "mongodb_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

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

# Store private key in SSM
resource "aws_ssm_parameter" "mongodb_private_key" {
  name  = "/${var.environment}/${var.cluster_name}/mongodb/ssh-private-key"
  type  = "SecureString"
  value = tls_private_key.mongodb_key.private_key_pem
  tags  = local.common_tags
}

# Data source for latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  count       = var.ami_id == "" ? 1 : 0
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

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Security Group for MongoDB
resource "aws_security_group" "mongodb" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.cluster_name}-mongodb-sg"
  description = "Security group for MongoDB 8.0 replica set"
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
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    self        = true
    description = "MongoDB replica set communication"
  }

  # SSH access
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

# IAM policies for MongoDB instances
resource "aws_iam_role_policy_attachment" "mongodb_cloudwatch" {
  role       = aws_iam_role.mongodb.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "mongodb_ssm" {
  role       = aws_iam_role.mongodb.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Enhanced IAM policy for MongoDB coordination
resource "aws_iam_role_policy" "mongodb_coordination" {
  name = "${var.cluster_name}-mongodb-coordination-policy"
  role = aws_iam_role.mongodb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # EBS operations
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:DescribeSnapshots",
          "ec2:DescribeVolumes",
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:ModifyInstanceAttribute",
          # SSM for coordination
          "ssm:GetParameter",
          "ssm:PutParameter",
          "ssm:DeleteParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          # CloudWatch for monitoring
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "mongodb" {
  name = "${var.cluster_name}-mongodb-profile"
  role = aws_iam_role.mongodb.name
}

# EBS Volumes for MongoDB data
resource "aws_ebs_volume" "mongodb_data" {
  count = var.replica_count

  availability_zone = data.aws_subnet.selected[count.index].availability_zone
  size              = var.data_volume_size
  type              = var.data_volume_type
  iops              = var.data_volume_type == "gp3" || var.data_volume_type == "io1" || var.data_volume_type == "io2" ? var.data_volume_iops : null
  throughput        = var.data_volume_type == "gp3" ? var.data_volume_throughput : null
  encrypted         = var.enable_encryption_at_rest

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.cluster_name}-mongodb-data-${count.index}"
      NodeIndex = count.index
      Purpose   = "MongoDB Data"
    }
  )
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

# EC2 Instances for MongoDB
resource "aws_instance" "mongodb" {
  count = var.replica_count

  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu[0].id
  instance_type = var.instance_type
  subnet_id     = element(var.subnet_ids, count.index)
  key_name      = aws_key_pair.mongodb_key.key_name

  vpc_security_group_ids = concat(
      var.create_security_group ? [aws_security_group.mongodb[0].id] : [],
    var.additional_security_group_ids
  )

  iam_instance_profile = aws_iam_instance_profile.mongodb.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = var.enable_encryption_at_rest
    delete_on_termination = true

    tags = merge(
      local.common_tags,
      {
        Name = "${var.cluster_name}-mongodb-root-${count.index}"
      }
    )
  }

  # User data with improved cloud-init script
  user_data_base64 = base64gzip(templatefile("${path.module}/user-data-cloud-init.yml", {
    mongodb_version         = var.mongodb_version
    replica_set_name        = local.replica_set_name
    node_index              = count.index
    total_nodes             = var.replica_count
    mongodb_admin_username  = var.mongodb_admin_username
    mongodb_admin_password  = var.mongodb_admin_password
    mongodb_keyfile_content = var.mongodb_keyfile_content
    enable_monitoring       = var.enable_monitoring
    cluster_name            = var.cluster_name
    vpc_id                  = var.vpc_id
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  monitoring = var.enable_monitoring

  tags = merge(
    local.common_tags,
    {
      Name           = "${var.cluster_name}-mongodb-${count.index}"
      NodeIndex      = count.index
      MongoDBCluster = var.cluster_name
      MongoDBRole    = count.index == 0 ? "primary" : "secondary"
      BackupEnabled  = var.backup_enabled ? "true" : "false"
    }
  )

  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }

  depends_on = [
    aws_key_pair.mongodb_key,
    aws_ebs_volume.mongodb_data,
    aws_cloudwatch_log_group.mongodb
  ]
}

# Attach EBS volumes to instances
resource "aws_volume_attachment" "mongodb_data" {
  count = var.replica_count

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.mongodb_data[count.index].id
  instance_id = aws_instance.mongodb[count.index].id

  # Prevent attachment during instance replacement
  lifecycle {
    ignore_changes = [instance_id]
  }

  depends_on = [
    aws_instance.mongodb,
    aws_ebs_volume.mongodb_data
  ]
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

  depends_on = [aws_instance.mongodb]
}

# Multi-value DNS record for the replica set
resource "aws_route53_record" "mongodb_rs" {
  for_each = var.create_dns_records ? {
    for idx, ip in aws_instance.mongodb[*].private_ip : idx => ip
  } : {}

  zone_id = aws_route53_zone.mongodb[0].zone_id
  name    = "mongodb-rs"
  type    = "A"
  ttl     = 60

  set_identifier                   = tostring(each.key)
  multivalue_answer_routing_policy = true
  records                          = [each.value]

  depends_on = [aws_instance.mongodb]
}

# SSM Parameter for connection string
resource "aws_ssm_parameter" "mongodb_connection_string" {
  count = var.store_connection_string_in_ssm ? 1 : 0

  name  = "/${var.environment}/${var.cluster_name}/mongodb/connection-string"
  type  = "SecureString"
  value = local.connection_string

  description = "MongoDB connection string for ${var.cluster_name}"
  tags        = local.common_tags

  depends_on = [aws_instance.mongodb]
}

# SSM Parameter for SRV connection string
resource "aws_ssm_parameter" "mongodb_srv_connection_string" {
  count = var.store_connection_string_in_ssm && var.create_dns_records ? 1 : 0

  name  = "/${var.environment}/${var.cluster_name}/mongodb/srv-connection-string"
  type  = "SecureString"
  value = local.srv_connection_string

  description = "MongoDB SRV connection string for ${var.cluster_name}"
  tags        = local.common_tags

  depends_on = [
    aws_instance.mongodb,
    aws_route53_zone.mongodb
  ]
}

# Store cluster configuration in SSM
resource "aws_ssm_parameter" "mongodb_cluster_config" {
  name = "/${var.cluster_name}/mongodb/cluster-config"
  type = "String"
  value = jsonencode({
    cluster_name         = var.cluster_name
    replica_set_name     = local.replica_set_name
    replica_count        = var.replica_count
    mongodb_version      = var.mongodb_version
    vpc_id               = var.vpc_id
    subnets              = var.subnet_ids
    security_group_id    = var.create_security_group ? aws_security_group.mongodb[0].id : null
    private_domain       = var.create_dns_records ? aws_route53_zone.mongodb[0].name : null
    backup_enabled       = var.backup_enabled
    monitoring_enabled   = var.enable_monitoring
    created_at           = timestamp()
  })

  description = "MongoDB cluster configuration for ${var.cluster_name}"
  tags        = local.common_tags
}

# Backup configuration using AWS Backup (optional)
resource "aws_backup_vault" "mongodb" {
  count = var.backup_enabled ? 1 : 0

  name        = "${var.cluster_name}-mongodb-backup-vault"
  kms_key_arn = var.enable_encryption_at_rest ? null : null

  tags = local.common_tags
}

resource "aws_backup_plan" "mongodb" {
  count = var.backup_enabled ? 1 : 0

  name = "${var.cluster_name}-mongodb-backup-plan"

  rule {
    rule_name         = "mongodb_backup_rule"
    target_vault_name = aws_backup_vault.mongodb[0].name
    schedule          = var.backup_schedule

    lifecycle {
      delete_after = var.backup_retention_days
    }

    recovery_point_tags = merge(
      local.common_tags,
      {
        BackupType = "MongoDB"
      }
    )
  }

  tags = local.common_tags
}

# Backup selection for MongoDB volumes
resource "aws_backup_selection" "mongodb" {
  count = var.backup_enabled ? 1 : 0

  iam_role_arn = aws_iam_role.backup[0].arn
  name         = "${var.cluster_name}-mongodb-backup-selection"
  plan_id      = aws_backup_plan.mongodb[0].id

  resources = aws_ebs_volume.mongodb_data[*].arn

  depends_on = [
    aws_ebs_volume.mongodb_data,
    aws_backup_plan.mongodb
  ]
}

# IAM role for AWS Backup
resource "aws_iam_role" "backup" {
  count = var.backup_enabled ? 1 : 0

  name = "${var.cluster_name}-mongodb-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  count = var.backup_enabled ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Local values for connection strings
locals {
  connection_string = format(
    "mongodb://%s:%s@%s/%s?replicaSet=%s&authSource=admin",
    var.mongodb_admin_username,
    var.mongodb_admin_password,
    join(",", formatlist("%s:27017", aws_instance.mongodb[*].private_ip)),
    var.default_database,
    local.replica_set_name
  )

  srv_connection_string = var.create_dns_records ? format(
    "mongodb+srv://%s:%s@%s/%s?replicaSet=%s&authSource=admin",
    var.mongodb_admin_username,
    var.mongodb_admin_password,
    replace(aws_route53_zone.mongodb[0].name, "/\\.$/", ""),
    var.default_database,
    local.replica_set_name
  ) : ""
}