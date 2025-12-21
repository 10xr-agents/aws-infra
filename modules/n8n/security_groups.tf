#------------------------------------------------------------------------------
# n8n Module - Security Groups
# Separate security groups for main, webhook, and worker services
#------------------------------------------------------------------------------

data "aws_vpc" "selected" {
  id = var.vpc_id
}

#------------------------------------------------------------------------------
# n8n Main Security Group
#------------------------------------------------------------------------------

resource "aws_security_group" "n8n_main" {
  name_prefix = "${local.name_prefix}-main-"
  description = "Security group for n8n main service"
  vpc_id      = var.vpc_id

  tags = merge(local.default_tags, {
    Name    = "${local.name_prefix}-main-sg"
    Service = "n8n-main"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Ingress: From ALB
resource "aws_vpc_security_group_ingress_rule" "n8n_main_from_alb" {
  security_group_id            = aws_security_group.n8n_main.id
  description                  = "n8n port from ALB"
  from_port                    = var.n8n_port
  to_port                      = var.n8n_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.alb_security_group_id

  tags = local.default_tags
}

# Egress: To PostgreSQL
resource "aws_vpc_security_group_egress_rule" "n8n_main_to_postgres" {
  security_group_id            = aws_security_group.n8n_main.id
  description                  = "PostgreSQL to RDS"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.rds.security_group_id

  tags = local.default_tags
}

# Egress: To Redis
resource "aws_vpc_security_group_egress_rule" "n8n_main_to_redis" {
  count = var.redis_security_group_id != null ? 1 : 0

  security_group_id            = aws_security_group.n8n_main.id
  description                  = "Redis for queue"
  from_port                    = var.redis_port
  to_port                      = var.redis_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.redis_security_group_id

  tags = local.default_tags
}

# Egress: HTTPS for external APIs and AWS services
resource "aws_vpc_security_group_egress_rule" "n8n_main_https" {
  security_group_id = aws_security_group.n8n_main.id
  description       = "HTTPS for external APIs and AWS services"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = local.default_tags
}

# Egress: HTTP for some external APIs
resource "aws_vpc_security_group_egress_rule" "n8n_main_http" {
  security_group_id = aws_security_group.n8n_main.id
  description       = "HTTP for external APIs"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = local.default_tags
}

#------------------------------------------------------------------------------
# n8n Webhook Security Group
#------------------------------------------------------------------------------

resource "aws_security_group" "n8n_webhook" {
  name_prefix = "${local.name_prefix}-webhook-"
  description = "Security group for n8n webhook service"
  vpc_id      = var.vpc_id

  tags = merge(local.default_tags, {
    Name    = "${local.name_prefix}-webhook-sg"
    Service = "n8n-webhook"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Ingress: From ALB
resource "aws_vpc_security_group_ingress_rule" "n8n_webhook_from_alb" {
  security_group_id            = aws_security_group.n8n_webhook.id
  description                  = "n8n port from ALB"
  from_port                    = var.n8n_port
  to_port                      = var.n8n_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.alb_security_group_id

  tags = local.default_tags
}

# Egress: To PostgreSQL
resource "aws_vpc_security_group_egress_rule" "n8n_webhook_to_postgres" {
  security_group_id            = aws_security_group.n8n_webhook.id
  description                  = "PostgreSQL to RDS"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.rds.security_group_id

  tags = local.default_tags
}

# Egress: To Redis
resource "aws_vpc_security_group_egress_rule" "n8n_webhook_to_redis" {
  count = var.redis_security_group_id != null ? 1 : 0

  security_group_id            = aws_security_group.n8n_webhook.id
  description                  = "Redis for queue"
  from_port                    = var.redis_port
  to_port                      = var.redis_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.redis_security_group_id

  tags = local.default_tags
}

# Egress: HTTPS for external APIs and AWS services
resource "aws_vpc_security_group_egress_rule" "n8n_webhook_https" {
  security_group_id = aws_security_group.n8n_webhook.id
  description       = "HTTPS for external APIs and AWS services"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = local.default_tags
}

# Egress: HTTP for some external APIs
resource "aws_vpc_security_group_egress_rule" "n8n_webhook_http" {
  security_group_id = aws_security_group.n8n_webhook.id
  description       = "HTTP for external APIs"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = local.default_tags
}

#------------------------------------------------------------------------------
# n8n Worker Security Group
#------------------------------------------------------------------------------

resource "aws_security_group" "n8n_worker" {
  name_prefix = "${local.name_prefix}-worker-"
  description = "Security group for n8n worker service"
  vpc_id      = var.vpc_id

  tags = merge(local.default_tags, {
    Name    = "${local.name_prefix}-worker-sg"
    Service = "n8n-worker"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Worker has no ingress rules - internal processing only

# Egress: To PostgreSQL
resource "aws_vpc_security_group_egress_rule" "n8n_worker_to_postgres" {
  security_group_id            = aws_security_group.n8n_worker.id
  description                  = "PostgreSQL to RDS"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.rds.security_group_id

  tags = local.default_tags
}

# Egress: To Redis
resource "aws_vpc_security_group_egress_rule" "n8n_worker_to_redis" {
  count = var.redis_security_group_id != null ? 1 : 0

  security_group_id            = aws_security_group.n8n_worker.id
  description                  = "Redis for queue"
  from_port                    = var.redis_port
  to_port                      = var.redis_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.redis_security_group_id

  tags = local.default_tags
}

# Egress: HTTPS for external APIs and AWS services
resource "aws_vpc_security_group_egress_rule" "n8n_worker_https" {
  security_group_id = aws_security_group.n8n_worker.id
  description       = "HTTPS for external APIs and AWS services"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = local.default_tags
}

# Egress: HTTP for some external APIs
resource "aws_vpc_security_group_egress_rule" "n8n_worker_http" {
  security_group_id = aws_security_group.n8n_worker.id
  description       = "HTTP for external APIs"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = local.default_tags
}
