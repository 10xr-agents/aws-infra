#------------------------------------------------------------------------------
# n8n Module - ALB Target Groups and Listener Rules
# Host-based routing for main UI and webhook endpoints
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Target Group - n8n Main
#------------------------------------------------------------------------------

resource "aws_lb_target_group" "n8n_main" {
  name_prefix          = "n8nmn-"
  port                 = var.n8n_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = merge(local.default_tags, {
    Name    = "${local.name_prefix}-main-tg"
    Service = "n8n-main"
  })

  lifecycle {
    create_before_destroy = true
  }
}

#------------------------------------------------------------------------------
# Target Group - n8n Webhook
#------------------------------------------------------------------------------

resource "aws_lb_target_group" "n8n_webhook" {
  name_prefix          = "n8nwh-"
  port                 = var.n8n_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = merge(local.default_tags, {
    Name    = "${local.name_prefix}-webhook-tg"
    Service = "n8n-webhook"
  })

  lifecycle {
    create_before_destroy = true
  }
}

#------------------------------------------------------------------------------
# Listener Rule - n8n Main UI
#------------------------------------------------------------------------------

resource "aws_lb_listener_rule" "n8n_main" {
  listener_arn = var.alb_listener_arn
  priority     = var.listener_rule_priority_main

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.n8n_main.arn
  }

  condition {
    host_header {
      values = [var.main_host_header]
    }
  }

  tags = merge(local.default_tags, {
    Name    = "${local.name_prefix}-main-rule"
    Service = "n8n-main"
  })
}

#------------------------------------------------------------------------------
# Listener Rule - n8n Webhook
#------------------------------------------------------------------------------

resource "aws_lb_listener_rule" "n8n_webhook" {
  listener_arn = var.alb_listener_arn
  priority     = var.listener_rule_priority_webhook

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.n8n_webhook.arn
  }

  condition {
    host_header {
      values = [var.webhook_host_header]
    }
  }

  tags = merge(local.default_tags, {
    Name    = "${local.name_prefix}-webhook-rule"
    Service = "n8n-webhook"
  })
}
