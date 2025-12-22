# environments/qa/terraform.tfvars

# AWS Region
region      = "us-east-1"
environment = "qa"

# Cluster Configuration
cluster_name = "ten-xr-app"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]

private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

enable_nat_gateway      = true
single_nat_gateway      = false
one_nat_gateway_per_az  = true
map_public_ip_on_launch = true

# ECS Configuration
enable_container_insights = true
enable_fargate            = true
enable_fargate_spot       = true

# SSL Configuration
ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"

################################################################################
# ECS Services Configuration
# Only two services: Home Health and Hospice (Next.js applications)
################################################################################
ecs_services = {
  "home-health" = {
    image         = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/home-health"
    image_tag     = "latest"
    port          = 3000
    cpu           = 1024
    memory        = 2048
    desired_count = 2

    environment = {
      # Basic Next.js configuration
      PORT = "3000"
    }

    secrets = [] # Secrets are injected via locals.tf

    capacity_provider_strategy = [
      {
        capacity_provider = "FARGATE"
        weight            = 1
        base              = 1
      },
      {
        capacity_provider = "FARGATE_SPOT"
        weight            = 1
        base              = 0
      }
    ]

    container_health_check = {
      command      = "curl -f http://localhost:3000/api/health || exit 1"
      interval     = 30
      timeout      = 10
      start_period = 60
      retries      = 3
    }

    health_check = {
      path                = "/api/health"
      interval            = 30
      timeout             = 10
      healthy_threshold   = 2
      unhealthy_threshold = 3
      matcher             = "200"
    }

    enable_auto_scaling        = true
    auto_scaling_min_capacity  = 2
    auto_scaling_max_capacity  = 6
    auto_scaling_cpu_target    = 70
    auto_scaling_memory_target = 80

    enable_default_routing   = false
    alb_host_headers         = ["homehealth.qa.10xr.co"]
    enable_load_balancer     = true
    enable_service_discovery = true
    deregistration_delay     = 30

    additional_task_policies = {} # IAM policies are added via locals.tf
  }

  "hospice" = {
    image         = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/hospice"
    image_tag     = "latest"
    port          = 3000
    cpu           = 1024
    memory        = 2048
    desired_count = 2

    environment = {
      # Basic Next.js configuration
      PORT = "3000"
    }

    secrets = [] # Secrets are injected via locals.tf

    capacity_provider_strategy = [
      {
        capacity_provider = "FARGATE"
        weight            = 1
        base              = 1
      },
      {
        capacity_provider = "FARGATE_SPOT"
        weight            = 1
        base              = 0
      }
    ]

    container_health_check = {
      command      = "curl -f http://localhost:3000/api/health || exit 1"
      interval     = 30
      timeout      = 10
      start_period = 60
      retries      = 3
    }

    health_check = {
      path                = "/api/health"
      interval            = 30
      timeout             = 10
      healthy_threshold   = 2
      unhealthy_threshold = 3
      matcher             = "200"
    }

    enable_auto_scaling        = true
    auto_scaling_min_capacity  = 2
    auto_scaling_max_capacity  = 6
    auto_scaling_cpu_target    = 70
    auto_scaling_memory_target = 80

    enable_default_routing   = false
    alb_host_headers         = ["hospice.qa.10xr.co"]
    enable_load_balancer     = true
    enable_service_discovery = true
    deregistration_delay     = 30

    additional_task_policies = {} # IAM policies are added via locals.tf
  }
}

################################################################################
# NLB Configuration
################################################################################
create_nlb                           = true
nlb_internal                         = false
nlb_enable_cross_zone_load_balancing = true

# Target Group Configuration
create_http_target_group = true
http_port                = 80
https_port               = 443
target_type              = "alb"
deregistration_delay     = 30

# Health Check Configuration
health_check_enabled             = true
health_check_healthy_threshold   = 2
health_check_interval            = 30
health_check_port                = "traffic-port"
health_check_protocol            = "HTTP"
health_check_timeout             = 6
health_check_unhealthy_threshold = 2
health_check_path                = "/"
health_check_matcher             = "200"

# Listener Configuration
create_http_listener = true

enable_bastion_host = true

# Cloudflare Configuration
# NOTE: cloudflare_api_token is stored in Terraform Cloud as a sensitive variable
cloudflare_zone_id    = "4245045dafc1829a6980697902b755b3"
cloudflare_account_id = "929c1d893cb7bb8455e151ae08f3b538"
cloudflare_email      = "jaswanth@10xr.co"
enable_cloudflare_dns = true

# Domain Configuration
################################################################################
domain = "qa.10xr.co"

# DNS is managed automatically via Cloudflare (see cloudflare_dns module)
# Records created: *.qa.10xr.co, homehealth.qa.10xr.co, hospice.qa.10xr.co, n8n.qa.10xr.co, webhook.n8n.qa.10xr.co

################################################################################
# HIPAA Configuration (Relaxed for QA/Staging)
# Production should use defaults (stricter settings)
################################################################################
hipaa_config = {
  # Reduced log retention for QA (30 days instead of 6 years)
  log_retention_days = 30

  # Reduced data retention for QA (90 days instead of 6 years)
  data_retention_days = 90

  # Reduced backup retention for QA (7 days instead of 35)
  backup_retention_days = 7

  # Disable deletion protection in QA for easier teardown
  enable_deletion_protection = false

  # Allow S3 buckets to be destroyed in QA
  s3_force_destroy = true

  # Allow skipping final snapshot in QA
  skip_final_snapshot = true

  # Still enable access logging for debugging
  enable_access_logging = true

  # Still enable CloudWatch alarms for monitoring
  enable_cloudwatch_alarms = true

  # Still enable audit logging for debugging
  enable_audit_logging = true
}

################################################################################
# n8n Workflow Automation Configuration (Starter Tier)
# Scale to Growth/Production by changing these values
################################################################################
n8n_config = {
  # Host headers for ALB routing (configure external DNS to point to NLB)
  main_host_header    = "n8n.qa.10xr.co"
  webhook_host_header = "webhook.n8n.qa.10xr.co"

  # RDS PostgreSQL - Starter tier (~$15/month)
  db_instance_class        = "db.t3.micro"
  db_allocated_storage     = 20
  db_max_allocated_storage = 100
  db_multi_az              = false

  # Redis - Starter tier (~$13/month)
  redis_node_type          = "cache.t3.micro"
  redis_num_cache_clusters = 1
  redis_multi_az           = false

  # n8n Main Service - Starter tier
  main_cpu                 = 512
  main_memory              = 1024
  main_desired_count       = 1
  main_min_capacity        = 1
  main_max_capacity        = 3
  main_enable_auto_scaling = true

  # n8n Webhook Service - Starter tier
  webhook_cpu                 = 256
  webhook_memory              = 512
  webhook_desired_count       = 1
  webhook_min_capacity        = 1
  webhook_max_capacity        = 4
  webhook_enable_auto_scaling = true

  # n8n Worker Service - Starter tier
  worker_cpu                 = 512
  worker_memory              = 1024
  worker_desired_count       = 1
  worker_min_capacity        = 1
  worker_max_capacity        = 6
  worker_enable_auto_scaling = true
  worker_concurrency         = 5

  # n8n Application
  n8n_image     = "n8nio/n8n"
  n8n_image_tag = "latest"
  n8n_timezone  = "America/New_York"
}

################################################################################
# Tags
################################################################################
tags = {
  Environment = "qa"
  Project     = "10xR HealthCare"
  Platform    = "Application"
  Terraform   = "true"
  HIPAA       = "false" # QA uses relaxed HIPAA settings
}
