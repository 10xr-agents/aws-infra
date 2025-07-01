# modules/global-accelerator/main.tf - Fixed version

locals {
  name_prefix = "${var.cluster_name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Component   = "GlobalAccelerator"
      ManagedBy   = "terraform"
    }
  )
}

################################################################################
# S3 Bucket for Global Accelerator Flow Logs
################################################################################

resource "aws_s3_bucket" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  bucket        = var.flow_logs_s3_bucket != "" ? var.flow_logs_s3_bucket : "${local.name_prefix}-ga-flow-logs-${random_string.bucket_suffix[0].result}"
  force_destroy = var.s3_force_destroy

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ga-flow-logs"
  })
}

resource "random_string" "bucket_suffix" {
  count = var.enable_flow_logs && var.flow_logs_s3_bucket == "" ? 1 : 0

  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy for Global Accelerator to write flow logs
resource "aws_s3_bucket_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "globalaccelerator.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.flow_logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "globalaccelerator.amazonaws.com"
        }
        Action = ["s3:GetBucketLocation", "s3:ListBucket"]
        Resource = aws_s3_bucket.flow_logs[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

################################################################################
# Global Accelerator
################################################################################

resource "aws_globalaccelerator_accelerator" "main" {
  name            = "${local.name_prefix}-accelerator"
  ip_address_type = var.ip_address_type
  enabled         = var.enabled

  dynamic "attributes" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      flow_logs_enabled   = true
      flow_logs_s3_bucket = aws_s3_bucket.flow_logs[0].id
      flow_logs_s3_prefix = var.flow_logs_s3_prefix
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-accelerator"
  })
}

################################################################################
# Global Accelerator Listeners
################################################################################

resource "aws_globalaccelerator_listener" "main" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.id
  client_affinity = var.client_affinity
  protocol        = var.protocol

  dynamic "port_range" {
    for_each = var.port_ranges
    content {
      from_port = port_range.value.from_port
      to_port   = port_range.value.to_port
    }
  }
}

################################################################################
# Global Accelerator Endpoint Groups
################################################################################

resource "aws_globalaccelerator_endpoint_group" "main" {
  listener_arn = aws_globalaccelerator_listener.main.id

  endpoint_group_region = var.endpoint_group_region != "" ? var.endpoint_group_region : data.aws_region.current.name

  # Health check configuration - removed invalid arguments
  health_check_interval_seconds     = var.health_check_interval_seconds
  health_check_path                 = var.health_check_path
  health_check_port                 = var.health_check_port
  health_check_protocol             = var.health_check_protocol
  threshold_count                   = var.threshold_count
  traffic_dial_percentage           = var.traffic_dial_percentage

  dynamic "endpoint_configuration" {
    for_each = var.endpoints
    content {
      endpoint_id                    = endpoint_configuration.value.endpoint_id
      weight                         = lookup(endpoint_configuration.value, "weight", 100)
      client_ip_preservation_enabled = lookup(endpoint_configuration.value, "client_ip_preservation_enabled", false)
    }
  }

  dynamic "port_override" {
    for_each = var.port_overrides
    content {
      listener_port = port_override.value.listener_port
      endpoint_port = port_override.value.endpoint_port
    }
  }
}

################################################################################
# Additional Listeners (for multi-protocol support)
################################################################################

resource "aws_globalaccelerator_listener" "additional" {
  count = length(var.additional_listeners)

  accelerator_arn = aws_globalaccelerator_accelerator.main.id
  client_affinity = lookup(var.additional_listeners[count.index], "client_affinity", "NONE")
  protocol        = var.additional_listeners[count.index].protocol

  dynamic "port_range" {
    for_each = var.additional_listeners[count.index].port_ranges
    content {
      from_port = port_range.value.from_port
      to_port   = port_range.value.to_port
    }
  }
}

################################################################################
# Additional Endpoint Groups (for additional listeners)
################################################################################

resource "aws_globalaccelerator_endpoint_group" "additional" {
  count = length(var.additional_listeners)

  listener_arn = aws_globalaccelerator_listener.additional[count.index].id

  endpoint_group_region = var.endpoint_group_region != "" ? var.endpoint_group_region : data.aws_region.current.name

  # Health check configuration - removed invalid arguments
  health_check_interval_seconds     = lookup(var.additional_listeners[count.index], "health_check_interval_seconds", var.health_check_interval_seconds)
  health_check_path                 = lookup(var.additional_listeners[count.index], "health_check_path", var.health_check_path)
  health_check_port                 = lookup(var.additional_listeners[count.index], "health_check_port", var.health_check_port)
  health_check_protocol             = lookup(var.additional_listeners[count.index], "health_check_protocol", var.health_check_protocol)
  threshold_count                   = lookup(var.additional_listeners[count.index], "threshold_count", var.threshold_count)
  traffic_dial_percentage           = lookup(var.additional_listeners[count.index], "traffic_dial_percentage", var.traffic_dial_percentage)

  dynamic "endpoint_configuration" {
    for_each = lookup(var.additional_listeners[count.index], "endpoints", var.endpoints)
    content {
      endpoint_id                    = endpoint_configuration.value.endpoint_id
      weight                         = lookup(endpoint_configuration.value, "weight", 100)
      client_ip_preservation_enabled = lookup(endpoint_configuration.value, "client_ip_preservation_enabled", false)
    }
  }

  dynamic "port_override" {
    for_each = lookup(var.additional_listeners[count.index], "port_overrides", [])
    content {
      listener_port = port_override.value.listener_port
      endpoint_port = port_override.value.endpoint_port
    }
  }
}

################################################################################
# CloudWatch Alarms for Global Accelerator (Optional)
################################################################################

resource "aws_cloudwatch_metric_alarm" "new_flow_count" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-ga-new-flow-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NewFlowCount"
  namespace           = "AWS/GlobalAccelerator"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.new_flow_count_threshold
  alarm_description   = "This metric monitors new flow count for Global Accelerator"
  alarm_actions       = var.alarm_actions

  dimensions = {
    Accelerator = aws_globalaccelerator_accelerator.main.id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "processed_bytes_in" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-ga-processed-bytes-in"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ProcessedBytesIn"
  namespace           = "AWS/GlobalAccelerator"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.processed_bytes_in_threshold
  alarm_description   = "This metric monitors processed bytes in for Global Accelerator"
  alarm_actions       = var.alarm_actions

  dimensions = {
    Accelerator = aws_globalaccelerator_accelerator.main.id
  }

  tags = local.common_tags
}

################################################################################
# Data Sources
################################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}