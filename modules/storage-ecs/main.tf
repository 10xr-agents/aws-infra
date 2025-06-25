# modules/storage-ecs/main.tf

/**
 * # Storage Module for ECS
 *
 * This module creates storage resources for ECS including:
 * - EFS for shared persistent storage
 * - S3 bucket for recordings
 */

# EFS File System
resource "aws_efs_file_system" "main" {
  creation_token   = "${var.cluster_name}-efs"
  performance_mode = var.efs_performance_mode
  throughput_mode  = var.efs_throughput_mode
  
  # Set provisioned throughput if using provisioned mode
  provisioned_throughput_in_mibps = var.efs_throughput_mode == "provisioned" ? var.efs_provisioned_throughput : null
  
  dynamic "lifecycle_policy" {
    for_each = var.enable_efs_lifecycle_policy ? [1] : []
    content {
      transition_to_ia = "AFTER_30_DAYS"
    }
  }

  encrypted = true

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-efs"
    }
  )
}

# EFS Mount Targets
resource "aws_efs_mount_target" "main" {
  count = length(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Security Group for EFS
resource "aws_security_group" "efs" {
  name        = "${var.cluster_name}-efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
    description     = "NFS from ECS tasks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-efs-sg"
    }
  )
}

# EFS Access Point for LiveKit
resource "aws_efs_access_point" "livekit" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/livekit"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  posix_user {
    gid = 1000
    uid = 1000
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-livekit-ap"
    }
  )
}

# S3 Bucket for Recordings
resource "aws_s3_bucket" "recordings" {
  count = var.create_recordings_bucket ? 1 : 0

  bucket = var.recordings_bucket_name

  tags = merge(
    var.tags,
    {
      Name = var.recordings_bucket_name
    }
  )
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "recordings" {
  count = var.create_recordings_bucket ? 1 : 0

  bucket = aws_s3_bucket.recordings[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "recordings" {
  count = var.create_recordings_bucket ? 1 : 0

  bucket = aws_s3_bucket.recordings[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "recordings" {
  count = var.create_recordings_bucket ? 1 : 0

  bucket = aws_s3_bucket.recordings[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle Policy
resource "aws_s3_bucket_lifecycle_configuration" "recordings" {
  count = var.create_recordings_bucket && var.recordings_expiration_days > 0 ? 1 : 0

  bucket = aws_s3_bucket.recordings[0].id

  rule {
    id     = "expire-old-recordings"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.recordings_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# IAM Role for ECS Tasks to access storage
resource "aws_iam_role" "ecs_task" {
  name = "${var.cluster_name}-ecs-task-storage-role"

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

# IAM Policy for S3 access
resource "aws_iam_policy" "s3_access" {
  count = var.create_recordings_bucket ? 1 : 0

  name        = "${var.cluster_name}-s3-recordings-policy"
  description = "Policy for ECS tasks to access recordings bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.recordings[0].arn,
          "${aws_s3_bucket.recordings[0].arn}/*"
        ]
      }
    ]
  })
}

# Attach S3 policy to task role
resource "aws_iam_role_policy_attachment" "s3_access" {
  count = var.create_recordings_bucket ? 1 : 0

  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.s3_access[0].arn
}

