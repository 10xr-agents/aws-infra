# modules/ecs/security_groups.tf
# This file should replace the security group section in main.tf

################################################################################
# Security Groups for ECS Services
################################################################################

resource "aws_security_group" "ecs_service" {
  for_each = local.services_config

  name        = each.value.security_group_name
  description = "Security group for ECS service ${each.key}"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name    = each.value.security_group_name
    Service = each.key
  })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Security Group Rules - Separate Resources for Better Dependency Management
################################################################################

# Ingress from ALB (if ALB is enabled)
resource "aws_security_group_rule" "ecs_service_from_alb" {
  for_each = {
    for name, config in local.services_config : name => config
    if (var.create_alb || var.alb_security_group_id != "") && lookup(config, "enable_load_balancer", true)
  }

  type                     = "ingress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = "tcp"
  source_security_group_id = var.create_alb ? aws_security_group.alb[0].id : var.alb_security_group_id
  security_group_id        = aws_security_group.ecs_service[each.key].id
  description              = "Ingress from ALB"

  depends_on = [aws_security_group.ecs_service]
}

# Ingress for service-to-service communication within VPC
resource "aws_security_group_rule" "ecs_service_from_vpc" {
  for_each = local.services_config

  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.ecs_service[each.key].id
  description       = "Service to service communication within VPC"

  depends_on = [aws_security_group.ecs_service]
}

# Ingress from other ECS services (for service discovery)
resource "aws_security_group_rule" "ecs_service_from_self" {
  for_each = {
    for name, config in local.services_config : name => config
    if var.enable_service_discovery
  }

  type              = "ingress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.ecs_service[each.key].id
  description       = "Service discovery communication"

  depends_on = [aws_security_group.ecs_service]
}

# Egress to internet
resource "aws_security_group_rule" "ecs_service_to_internet" {
  for_each = local.services_config

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_service[each.key].id
  description       = "All outbound traffic"

  depends_on = [aws_security_group.ecs_service]
}

# Egress to Redis (if Redis security group is provided)
resource "aws_security_group_rule" "ecs_service_to_redis" {
  for_each = var.redis_security_group_id != "" ? local.services_config : {}

  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = var.redis_security_group_id
  security_group_id        = aws_security_group.ecs_service[each.key].id
  description              = "To Redis cluster"

  depends_on = [aws_security_group.ecs_service]
}

# Egress to MongoDB (if MongoDB security group is provided)
resource "aws_security_group_rule" "ecs_service_to_mongodb" {
  for_each = var.mongodb_security_group_id != "" ? local.services_config : {}

  type                     = "egress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = var.mongodb_security_group_id
  security_group_id        = aws_security_group.ecs_service[each.key].id
  description              = "To MongoDB cluster"

  depends_on = [aws_security_group.ecs_service]
}

################################################################################
# ALB Security Group (if creating ALB)
################################################################################

resource "aws_security_group" "alb" {
  count = var.create_alb ? 1 : 0

  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for ALB ${local.name_prefix}"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-alb-sg"
    Component = "SecurityGroup"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Security Group Rules
resource "aws_security_group_rule" "alb_http_ingress" {
  count = var.create_alb ? 1 : 0

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.alb_allowed_cidr_blocks
  security_group_id = aws_security_group.alb[0].id
  description       = "HTTP"

  depends_on = [aws_security_group.alb]
}

resource "aws_security_group_rule" "alb_https_ingress" {
  count = var.create_alb ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.alb_allowed_cidr_blocks
  security_group_id = aws_security_group.alb[0].id
  description       = "HTTPS"

  depends_on = [aws_security_group.alb]
}

resource "aws_security_group_rule" "alb_custom_ports_ingress" {
  for_each = var.create_alb ? toset([for port in var.alb_additional_ports : tostring(port)]) : []

  type              = "ingress"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  protocol          = "tcp"
  cidr_blocks       = var.alb_allowed_cidr_blocks
  security_group_id = aws_security_group.alb[0].id
  description       = "Custom port ${each.value}"

  depends_on = [aws_security_group.alb]
}

resource "aws_security_group_rule" "alb_to_ecs_services" {
  count = var.create_alb ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.alb[0].id
  description       = "To ECS services"

  depends_on = [aws_security_group.alb]
}

resource "aws_security_group_rule" "alb_internet_egress" {
  count = var.create_alb ? 1 : 0

  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb[0].id
  description       = "Internet egress"

  depends_on = [aws_security_group.alb]
}