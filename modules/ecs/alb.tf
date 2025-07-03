# modules/ecs/alb.tf

locals {
  # Find the service with enable_default_routing = true
  default_routing_service = try([
    for name, config in local.services_config : name
    if lookup(config, "enable_default_routing", false) == true && lookup(config, "enable_load_balancer", true) == true
  ][0], null)

  # Determine the default target group ARN based on enable_default_routing
  default_target_group_arn = var.default_target_group_arn != "" ? var.default_target_group_arn : (
    local.default_routing_service != null ? aws_lb_target_group.service[local.default_routing_service].arn : (
    var.create_default_target_group ? aws_lb_target_group.alb_default[0].arn : (
    length(aws_lb_target_group.service) > 0 ? values(aws_lb_target_group.service)[0].arn : null
  )
  )
  )
}

################################################################################
# Application Load Balancer
################################################################################

resource "aws_lb" "main" {
  count = var.create_alb ? 1 : 0

  name               = "${local.name_prefix}-alb"
  internal           = var.alb_internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]

  # Fixed: Ensure we have at least 2 subnets in different AZs
  subnets = var.alb_internal ? (
    length(var.private_subnet_ids) >= 2 ? var.private_subnet_ids :
    concat(var.private_subnet_ids, var.public_subnet_ids)
  ) : (
    length(var.public_subnet_ids) >= 2 ? var.public_subnet_ids :
    concat(var.public_subnet_ids, var.private_subnet_ids)
  )

  # ALB Configuration
  enable_deletion_protection       = var.alb_enable_deletion_protection
  enable_http2                    = var.alb_enable_http2
  enable_cross_zone_load_balancing = var.alb_enable_cross_zone_load_balancing
  idle_timeout                    = var.alb_idle_timeout
  enable_waf_fail_open           = var.alb_enable_waf_fail_open

  # Access logs
  dynamic "access_logs" {
    for_each = var.alb_access_logs_enabled ? [1] : []
    content {
      bucket  = var.alb_access_logs_bucket
      prefix  = var.alb_access_logs_prefix
      enabled = true
    }
  }

  # Connection logs
  dynamic "connection_logs" {
    for_each = var.alb_connection_logs_enabled ? [1] : []
    content {
      bucket  = var.alb_connection_logs_bucket
      prefix  = var.alb_connection_logs_prefix
      enabled = true
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-alb"
    Component = "LoadBalancer"
  })
}

################################################################################
# ALB Security Group
################################################################################

resource "aws_security_group" "alb" {
  count = var.create_alb ? 1 : 0

  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for ALB ${local.name_prefix}"
  vpc_id      = var.vpc_id

  # HTTP ingress
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_allowed_cidr_blocks
  }

  # HTTPS ingress
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.alb_allowed_cidr_blocks
  }

  # Custom port ingress (if specified)
  dynamic "ingress" {
    for_each = var.alb_additional_ports
    content {
      description = "Custom port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.alb_allowed_cidr_blocks
    }
  }

  # Egress to ECS services
  egress {
    description = "To ECS services"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # Internet egress (for health checks, etc.)
  egress {
    description = "Internet egress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-alb-sg"
    Component = "SecurityGroup"
  })
}

################################################################################
# Default Target Group for ALB
################################################################################

resource "aws_lb_target_group" "alb_default" {
  count = var.create_alb && var.create_default_target_group ? 1 : 0

  name        = "${local.name_prefix}-default-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,404"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  deregistration_delay = 30

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-default-tg"
    Component = "TargetGroup"
  })

  depends_on = [aws_lb.main]
}

################################################################################
# HTTP Listener
################################################################################

resource "aws_lb_listener" "http" {
  count = var.create_alb ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = "80"
  protocol          = "HTTP"

  # Default action - redirect to HTTPS if certificate provided, otherwise forward
  default_action {
    type = var.acm_certificate_arn != "" ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.acm_certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "forward" {
      for_each = var.acm_certificate_arn == "" ? [1] : []
      content {
        target_group {
          arn = local.default_target_group_arn
        }
      }
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-http-listener"
    Component = "Listener"
  })
}

################################################################################
# HTTPS Listener
################################################################################

resource "aws_lb_listener" "https" {
  count = var.create_alb && var.acm_certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.acm_certificate_arn

  # Default action
  default_action {
    type = "forward"
    forward {
      target_group {
        arn = local.default_target_group_arn
      }
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-https-listener"
    Component = "Listener"
  })
}

################################################################################
# Listener Rules for Service Routing
################################################################################

# Host-based routing rules for HTTP
resource "aws_lb_listener_rule" "http_host_rules" {
  for_each = var.create_alb ? {
    for name, config in local.services_config : name => config
    if lookup(config, "enable_load_balancer", true) &&
    lookup(config, "alb_host_headers", null) != null
  } : {}

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 100 + index(keys(local.services_config), each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  condition {
    host_header {
      values = each.value.alb_host_headers
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-${each.key}-host-rule"
    Service   = each.key
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.http,
    aws_lb_target_group.service
  ]
}

# Host-based routing rules for HTTPS
resource "aws_lb_listener_rule" "https_host_rules" {
  for_each = var.create_alb && var.acm_certificate_arn != "" ? {
    for name, config in local.services_config : name => config
    if lookup(config, "enable_load_balancer", true) &&
    lookup(config, "alb_host_headers", null) != null
  } : {}

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100 + index(keys(local.services_config), each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  condition {
    host_header {
      values = each.value.alb_host_headers
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-${each.key}-host-rule"
    Service   = each.key
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.https,
    aws_lb_target_group.service
  ]
}

# Path-based routing rules for HTTP (if not redirecting to HTTPS)
resource "aws_lb_listener_rule" "http_path_rules" {
  for_each = var.create_alb ? {
    for name, config in local.services_config : name => config
    if lookup(config, "enable_load_balancer", true) &&
    lookup(config, "alb_path_patterns", null) != null
  } : {}

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 200 + index(keys(local.services_config), each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value.alb_path_patterns
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-${each.key}-path-rule"
    Service   = each.key
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.http,
    aws_lb_target_group.service
  ]
}

# Path-based routing rules for HTTPS
resource "aws_lb_listener_rule" "https_path_rules" {
  for_each = var.create_alb && var.acm_certificate_arn != "" ? {
    for name, config in local.services_config : name => config
    if lookup(config, "enable_load_balancer", true) &&
    lookup(config, "alb_path_patterns", null) != null
  } : {}

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 200 + index(keys(local.services_config), each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value.alb_path_patterns
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-${each.key}-path-rule"
    Service   = each.key
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.https,
    aws_lb_target_group.service
  ]
}

################################################################################
# Data Sources
################################################################################

data "aws_vpc" "main" {
  id = var.vpc_id
}