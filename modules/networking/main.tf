# modules/networking/main.tf

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false  # Changed to false for easier management
  drop_invalid_header_fields = true
  idle_timeout               = 60

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    prefix  = "alb-logs"
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-alb"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  depends_on = [aws_s3_bucket_policy.alb_logs]  # Ensure bucket policy is created before ALB
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No routes defined"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Add Network Load Balancer (NLB) for non-HTTP traffic
resource "aws_lb" "nlb" {
  name               = "${var.project_name}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids

  enable_cross_zone_load_balancing = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-nlb"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# NLB Listeners and Target Groups
resource "aws_lb_listener" "nlb_udp" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 3478
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_udp.arn
  }
}

resource "aws_lb_listener" "nlb_tcp" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 3478
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tcp.arn
  }
}

resource "aws_lb_target_group" "nlb_udp" {
  name        = "${var.project_name}-nlb-udp-tg"
  port        = 3478
  protocol    = "UDP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol = "TCP"
    port     = 3478
  }
}

resource "aws_lb_target_group" "nlb_tcp" {
  name        = "${var.project_name}-nlb-tcp-tg"
  port        = 3478
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol = "TCP"
    port     = 3478
  }
}

# Add security group for NLB traffic
resource "aws_security_group" "nlb" {
  name        = "${var.project_name}-nlb-sg"
  description = "Security group for NLB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3478
    to_port     = 3478
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "TURN/UDP"
  }

  ingress {
    from_port   = 3478
    to_port     = 3478
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "TURN/TLS"
  }

  ingress {
    from_port   = 49152
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "ICE/UDP port range"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-nlb-sg"
    }
  )
}

# Update ALB security group for better EKS integration
resource "aws_security_group_rule" "alb_to_eks" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = var.eks_cluster_sg_id
  security_group_id        = var.alb_security_group_id
}


# Removed TCP and UDP listeners as they're not typically used with Application Load Balancers

resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project_name}-waf-acl"
  description = "WAF ACL for ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateBasedRule"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateBasedRuleMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAFWebACLMetric"
    sampled_requests_enabled   = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-waf-acl"
    }
  )
}

resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# Removed Global Accelerator and Shield resources as they require additional subscriptions

resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.project_name}-alb-logs"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-alb-logs"
    }
  )
}

resource "aws_s3_bucket_ownership_controls" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "alb_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.alb_logs]

  bucket = aws_s3_bucket.alb_logs.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "log_rotation"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.project_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors ALB 5xx errors"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_4xx_errors" {
  alarm_name          = "${var.project_name}-alb-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_ELB_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "50"
  alarm_description   = "This metric monitors ALB 4xx errors"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "${var.project_name}-alb-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors ALB latency"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

data "aws_elb_service_account" "main" {}

# Global Accelerator and Shield configurations (commented out)
# Uncomment and configure these resources if you have the necessary AWS subscriptions
#
# resource "aws_globalaccelerator_accelerator" "main" {
#   name            = "${var.project_name}-accelerator"
#   ip_address_type = "IPV4"
#   enabled         = true
#
#   attributes {
#     flow_logs_enabled   = true
#     flow_logs_s3_bucket = aws_s3_bucket.alb_logs.id
#     flow_logs_s3_prefix = "flow-logs/"
#   }
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.project_name}-accelerator"
#     }
#   )
# }
#
# resource "aws_shield_protection" "global_accelerator" {
#   name         = "${var.project_name}-shield-global-accelerator"
#   resource_arn = aws_globalaccelerator_accelerator.main.id
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.project_name}-shield-global-accelerator"
#     }
#   )
# }
#
# resource "aws_globalaccelerator_listener" "main" {
#   accelerator_arn = aws_globalaccelerator_accelerator.main.id
#   client_affinity = "SOURCE_IP"
#   protocol        = "TCP"
#
#   port_range {
#     from_port = 80
#     to_port   = 80
#   }
#
#   port_range {
#     from_port = 443
#     to_port   = 443
#   }
# }
#
# resource "aws_globalaccelerator_endpoint_group" "main" {
#   listener_arn = aws_globalaccelerator_listener.main.id
#
#   endpoint_configuration {
#     endpoint_id = aws_lb.main.arn
#     weight      = 100
#   }
#
#   health_check_path             = "/healthz"
#   health_check_interval_seconds = 10
#   health_check_port             = 443
#   health_check_protocol         = "HTTPS"
# }
#
# resource "aws_shield_protection" "alb" {
#   name         = "${var.project_name}-shield-alb"
#   resource_arn = aws_lb.main.arn
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.project_name}-shield-alb"
#     }
#   )
# }