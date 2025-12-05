# modules/vpc/main.tf

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.17"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs              = var.azs
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets

  create_database_subnet_group = var.create_database_subnet_group

  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az
  enable_vpn_gateway     = var.enable_vpn_gateway

  map_public_ip_on_launch = var.map_public_ip_on_launch

  # DNS configuration
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  # HIPAA requires 6 years (2192 days) retention for audit logs
  enable_flow_log                                 = var.enable_flow_log
  create_flow_log_cloudwatch_log_group            = var.create_flow_log_cloudwatch_log_group
  create_flow_log_cloudwatch_iam_role             = var.create_flow_log_cloudwatch_iam_role
  flow_log_max_aggregation_interval               = var.flow_log_max_aggregation_interval
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_log_cloudwatch_log_retention_days

  # Tags for subnet discovery by load balancers and cluster
  public_subnet_tags = {
    "Type" = "${var.cluster_name}-public"
  }

  private_subnet_tags = {
    "Type" = "${var.cluster_name}-private"
  }

  # Default security group configuration
  default_security_group_name = "${var.vpc_name}-default-sg"

  default_security_group_egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  ]

  default_security_group_tags = merge(
    var.tags,
    {
      "Name"        = "${var.vpc_name}-default-sg"
      "Environment" = var.environment
      "Project"     = "10xR-Agents"
      "Terraform"   = "true"
    }
  )

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-Agents"
      "Terraform"   = "true"
    }
  )
}

# VPC Endpoints for AWS services to reduce NAT Gateway costs and improve security
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.17"

  vpc_id = module.vpc.vpc_id

  create_security_group      = true
  security_group_name_prefix = "${module.vpc.name}-endpoints-"
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
  }
  security_group_tags = var.tags

  # Essential VPC Endpoints for HIPAA-compliant ECS/Fargate workloads
  # Cost-optimized: ~$176/month (8 endpoints × 3 AZs) vs ~$307/month (15 endpoints)
  #
  # Removed (will use NAT Gateway instead):
  # - ecs-telemetry: Optional telemetry, not critical
  # - autoscaling: Only needed for EC2 auto-scaling groups
  # - ec2: Only needed for EC2 instance API calls
  # - ec2messages: Only needed for SSM Session Manager to EC2
  # - elasticloadbalancing: ALB/NLB API calls are infrequent
  # - ssmmessages: Only needed for SSM Session Manager

  endpoints = merge({
    # Gateway Endpoint (FREE) - Required for ECR image layers
    s3 = {
      service             = "s3"
      service_type        = "Gateway"
      private_dns_enabled = true
      route_table_ids     = flatten([module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      tags                = { Name = "${module.vpc.name}-s3-vpc-endpoint" }
    }
  }, {
    # Interface Endpoints (Essential for ECS/Fargate + HIPAA)
    for service in toset([
      "ecr.api",        # Required: ECR API for image pulls
      "ecr.dkr",        # Required: Docker registry for image pulls
      "ecs",            # Required: ECS service API
      "ecs-agent",      # Required: ECS agent communication
      "sts",            # Required: IAM role assumption for tasks
      "kms",            # Required: Encryption/decryption (HIPAA)
      "logs",           # Required: CloudWatch Logs for containers
      "secretsmanager"  # Required: DocumentDB credentials (HIPAA)
    ]) :
    replace(service, ".", "_") => {
      service             = service
      service_type        = "Interface"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = merge(var.tags, { Name = "${module.vpc.name}-${service}" })
    }
  })

  tags = merge(var.tags, {
    Endpoint = "true"
  })
}

