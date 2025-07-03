# modules/networking/main.tf

locals {
  name_prefix = "${var.cluster_name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Component   = "Networking"
      ManagedBy   = "terraform"
    }
  )
}

################################################################################
# Data Sources
################################################################################

data "aws_vpc" "main" {
  id = var.vpc_id
}

################################################################################
# Network Load Balancer
################################################################################

resource "aws_lb" "public_nlb" {
  count = var.create_nlb ? 1 : 0

  name               = "${local.name_prefix}-public-nlb"
  internal           = var.nlb_internal
  load_balancer_type = "network"

  # Use appropriate subnets based on internal/external configuration
  subnets = var.nlb_internal ? var.private_subnet_ids : var.public_subnet_ids

  enable_deletion_protection = var.nlb_enable_deletion_protection
  enable_cross_zone_load_balancing = var.nlb_enable_cross_zone_load_balancing

  # Access logs configuration
  dynamic "access_logs" {
    for_each = var.nlb_access_logs_enabled ? [1] : []
    content {
      bucket  = var.nlb_access_logs_bucket
      prefix  = var.nlb_access_logs_prefix
      enabled = true
    }
  }

  # Connection logs configuration
  dynamic "connection_logs" {
    for_each = var.nlb_connection_logs_enabled ? [1] : []
    content {
      bucket  = var.nlb_connection_logs_bucket
      prefix  = var.nlb_connection_logs_prefix
      enabled = true
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-nlb"
    Type = "Network Load Balancer"
  })
}

################################################################################
# Target Groups
################################################################################

# HTTP Target Group
resource "aws_lb_target_group" "alb_targets_http" {
  count = var.create_nlb && var.create_http_target_group ? 1 : 0

  name        = "${local.name_prefix}-alb-tg-http"
  port        = var.http_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = var.target_type

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    port                = var.health_check_port
    protocol            = var.health_check_protocol
    timeout             = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
    path                = var.health_check_path
    matcher             = var.health_check_matcher
  }

  deregistration_delay = var.deregistration_delay

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-tg-http"
    Port = var.http_port
  })
}

# HTTPS Target Group
resource "aws_lb_target_group" "alb_targets_https" {
  count = var.create_nlb && var.create_https_target_group ? 1 : 0

  name        = "${local.name_prefix}-alb-tg-https"
  port        = var.https_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = var.target_type

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    port                = var.health_check_port
    protocol            = var.health_check_protocol
    timeout             = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
    path                = var.health_check_path
    matcher             = var.health_check_matcher
  }

  deregistration_delay = var.deregistration_delay

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-tg-https"
    Port = var.https_port
  })
}

# Custom Target Groups
resource "aws_lb_target_group" "custom" {
  for_each = var.custom_target_groups

  name        = "${local.name_prefix}-${each.key}-tg"
  port        = each.value.port
  protocol    = lookup(each.value, "protocol", "TCP")
  vpc_id      = var.vpc_id
  target_type = lookup(each.value, "target_type", var.target_type)

  dynamic "health_check" {
    for_each = lookup(each.value, "health_check", null) != null ? [each.value.health_check] : []
    content {
      enabled             = lookup(health_check.value, "enabled", true)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", var.health_check_healthy_threshold)
      interval            = lookup(health_check.value, "interval", var.health_check_interval)
      port                = lookup(health_check.value, "port", var.health_check_port)
      protocol            = lookup(health_check.value, "protocol", var.health_check_protocol)
      timeout             = lookup(health_check.value, "timeout", var.health_check_timeout)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", var.health_check_unhealthy_threshold)
      path                = lookup(health_check.value, "path", var.health_check_path)
      matcher             = lookup(health_check.value, "matcher", var.health_check_matcher)
    }
  }

  deregistration_delay = lookup(each.value, "deregistration_delay", var.deregistration_delay)

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.key}-tg"
    Port = each.value.port
  })
}

################################################################################
# Target Group Attachments
################################################################################

# HTTP Target Group Attachment
resource "aws_lb_target_group_attachment" "alb_target_http" {
  count = var.create_nlb && var.create_http_target_group && var.alb_arn != "" ? 1 : 0

  target_group_arn = aws_lb_target_group.alb_targets_http[0].arn
  target_id        = var.alb_arn
  port             = var.http_port
}

# HTTPS Target Group Attachment
resource "aws_lb_target_group_attachment" "alb_target_https" {
  count = var.create_nlb && var.create_https_target_group && var.alb_arn != "" ? 1 : 0

  target_group_arn = aws_lb_target_group.alb_targets_https[0].arn
  target_id        = var.alb_arn
  port             = var.https_port
}

# Custom Target Group Attachments
resource "aws_lb_target_group_attachment" "custom" {
  for_each = {
    for key, config in var.custom_target_groups : key => config
    if lookup(config, "target_id", "") != "" && var.create_nlb
  }

  target_group_arn = aws_lb_target_group.custom[each.key].arn
  target_id        = each.value.target_id
  port             = each.value.port
}

