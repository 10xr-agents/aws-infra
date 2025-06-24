# modules/alb/main.tf

/**
 * # Application Load Balancer Module
 *
 * This module creates an Application Load Balancer (ALB) for HTTP/HTTPS traffic
 * with support for multiple target groups and listeners.
 */

# Application Load Balancer
resource "aws_lb" "main" {
  name               = format("%.32s", "${var.cluster_name}-alb")
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.create_security_group ? [aws_security_group.alb[0].id] : var.security_group_ids
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2              = var.enable_http2
  idle_timeout              = var.idle_timeout

  enable_cross_zone_load_balancing = true

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-alb"
    }
  )
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
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
    var.tags,
    {
      Name = "${var.cluster_name}-alb-sg"
    }
  )
}

# Default Target Group
resource "aws_lb_target_group" "default" {
  name     = format("%.32s", "${var.cluster_name}-default-tg")
  port     = var.target_group_defaults.port
  protocol = var.target_group_defaults.protocol
  vpc_id   = var.vpc_id

  target_type          = var.target_group_defaults.target_type
  deregistration_delay = var.target_group_defaults.deregistration_delay

  health_check {
    enabled             = var.target_group_defaults.health_check_enabled
    interval            = var.target_group_defaults.health_check_interval
    path                = var.target_group_defaults.health_check_path
    timeout             = var.target_group_defaults.health_check_timeout
    healthy_threshold   = var.target_group_defaults.health_check_healthy_threshold
    unhealthy_threshold = var.target_group_defaults.health_check_unhealthy_threshold
    matcher             = var.target_group_defaults.health_check_matcher
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-default-tg"
    }
  )
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = var.certificate_arn != "" ? "redirect" : "forward"

    # Redirect to HTTPS if certificate is provided
    dynamic "redirect" {
      for_each = var.certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    # Forward to target group if no certificate
    dynamic "forward" {
      for_each = var.certificate_arn != "" ? [] : [1]
      content {
        target_group_arn = aws_lb_target_group.default.arn
      }
    }
  }
}

# HTTPS Listener (if certificate is provided)
resource "aws_lb_listener" "https" {
  count = var.certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }
}

# Additional certificates for HTTPS listener
resource "aws_lb_listener_certificate" "additional" {
  for_each = var.certificate_arn != "" ? toset(var.additional_certificate_arns) : []

  listener_arn    = aws_lb_listener.https[0].arn
  certificate_arn = each.value
}