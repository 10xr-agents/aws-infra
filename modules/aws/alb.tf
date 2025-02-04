# Application Load Balancer
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.13.0"

  name = "${local.name}-alb"

  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.alb_sg.security_group_id]

  # Access logs
  access_logs = {
    bucket = module.alb_logs.s3_bucket_id
    prefix = "alb-logs"
    enabled = true
  }

  target_groups = {
    for service in var.services : service.name => {
      name_prefix          = "svc-"
      backend_protocol     = "HTTP"
      backend_port         = service.port
      target_type         = "ip"
      deregistration_delay = 10
      health_check = {
        enabled             = true
        interval            = 30
        path               = service.health_check_path
        port               = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol           = "HTTP"
        matcher            = "200-299"
      }
    }
  }

  listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = local.tags
}

# ALB Security Group
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3.0"

  name        = "${local.name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}

# ALB Logs Bucket
module "alb_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.5.0"

  bucket = "${local.name}-alb-logs"
  acl    = "log-delivery-write"

  force_destroy = true

  attach_elb_log_delivery_policy = true
  attach_lb_log_delivery_policy  = true

  # Lifecycle rules
  lifecycle_rule = [
    {
      id      = "log"
      enabled = true

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 90
      }
    }
  ]

  tags = local.tags
}