# modules/s3-hipaa/main.tf
# HIPAA-compliant S3 bucket for PHI (Protected Health Information)

################################################################################
# Local Variables
################################################################################

locals {
  name_prefix = "${var.cluster_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = "10xR-Healthcare"
    Terraform   = "true"
    HIPAA       = "true"
    DataType    = "PHI"
  })
}

################################################################################
# KMS Key for S3 Encryption (HIPAA Requirement)
################################################################################

resource "aws_kms_key" "s3" {
  count = var.create_kms_key ? 1 : 0

  description             = "KMS key for S3 bucket encryption - ${var.bucket_name}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true # HIPAA requirement

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow ECS Tasks"
        Effect = "Allow"
        Principal = {
          AWS = var.ecs_task_role_arns
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-s3-${var.bucket_name}-kms"
  })
}

resource "aws_kms_alias" "s3" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${local.name_prefix}-s3-${var.bucket_name}"
  target_key_id = aws_kms_key.s3[0].key_id
}

################################################################################
# S3 Bucket
################################################################################

resource "aws_s3_bucket" "this" {
  bucket        = "${local.name_prefix}-${var.bucket_name}"
  force_destroy = var.force_destroy # Configurable - should be false in production for HIPAA compliance

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.bucket_name}"
  })
}

################################################################################
# S3 Bucket Versioning (HIPAA Requirement)
################################################################################

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled" # HIPAA requirement - maintain audit trail
  }
}

################################################################################
# S3 Bucket Server-Side Encryption (HIPAA Requirement)
################################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.create_kms_key ? aws_kms_key.s3[0].arn : var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true # Cost optimization
  }
}

################################################################################
# S3 Bucket Public Access Block (HIPAA Requirement)
################################################################################

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

################################################################################
# S3 Bucket Policy (Enforce SSL/TLS)
################################################################################

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceSSLOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "EnforceEncryption"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.this.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid    = "AllowECSTaskAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.ecs_task_role_arns
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.this]
}

################################################################################
# S3 Bucket Lifecycle Configuration (Cost Optimization + Retention)
################################################################################

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "hipaa-retention"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # Retain data for configured retention period
    expiration {
      days = var.retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.retention_days
    }

    # Cost optimization - move to cheaper storage (only if retention > transition days)
    dynamic "transition" {
      for_each = var.retention_days > 90 ? [1] : []
      content {
        days          = 90
        storage_class = "STANDARD_IA"
      }
    }

    dynamic "transition" {
      for_each = var.retention_days > 365 ? [1] : []
      content {
        days          = 365
        storage_class = "GLACIER"
      }
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

################################################################################
# S3 Bucket Logging (HIPAA Audit Trail)
################################################################################

resource "aws_s3_bucket" "access_logs" {
  count = var.enable_access_logging ? 1 : 0

  bucket        = "${local.name_prefix}-${var.bucket_name}-access-logs"
  force_destroy = var.force_destroy # Configurable - should be false in production for HIPAA compliance

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-${var.bucket_name}-access-logs"
    Purpose = "S3 Access Logs"
  })
}

resource "aws_s3_bucket_versioning" "access_logs" {
  count = var.enable_access_logging ? 1 : 0

  bucket = aws_s3_bucket.access_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  count = var.enable_access_logging ? 1 : 0

  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  count = var.enable_access_logging ? 1 : 0

  bucket = aws_s3_bucket.access_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  count = var.enable_access_logging ? 1 : 0

  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    id     = "access-logs-retention"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.retention_days
    }

    # Cost optimization - move to cheaper storage (only if retention > transition days)
    dynamic "transition" {
      for_each = var.retention_days > 90 ? [1] : []
      content {
        days          = 90
        storage_class = "STANDARD_IA"
      }
    }

    dynamic "transition" {
      for_each = var.retention_days > 365 ? [1] : []
      content {
        days          = 365
        storage_class = "GLACIER"
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.access_logs]
}

resource "aws_s3_bucket_logging" "this" {
  count = var.enable_access_logging ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = aws_s3_bucket.access_logs[0].id
  target_prefix = "logs/"
}

################################################################################
# IAM Policy for ECS Task Access
################################################################################

resource "aws_iam_policy" "s3_access" {
  name        = "${local.name_prefix}-${var.bucket_name}-s3-access"
  description = "IAM policy for ECS tasks to access ${var.bucket_name} S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
      },
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = var.create_kms_key ? [aws_kms_key.s3[0].arn] : [var.kms_key_arn]
      }
    ]
  })

  tags = local.common_tags
}

################################################################################
# Data Sources
################################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
