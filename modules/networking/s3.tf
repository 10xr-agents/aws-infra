################################################################################
# S3 Buckets for NLB Logs
################################################################################

# Generate random suffix for bucket names to ensure uniqueness
resource "random_string" "bucket_suffix" {
  count = (var.nlb_access_logs_enabled || var.nlb_connection_logs_enabled) ? 1 : 0

  length  = 8
  special = false
  upper   = false
}

# S3 Bucket for Access Logs
resource "aws_s3_bucket" "nlb_access_logs" {
  count = var.nlb_access_logs_enabled ? 1 : 0

  bucket        = "${local.name_prefix}-nlb-access-logs"
  force_destroy = false  # HIPAA compliance - prevent accidental deletion of audit logs

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-nlb-access-logs"
    Purpose = "NLB Access Logs"
  })
}

# S3 Bucket for Connection Logs
resource "aws_s3_bucket" "nlb_connection_logs" {
  count = var.nlb_connection_logs_enabled ? 1 : 0

  bucket        = "${local.name_prefix}-nlb-connection-logs"
  force_destroy = false  # HIPAA compliance - prevent accidental deletion of audit logs

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-nlb-connection-logs"
    Purpose = "NLB Connection Logs"
  })
}

# S3 Bucket Versioning for Access Logs
resource "aws_s3_bucket_versioning" "nlb_access_logs" {
  count = var.nlb_access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.nlb_access_logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Versioning for Connection Logs
resource "aws_s3_bucket_versioning" "nlb_connection_logs" {
  count = var.nlb_connection_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.nlb_connection_logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server Side Encryption for Access Logs
resource "aws_s3_bucket_server_side_encryption_configuration" "nlb_access_logs" {
  count = var.nlb_access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.nlb_access_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Server Side Encryption for Connection Logs
resource "aws_s3_bucket_server_side_encryption_configuration" "nlb_connection_logs" {
  count = var.nlb_connection_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.nlb_connection_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block for Access Logs
resource "aws_s3_bucket_public_access_block" "nlb_access_logs" {
  count = var.nlb_access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.nlb_access_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Public Access Block for Connection Logs
resource "aws_s3_bucket_public_access_block" "nlb_connection_logs" {
  count = var.nlb_connection_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.nlb_connection_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy for Access Logs
resource "aws_s3_bucket_policy" "nlb_access_logs" {
  count = var.nlb_access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.nlb_access_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.nlb_access_logs[0].arn}/*"
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
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.nlb_access_logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.nlb_access_logs[0].arn
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.nlb_access_logs[0].arn
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.nlb_access_logs]
}

# S3 Bucket Policy for Connection Logs
resource "aws_s3_bucket_policy" "nlb_connection_logs" {
  count = var.nlb_connection_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.nlb_connection_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.nlb_connection_logs[0].arn}/*"
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
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.nlb_connection_logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.nlb_connection_logs[0].arn
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.nlb_connection_logs[0].arn
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.nlb_connection_logs]
}

# S3 Bucket Lifecycle Configuration for Access Logs
# HIPAA requires 6 years (2192 days) retention for audit logs
resource "aws_s3_bucket_lifecycle_configuration" "nlb_access_logs" {
  count = var.nlb_access_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.nlb_access_logs[0].id

  rule {
    id     = "nlb_access_logs_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # HIPAA: Retain logs for 6 years
    expiration {
      days = var.nlb_logs_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.nlb_logs_retention_days
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

  depends_on = [aws_s3_bucket_versioning.nlb_access_logs]
}

# S3 Bucket Lifecycle Configuration for Connection Logs
# HIPAA requires 6 years (2192 days) retention for audit logs
resource "aws_s3_bucket_lifecycle_configuration" "nlb_connection_logs" {
  count = var.nlb_connection_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.nlb_connection_logs[0].id

  rule {
    id     = "nlb_connection_logs_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # HIPAA: Retain logs for 6 years
    expiration {
      days = var.nlb_logs_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.nlb_logs_retention_days
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

  depends_on = [aws_s3_bucket_versioning.nlb_connection_logs]
}