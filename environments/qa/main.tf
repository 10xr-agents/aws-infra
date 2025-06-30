# environments/qa/main.tf

locals {
  cluster_name = "${var.cluster_name}-${var.environment}"
  vpc_name     = "${var.cluster_name}-${var.environment}-${var.region}"
}

# VPC Module - Reuse existing VPC module
module "vpc" {
  source = "../../modules/vpc"

  environment = var.environment

  vpc_name = local.vpc_name
  vpc_cidr = var.vpc_cidr
  azs      = var.azs

  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets

  map_public_ip_on_launch = var.map_public_ip_on_launch

  # ECS specific tags
  cluster_name = local.cluster_name

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-Agents"
      "Platform"    = "AWS"
      "Terraform"   = "true"
    }
  )
}

# MongoDB Cluster Module
module "mongodb" {
  source = "../../modules/mongodb"

  cluster_name = "${local.cluster_name}-mongodb"
  environment  = var.environment

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.database_subnets  # Using database subnets for MongoDB

  # Instance configuration
  replica_count = var.mongodb_replica_count
  instance_type = var.mongodb_instance_type
  ami_id        = var.mongodb_ami_id
  # Removed key_name - key pair will be created automatically

  # MongoDB configuration
  mongodb_version         = var.mongodb_version
  mongodb_admin_username  = var.mongodb_admin_username
  mongodb_admin_password  = var.mongodb_admin_password
  mongodb_keyfile_content = var.mongodb_keyfile_content
  default_database = var.mongodb_default_database

  # Storage configuration
  root_volume_size = var.mongodb_root_volume_size
  data_volume_size = var.mongodb_data_volume_size
  data_volume_type = var.mongodb_data_volume_type
  data_volume_iops = var.mongodb_data_volume_iops
  data_volume_throughput = var.mongodb_data_volume_throughput

  # Security configuration
  create_security_group = true
  allowed_cidr_blocks = [module.vpc.vpc_cidr_block]
  additional_security_group_ids = []
  allow_ssh             = var.mongodb_allow_ssh
  ssh_cidr_blocks = var.mongodb_ssh_cidr_blocks

  # Monitoring and logging
  enable_monitoring = var.mongodb_enable_monitoring
  log_retention_days = var.mongodb_log_retention_days

  # DNS configuration
  create_dns_records = var.mongodb_create_dns_records
  private_domain = var.mongodb_private_domain

  # Backup configuration
  backup_enabled  = var.mongodb_backup_enabled
  backup_schedule = var.mongodb_backup_schedule
  backup_retention_days = var.mongodb_backup_retention_days

  # Additional features
  store_connection_string_in_ssm = var.mongodb_store_connection_string_in_ssm
  enable_encryption_at_rest      = var.mongodb_enable_encryption_at_rest
  enable_audit_logging           = var.mongodb_enable_audit_logging

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-Agents"
      "Component"   = "MongoDB"
      "Platform"    = "AWS"
      "Terraform"   = "true"
    }
  )

  depends_on = [module.vpc]
}

# Application Load Balancer Module
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.17.0"

  name               = "${local.cluster_name}-alb"
  load_balancer_type = "application"

  vpc_id = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  # ALB Configuration
  enable_deletion_protection = var.alb_enable_deletion_protection
  enable_http2               = var.alb_enable_http2
  idle_timeout = var.alb_idle_timeout

  # Security Groups
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "HTTP web traffic"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "HTTPS web traffic"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "All outbound traffic"
    }
  }

  # Target Groups for each service
  target_groups = {
    for service_name, service_config in local.ecs_services_with_overrides : service_name => {
      name_prefix = substr(service_name, 0, 6)
      protocol    = "HTTP"
      port        = service_config.port
      target_type = "ip"
      deregistration_delay = lookup(service_config, "deregistration_delay", 30)

      health_check = {
        enabled  = true
        healthy_threshold = lookup(service_config.health_check, "healthy_threshold", 2)
        interval = lookup(service_config.health_check, "interval", 30)
        matcher = lookup(service_config.health_check, "matcher", "200")
        path = lookup(service_config.health_check, "path", "/health")
        port     = "traffic-port"
        protocol = "HTTP"
        timeout = lookup(service_config.health_check, "timeout", 20)
        unhealthy_threshold = lookup(service_config.health_check, "unhealthy_threshold", 3)
      }

      create_attachment = false
    }
  }

  # HTTP Listener
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      # Redirect to HTTPS if certificate is provided
      default_actions = var.acm_certificate_arn != "" ? [
        {
          type = "redirect"
          redirect = {
            port        = "443"
            protocol    = "HTTPS"
            status_code = "HTTP_301"
          }
          target_group_key = null
        }
      ] : [
        {
          type             = "forward"
          redirect         = null
          target_group_key = "ui-console" # Default to UI console
        }
      ]
    }

    # HTTPS Listener (if certificate is provided)
    https = var.acm_certificate_arn != "" ? {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.acm_certificate_arn
      ssl_policy      = var.ssl_policy

      default_actions = [
        {
          type             = "forward"
          target_group_key = "ui-console" # Default to UI console
        }
      ]

      # Rules for each service based on path patterns
      rules = {
        for service_name, service_config in local.ecs_services_with_overrides : service_name => {
          priority = 100 + index(keys(local.ecs_services_with_overrides), service_name)

          conditions = [
            {
              path_pattern = {
                values = lookup(service_config, "alb_path_patterns", ["/${service_name}/*"])
              }
            }
          ]

          actions = [
            {
              type             = "forward"
              target_group_key = service_name
            }
          ]
        } if lookup(service_config, "alb_path_patterns", null) != null
      }
    } : null
  }

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Project"     = "10xR-Agents"
      "Component"   = "ALB"
      "Platform"    = "AWS"
      "Terraform"   = "true"
    }
  )
}

# ECS Cluster Module
module "ecs" {
  source = "../../modules/ecs"

  cluster_name = var.cluster_name
  environment  = var.environment

  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnets
  alb_security_group_id = module.alb.security_group_id

  acm_certificate_arn = ""
  create_alb_rules    = true

  enable_container_insights = var.enable_container_insights
  enable_execute_command    = var.enable_execute_command
  enable_service_discovery  = true
  create_alb = true

  # Pass the entire services configuration from variables
  services = local.ecs_services_with_overrides

  tags = var.tags

  depends_on = [module.mongodb]
}