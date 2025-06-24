# modules/nlb/main.tf

/**
 * # Network Load Balancer Module
 *
 * This module creates Network Load Balancers (NLBs) for TCP/UDP traffic
 * specifically designed for WebRTC (TURN) and SIP traffic.
 */

# Network Load Balancer for TURN traffic
resource "aws_lb" "turn" {
  count = var.create_turn_nlb ? 1 : 0

  name               = format("%.32s", "${var.cluster_name}-turn-nlb")
  internal           = false
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-turn-nlb"
      Service = "TURN"
    }
  )
}

# Target groups for TURN traffic
resource "aws_lb_target_group" "turn" {
  for_each = var.create_turn_nlb ? var.turn_ports : {}

  name        = format("%.32s", "${var.cluster_name}-turn-${each.key}")
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 30
    port                = each.value.health_check_port != null ? each.value.health_check_port : each.value.port
    protocol            = each.value.health_check_protocol != null ? each.value.health_check_protocol : "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  stickiness {
    enabled = true
    type    = "source_ip"
  }

  deregistration_delay = 30

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-turn-${each.key}-tg"
      Service = "TURN"
    }
  )
}

# Listeners for TURN traffic
resource "aws_lb_listener" "turn" {
  for_each = var.create_turn_nlb ? var.turn_ports : {}

  load_balancer_arn = aws_lb.turn[0].arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.turn[each.key].arn
  }
}

# Network Load Balancer for SIP traffic
resource "aws_lb" "sip" {
  count = var.create_sip_nlb ? 1 : 0

  name               = format("%.32s", "${var.cluster_name}-sip-nlb")
  internal           = false
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-sip-nlb"
      Service = "SIP"
    }
  )
}

# Target group for SIP signaling
resource "aws_lb_target_group" "sip_signaling" {
  count = var.create_sip_nlb ? 1 : 0

  name        = format("%.32s", "${var.cluster_name}-sip-signal")
  port        = var.sip_ports.signaling.port
  protocol    = var.sip_ports.signaling.protocol
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 30
    port                = var.sip_ports.signaling.port
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  stickiness {
    enabled = true
    type    = "source_ip"
  }

  deregistration_delay = 30

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-sip-signaling-tg"
      Service = "SIP"
    }
  )
}

# Listener for SIP signaling
resource "aws_lb_listener" "sip_signaling" {
  count = var.create_sip_nlb ? 1 : 0

  load_balancer_arn = aws_lb.sip[0].arn
  port              = var.sip_ports.signaling.port
  protocol          = var.sip_ports.signaling.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sip_signaling[0].arn
  }
}

# Security group for NLB traffic (if needed for IP targets)
resource "aws_security_group" "nlb" {
  name        = "${var.cluster_name}-nlb-sg"
  description = "Security group for NLB traffic"
  vpc_id      = var.vpc_id

  # TURN UDP
  dynamic "ingress" {
    for_each = var.create_turn_nlb ? { for k, v in var.turn_ports : k => v if v.protocol == "UDP" } : {}
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "TURN ${ingress.key} traffic"
    }
  }

  # TURN TCP
  dynamic "ingress" {
    for_each = var.create_turn_nlb ? { for k, v in var.turn_ports : k => v if v.protocol == "TCP" } : {}
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "TURN ${ingress.key} traffic"
    }
  }

  # SIP signaling
  dynamic "ingress" {
    for_each = var.create_sip_nlb ? [var.sip_ports.signaling] : []
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = lower(ingress.value.protocol)
      cidr_blocks = ["0.0.0.0/0"]
      description = "SIP signaling traffic"
    }
  }

  # RTP port range for SIP
  dynamic "ingress" {
    for_each = var.create_sip_nlb ? [1] : []
    content {
      from_port   = var.sip_ports.rtp_start.port
      to_port     = var.sip_ports.rtp_end.port
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SIP RTP media traffic"
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
      Name = "${var.cluster_name}-nlb-sg"
    }
  )
}