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

# SSL Configuration (add your certificate ARN here if you have one)
ssl_policy          = "ELBSecurityPolicy-TLS-1-2-2017-01"

# ECS Services Configuration (keeping your existing services + new automation-service-mcp)
ecs_services = {
  "voice-agent": {
    "image": "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/voice-agent",
    "image_tag": "v1.0.0",
    "port": 9600,
    "cpu": 4096,
    "memory": 8192,
    "desired_count": 2,
    "environment": {
      "SERVICE_PORT": "9600"
    },
    "secrets": [],
    "capacity_provider_strategy": [
      {
        "capacity_provider": "FARGATE",
        "weight": 1,
        "base": 1
      },
      {
        "capacity_provider": "FARGATE_SPOT",
        "weight": 3,
        "base": 0
      }
    ],
    "container_health_check": {
      "command": "curl -f http://localhost:9600/ || exit 1",
      "interval": 30,
      "timeout": 20,
      "start_period": 90,
      "retries": 3
    },
    "health_check": {
      "path": "/",
      "interval": 30,
      "timeout": 20,
      "healthy_threshold": 2,
      "unhealthy_threshold": 3,
      "matcher": "200"
    },
    "enable_auto_scaling": true,
    "auto_scaling_min_capacity": 1,
    "auto_scaling_max_capacity": 10,
    "auto_scaling_cpu_target": 40,
    "auto_scaling_memory_target": 40,
    "enable_default_routing": false,
    "alb_host_headers": ["agents.qa.10xr.co"],
#    "alb_path_patterns": ["/agents/*"],
    "enable_load_balancer": true,
    "enable_service_discovery": true,
    "deregistration_delay": 30,
    "additional_task_policies": {
      "S3Access": "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    }
  },
  "livekit-proxy": {
    "image": "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/livekit-proxy-service",
    "image_tag": "1.0.0",
    "port": 9000,
    "cpu": 1024,
    "memory": 2048,
    "desired_count": 2,
    "environment": {
      "SERVICE_PORT": "9000"
    },
    "secrets": [],
    "capacity_provider_strategy": [
      {
        "capacity_provider": "FARGATE",
        "weight": 1,
        "base": 2
      },
      {
        "capacity_provider": "FARGATE_SPOT",
        "weight": 1,
        "base": 0
      }
    ],
    "container_health_check": {
      "command": "curl -f http://localhost:9000/api/v1/management/health || exit 1",
      "interval": 30,
      "timeout": 20,
      "start_period": 60,
      "retries": 3
    },
    "health_check": {
      "path": "/api/v1/management/health",
      "interval": 30,
      "timeout": 20,
      "healthy_threshold": 2,
      "unhealthy_threshold": 3,
      "matcher": "200"
    },
    "enable_auto_scaling": true,
    "auto_scaling_min_capacity": 1,
    "auto_scaling_max_capacity": 8,
    "auto_scaling_cpu_target": 70,
    "auto_scaling_memory_target": 80,
    "enable_default_routing": false,
#    "alb_path_patterns": ["/livekit/*"],
    "alb_host_headers": ["proxy.qa.10xr.co"],
    "enable_load_balancer": true,
    "enable_service_discovery": true,
    "deregistration_delay": 30
  },
  "agent-analytics": {
    "image": "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/agent-analytics-service",
    "image_tag": "latest",
    "port": 9800,
    "cpu": 2048,
    "memory": 4096,
    "desired_count": 2,
    "environment": {
      "LOG_LEVEL": "INFO",
      "SERVICE_PORT": "9800"
    },
    "secrets": [],
    "capacity_provider_strategy": [
      {
        "capacity_provider": "FARGATE",
        "weight": 1,
        "base": 1
      },
      {
        "capacity_provider": "FARGATE_SPOT",
        "weight": 2,
        "base": 0
      }
    ],
    "container_health_check": {
      "command": "curl -f http://localhost:9800/management/health || exit 1",
      "interval": 30,
      "timeout": 20,
      "start_period": 90,
      "retries": 3
    },
    "health_check": {
      "path": "/management/health",
      "interval": 30,
      "timeout": 20,
      "healthy_threshold": 2,
      "unhealthy_threshold": 3,
      "matcher": "200"
    },
    "enable_auto_scaling": true,
    "auto_scaling_min_capacity": 1,
    "auto_scaling_max_capacity": 8,
    "auto_scaling_cpu_target": 70,
    "auto_scaling_memory_target": 80,
    "enable_default_routing": false,
    "alb_host_headers": ["analytics.qa.10xr.co"],
#    "alb_path_patterns": ["/analytics/*"],
    "enable_load_balancer": true,
    "enable_service_discovery": true,
    "deregistration_delay": 30
  },
  "ui-console": {
    "image": "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/ui-console",
    "image_tag": "qa-0.1.0",
    "port": 3000,
    "cpu": 512,
    "memory": 1024,
    "desired_count": 2,
    "environment": {
      "LOG_LEVEL": "INFO",
      "REACT_APP_API_URL": "https://services.qa.10xr.co",
      "SERVICE_PORT": "3000"
    },
    "secrets": [],
    "capacity_provider_strategy": [
      {
        "capacity_provider": "FARGATE",
        "weight": 1,
        "base": 2
      }
    ],
    "container_health_check": {
      "command": "curl -f http://localhost:3000/api/management/health || exit 1",
      "interval": 30,
      "timeout": 20,
      "start_period": 60,
      "retries": 3
    },
    "health_check": {
      "path": "/api/server/health",
      "interval": 30,
      "timeout": 20,
      "healthy_threshold": 2,
      "unhealthy_threshold": 3,
      "matcher": "200"
    },
    "enable_auto_scaling": true,
    "auto_scaling_min_capacity": 2,
    "auto_scaling_max_capacity": 6,
    "auto_scaling_cpu_target": 70,
    "auto_scaling_memory_target": 80,
    "enable_default_routing": true,
    "alb_host_headers": ["qa.10xr.co", "ui.qa.10xr.co"],
#    "alb_path_patterns": ["/ui/*", "/"],
    "enable_load_balancer": true,
    "enable_service_discovery": true,
    "deregistration_delay": 30
  },
  "agentic-services": {
    "image": "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/agentic-framework-service",
    "image_tag": "latest",
    "port": 8080,
    "cpu": 1024,
    "memory": 2048,
    "desired_count": 2,
    "environment": {
      "LOG_LEVEL": "INFO",
      "SERVICE_PORT": "8080"
    },
    "secrets": [],
    "capacity_provider_strategy": [
      {
        "capacity_provider": "FARGATE",
        "weight": 1,
        "base": 1
      },
      {
        "capacity_provider": "FARGATE_SPOT",
        "weight": 2,
        "base": 0
      }
    ],
    "container_health_check": {
      "command": "curl -f http://localhost:8080/actuator/health || exit 1",
      "interval": 30,
      "timeout": 20,
      "start_period": 90,
      "retries": 3
    },
    "health_check": {
      "path": "/actuator/health",
      "interval": 30,
      "timeout": 20,
      "healthy_threshold": 2,
      "unhealthy_threshold": 3,
      "matcher": "200"
    },
    "enable_auto_scaling": true,
    "auto_scaling_min_capacity": 1,
    "auto_scaling_max_capacity": 8,
    "auto_scaling_cpu_target": 70,
    "auto_scaling_memory_target": 80,
    "enable_default_routing": false,
    "alb_host_headers": ["api.qa.10xr.co"],
#    "alb_path_patterns": ["/services/*"],
    "enable_load_balancer": true,
    "enable_service_discovery": true,
    "deregistration_delay": 30,
    "efs_config": {
      "enabled": false,
      "mount_path": "/app/storage"
    }
  },
  "automation-service-mcp": {
    "image": "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/automation-service-mcp",
    "image_tag": "v1.0.0",
    "port": 8090,
    "cpu": 1024,
    "memory": 2048,
    "desired_count": 2,
    "environment": {
      "LOG_LEVEL": "INFO",
      "SERVICE_PORT": "8090"
    },
    "secrets": [],
    "capacity_provider_strategy": [
      {
        "capacity_provider": "FARGATE",
        "weight": 1,
        "base": 1
      },
      {
        "capacity_provider": "FARGATE_SPOT",
        "weight": 2,
        "base": 0
      }
    ],
    "container_health_check": {
      "command": "curl -f http://localhost:8090/health || exit 1",
      "interval": 30,
      "timeout": 20,
      "start_period": 90,
      "retries": 3
    },
    "health_check": {
      "path": "/health",
      "interval": 30,
      "timeout": 20,
      "healthy_threshold": 2,
      "unhealthy_threshold": 3,
      "matcher": "200"
    },
    "enable_auto_scaling": true,
    "auto_scaling_min_capacity": 1,
    "auto_scaling_max_capacity": 8,
    "auto_scaling_cpu_target": 70,
    "auto_scaling_memory_target": 80,
    "enable_default_routing": false,
    "alb_host_headers": ["automation.qa.10xr.co"],
    "enable_load_balancer": true,
    "enable_service_discovery": true,
    "deregistration_delay": 30
  }
}

# NLB Configuration
create_nlb = true
nlb_internal = false
nlb_enable_deletion_protection = false
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

# Access Logs (optional - set to true if you want to enable)
nlb_access_logs_enabled = true
nlb_connection_logs_enabled = true

# Domain Configuration
domain = "qa.10xr.co"
base_domain_name = "10xr.co"

# Update app_dns_records to not be proxied
app_dns_records = {
  "qa-main" = {
    name     = "hospice.qa"
    content  = "" # Will be set by module to Global Accelerator DNS name
    type     = "CNAME"
    proxied  = false  # Changed from true to false
    ttl      = 300
    comment  = "Hospice QA environment"
    tags     = ["qa", "hospice"]
  },
  "qa-service" = {
    name     = "homehealth.qa"
    content  = "" # Will be set by module to Global Accelerator DNS name
    type     = "CNAME"
    proxied  = false  # Changed from true to false
    ttl      = 300
    comment  = "HomeHealth QA environment"
    tags     = ["qa", "homehealth"]
  }
}

# Tags
tags = {
  Environment = "qa"
  Project     = "10xR HealthCare"
  Platform    = "Application"
  Terraform   = "true"
}