################################################################################
# NLB Listeners
################################################################################

# HTTP Listener
resource "aws_lb_listener" "public_nlb_http" {
  count = var.create_nlb && var.create_http_listener ? 1 : 0

  load_balancer_arn = aws_lb.public_nlb[0].arn
  port              = var.http_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = var.create_http_target_group ? aws_lb_target_group.alb_targets_http[0].arn : var.default_http_target_group_arn
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nlb-http-listener"
    Port = var.http_port
  })
}

# HTTPS Listener (TCP)
resource "aws_lb_listener" "public_nlb_https_tcp" {
  count = var.create_nlb && var.create_https_listener && var.https_listener_protocol == "TCP" ? 1 : 0

  load_balancer_arn = aws_lb.public_nlb[0].arn
  port              = var.https_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = var.create_https_target_group ? aws_lb_target_group.alb_targets_https[0].arn : var.default_https_target_group_arn
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nlb-https-tcp-listener"
    Port = var.https_port
  })
}

# HTTPS Listener (TLS)
resource "aws_lb_listener" "public_nlb_https_tls" {
  count = var.create_nlb && var.create_https_listener && var.https_listener_protocol == "TLS" ? 1 : 0

  load_balancer_arn = aws_lb.public_nlb[0].arn
  port              = var.https_port
  protocol          = "TLS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = var.create_https_target_group ? aws_lb_target_group.alb_targets_https[0].arn : var.default_https_target_group_arn
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nlb-https-tls-listener"
    Port = var.https_port
  })
}

# Custom Listeners
resource "aws_lb_listener" "custom" {
  for_each = var.custom_listeners

  load_balancer_arn = aws_lb.public_nlb[0].arn
  port              = each.value.port
  protocol          = each.value.protocol

  # SSL configuration for TLS listeners
  ssl_policy      = each.value.protocol == "TLS" ? lookup(each.value, "ssl_policy", var.ssl_policy) : null
  certificate_arn = each.value.protocol == "TLS" ? lookup(each.value, "certificate_arn", var.certificate_arn) : null

  default_action {
    type             = "forward"
    target_group_arn = lookup(each.value, "target_group_arn", null) != null ? each.value.target_group_arn : aws_lb_target_group.custom[each.key].arn
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nlb-${each.key}-listener"
    Port = each.value.port
  })
}

################################################################################
# Security Groups for NLB (if create_security_groups is enabled)
################################################################################

resource "aws_security_group" "nlb" {
  count = var.create_nlb && var.create_security_groups ? 1 : 0

  name        = "${local.name_prefix}-nlb-sg"
  description = "Security group for NLB ${local.name_prefix}"
  vpc_id      = var.vpc_id

  # HTTP ingress
  dynamic "ingress" {
    for_each = var.create_http_listener ? [1] : []
    content {
      description = "HTTP"
      from_port   = var.http_port
      to_port     = var.http_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  # HTTPS ingress
  dynamic "ingress" {
    for_each = var.create_https_listener ? [1] : []
    content {
      description = "HTTPS"
      from_port   = var.https_port
      to_port     = var.https_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  # Custom port ingress
  dynamic "ingress" {
    for_each = var.additional_ports
    content {
      description = "Custom port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  # Egress rules
  dynamic "egress" {
    for_each = var.security_group_egress_rules
    content {
      description = lookup(egress.value, "description", "")
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = lookup(egress.value, "cidr_blocks", [])
      security_groups = lookup(egress.value, "security_groups", [])
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nlb-sg"
  })
}

################################################################################
# Route 53 Record (optional)
################################################################################

resource "aws_route53_record" "nlb" {
  count = var.create_nlb && var.create_route53_record ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.route53_record_name
  type    = "A"

  alias {
    name                   = aws_lb.public_nlb[0].dns_name
    zone_id                = aws_lb.public_nlb[0].zone_id
    evaluate_target_health = var.route53_evaluate_target_health
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nlb-dns"
  })
}

################################################################################
# CloudWatch Alarms (optional)
################################################################################

resource "aws_cloudwatch_metric_alarm" "nlb_healthy_host_count" {
  count = var.create_nlb && var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-nlb-healthy-host-count"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/NetworkELB"
  period              = "300"
  statistic           = "Average"
  threshold           = var.healthy_host_count_threshold
  alarm_description   = "This metric monitors healthy host count for NLB"
  alarm_actions       = var.alarm_actions

  dimensions = {
    LoadBalancer = aws_lb.public_nlb[0].arn_suffix
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "nlb_unhealthy_host_count" {
  count = var.create_nlb && var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-nlb-unhealthy-host-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/NetworkELB"
  period              = "300"
  statistic           = "Average"
  threshold           = var.unhealthy_host_count_threshold
  alarm_description   = "This metric monitors unhealthy host count for NLB"
  alarm_actions       = var.alarm_actions

  dimensions = {
    LoadBalancer = aws_lb.public_nlb[0].arn_suffix
  }

  tags = local.common_tags
}