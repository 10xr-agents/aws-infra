# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.18.1"

  name = local.name
  cidr = var.vpc_cidr

  azs = local.azs

  # Assign subnets
  public_subnets      = chunklist(local.public_subnets, length(local.azs))[0]
  private_subnets     = chunklist(local.private_subnets, length(local.azs))[0]
  elasticache_subnets = chunklist(local.elasticache_subnets, length(local.azs))[0]

  # Enable NAT Gateway for private subnets
  enable_nat_gateway   = true
  one_nat_gateway_per_az = true

  # Enable IPv6
  enable_ipv6 = true

  # Add VPC flow log improvements
  flow_log_cloudwatch_log_group_retention_in_days = 30
  flow_log_traffic_type = "ALL"  # Capture all traffic instead of just rejected traffic

  # Create IPv6 CIDR blocks for public and private subnets
  public_subnet_ipv6_prefixes = range(0, length(local.azs))
  private_subnet_ipv6_prefixes = range(length(local.azs), length(local.azs) * 2)
  elasticache_subnet_ipv6_prefixes = range(length(local.azs) * 2, length(local.azs) * 3)

  public_subnet_assign_ipv6_address_on_creation  = true
  private_subnet_assign_ipv6_address_on_creation = true

  # VPC Flow Logs
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 600

  # Network ACLs
  default_network_acl_tags      = local.tags
  default_route_table_tags      = local.tags
  default_security_group_tags   = local.tags

  # Tags
  tags                    = local.tags
  private_subnet_tags     = merge(local.tags, var.private_subnet_tags, {
    Tier = "private"
  })
  public_subnet_tags      = merge(local.tags, var.public_subnet_tags, {
    Tier = "public"
  })
  elasticache_subnet_tags = merge(local.tags, var.private_subnet_tags, {
    Tier = "elastic-cache"
  })
}

# CloudWatch Alarm for NAT Gateway Errors
resource "aws_cloudwatch_metric_alarm" "nat_gateway_errors" {
  count = length(local.azs)
  alarm_name          = "${local.name}-nat-gateway-errors-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorPortAllocation"
  namespace           = "AWS/NATGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors NAT gateway port allocation errors"
  alarm_actions       = var.alarm_actions

  dimensions = {
    NatGatewayId = module.vpc.natgw_ids[count.index]
  }

  tags = local.tags

  depends_on = [
    module.vpc
  ]
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.17"

  vpc_id = module.vpc.vpc_id

  create_security_group      = true
  security_group_name_prefix = "${local.name}-vpc-endpoints-"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
    egress_all = {
      description = "All outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      type        = "egress"
    }
    ingress_all = {
      description = "Allow access to all inbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      type        = "ingress"
    }
  }
  security_group_tags = local.tags

  endpoints = merge({
    s3 = {
      service             = "s3"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      dns_options = {
        private_dns_only_for_inbound_resolver_endpoint = false
      }
      tags = { Name = "s3-vpc-endpoint" }
    }
  }, {
    for service in toset([
      "ecr.api",
      "ecr.dkr",
      "sts",
      "autoscaling",
      "ec2",
      "ec2messages",
      "elasticache",
      "elasticloadbalancing",
      "events",
      "execute-api",
      "kms",
      "logs",
      "monitoring",
      "rds",
      "sqs",
      "sns",
      "ssm",
      "ssmmessages",
      "secretsmanager",
    ]) :
    replace(service, ".", "_") => {
      service             = service
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags = merge(local.tags, { Name = "${local.name}-${service}" })
    }
  })

  tags = merge(local.tags, {
    Project  = var.project_name
    Endpoint = "true"
  })
}