# environments/qa/terraform.tfvars

# AWS Region
region = "us-east-1"
environment = "qa"

# Cluster Configuration
cluster_name = "ten-xr-app"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]

private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

enable_nat_gateway     = true
single_nat_gateway     = false
one_nat_gateway_per_az = true
map_public_ip_on_launch = true

# ECS Configuration
enable_container_insights = true
enable_fargate           = true
enable_fargate_spot      = true

# SSL Configuration
ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"

################################################################################
# ECS Services Configuration
# Only two services: Home Health and Hospice (Next.js applications)
################################################################################
ecs_services = {
  "home-health" = {
    image     = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/home-health"
    image_tag = "latest"
    port      = 3000
    cpu       = 1024
    memory    = 2048
    desired_count = 2

    environment = {
      # Basic Next.js configuration
      PORT = "3000"
    }

    secrets = []  # Secrets are injected via locals.tf

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

    additional_task_policies = {}  # IAM policies are added via locals.tf
  }

  "hospice" = {
    image     = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/hospice"
    image_tag = "latest"
    port      = 3000
    cpu       = 1024
    memory    = 2048
    desired_count = 2

    environment = {
      # Basic Next.js configuration
      PORT = "3000"
    }

    secrets = []  # Secrets are injected via locals.tf

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

    additional_task_policies = {}  # IAM policies are added via locals.tf
  }
}

################################################################################
# NLB Configuration
################################################################################
create_nlb = true
nlb_internal = false
nlb_enable_deletion_protection = true  # HIPAA compliance
nlb_enable_cross_zone_load_balancing = true

# Target Group Configuration
create_http_target_group = true
http_port = 80
https_port = 443
target_type = "alb"
deregistration_delay = 30

# Health Check Configuration
health_check_enabled = true
health_check_healthy_threshold = 2
health_check_interval = 30
health_check_port = "traffic-port"
health_check_protocol = "HTTP"
health_check_timeout = 6
health_check_unhealthy_threshold = 2
health_check_path = "/"
health_check_matcher = "200"

# Listener Configuration
create_http_listener = true

# Access Logs (HIPAA compliance - enabled by default)
nlb_access_logs_enabled = true
nlb_connection_logs_enabled = true

################################################################################
# Domain Configuration
################################################################################
domain = "qa.10xr.co"
base_domain_name = "10xr.co"

# DNS Records for Route 53
app_dns_records = {
  "qa-hospice" = {
    name     = "hospice.qa"
    content  = ""  # Will be set by module to NLB DNS name
    type     = "CNAME"
    proxied  = false
    ttl      = 300
    comment  = "Hospice QA environment"
    tags     = ["qa", "hospice"]
  }
  "qa-homehealth" = {
    name     = "homehealth.qa"
    content  = ""  # Will be set by module to NLB DNS name
    type     = "CNAME"
    proxied  = false
    ttl      = 300
    comment  = "HomeHealth QA environment"
    tags     = ["qa", "homehealth"]
  }
}

################################################################################
# Tags
################################################################################
tags = {
  Environment = "qa"
  Project     = "10xR HealthCare"
  Platform    = "Application"
  Terraform   = "true"
  HIPAA       = "true"
}
