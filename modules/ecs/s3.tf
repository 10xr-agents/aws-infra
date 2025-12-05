# modules/ecs/s3.tf - HIPAA-Compliant S3 Buckets for ALB Logs

################################################################################
# Data Sources
################################################################################

data "aws_elb_service_account" "main" {}

################################################################################
# S3 Bucket for ALB Access Logs
################################################################################

resource "aws_s3_bucket" "alb_access_logs" {
  count = var.create_alb && var.alb_access_logs_enabled ? 1 : 0

  bucket        = "${local.name_prefix}-alb-access-logs"
  force_destroy = false  # HIPAA compliance - prevent accidental deletion of audit logs

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-alb-access-logs"
    Purpose   = "ALB Access Logs"
    HIPAA     = "true"
    Component = "S3"
  })
}

# S3 Bucket for ALB Connection Logs
resource "aws_s3_bucket" "alb_connection_logs" {
  count = var.create_alb && var.alb_connection_logs_enabled ? 1 : 0

  bucket        = "${local.name_prefix}-alb-connection-logs"
  force_destroy = false  # HIPAA compliance - prevent accidental deletion of audit logs

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-alb-connection-logs"
    Purpose   = "ALB Connection Logs"
    HIPAA     = "true"
    Component = "S3"
  })
}

################################################################################
# S3 Bucket Versioning (HIPAA Compliance)
################################################################################

resource "aws_s3_bucket_versioning" "alb_access_logs" {
  count = var.create_alb && var.alb_access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "alb_connection_logs" {
  count = var.create_alb && var.alb_connection_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.alb_connection_logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

################################################################################
# S3 Bucket Server Side Encryption (HIPAA Compliance)
################################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_access_logs" {
  count = var.create_alb && var.alb_access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_connection_logs" {
  count = var.create_alb && var.alb_connection_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.alb_connection_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

################################################################################
# S3 Bucket Public Access Block (HIPAA Compliance)
################################################################################

resource "aws_s3_bucket_public_access_block" "alb_access_logs" {
  count = var.create_alb && var.alb_access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "alb_connection_logs" {
  count = var.create_alb && var.alb_connection_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.alb_connection_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

################################################################################
# S3 Bucket Policies for ALB/ELB Service Access
################################################################################

resource "aws_s3_bucket_policy" "alb_access_logs" {
  count = var.create_alb && var.alb_access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_access_logs[0].arn}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_access_logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_access_logs[0].arn
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.alb_access_logs]
}

resource "aws_s3_bucket_policy" "alb_connection_logs" {
  count = var.create_alb && var.alb_connection_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.alb_connection_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_connection_logs[0].arn}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_connection_logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_connection_logs[0].arn
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.alb_connection_logs]
}

################################################################################
# S3 Bucket Lifecycle Configuration (HIPAA - 6 Year Retention)
################################################################################

resource "aws_s3_bucket_lifecycle_configuration" "alb_access_logs" {
  count = var.create_alb && var.alb_access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id

  rule {
    id     = "alb_access_logs_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # HIPAA: Retain logs for 6 years (2192 days)
    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.log_retention_days
    }

    # Transition to cheaper storage after 90 days
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier after 365 days
    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.alb_access_logs]
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_connection_logs" {
  count = var.create_alb && var.alb_connection_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.alb_connection_logs[0].id

  rule {
    id     = "alb_connection_logs_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # HIPAA: Retain logs for 6 years (2192 days)
    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.log_retention_days
    }

    # Transition to cheaper storage after 90 days
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier after 365 days
    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.alb_connection_logs]
}
