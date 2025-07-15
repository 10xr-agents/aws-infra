# environments/prod/terraform.tfvars

# AWS Region
region = "us-east-1"
environment = "prod"

# Cluster Configuration
cluster_name = "ten-xr-agents"

# VPC Configuration - Production subnets
vpc_cidr = "10.1.0.0/16"
azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]

private_subnets  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
public_subnets   = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
database_subnets = ["10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"]

documentdb_default_database = "ten_xr_agents_prod"

enable_nat_gateway     = true
single_nat_gateway     = true
one_nat_gateway_per_az = false
map_public_ip_on_launch = true

# ECS Configuration
enable_container_insights = true
enable_fargate           = true
enable_fargate_spot      = true

# SSL Configuration
ssl_policy          = "ELBSecurityPolicy-TLS-1-2-2017-01"

# ECS Services Configuration - Production settings
ecs_services = {
  "voice-agent": {
    "image": "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/voice-agent",
    "image_tag": "v1.0.0",
    "port": 9600,
    "cpu": 8192,      # Doubled for production
    "memory": 16384,  # Doubled for production
    "desired_count": 2, # Increased for production
    "environment": {
      "SERVICE_PORT": "9600"
    },
    "secrets": [],
    "capacity_provider_strategy": [
      {
        "capacity_provider": "FARGATE",
        "weight": 1,
        "base": 3  # Higher base for production
      },
      {
        "capacity_provider": "FARGATE_SPOT",
        "weight": 2,  # Reduced spot usage for production
        "base": 0
      }
    ],
    "container_health_check": {
      "command": "curl -f http://localhost:9600/health || exit 1",
      "interval": 30,
      "timeout": 20,
      "start_period": 120,  # Longer start period for production
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
    "auto_scaling_min_capacity": 3,  # Higher minimum for production
    "auto_scaling_max_capacity": 20, # Higher maximum for production
    "auto_scaling_cpu_target": 60,   # Lower target for production
    "auto_scaling_memory_target": 70,
    "enable_default_routing": false,
    "alb_host_headers": ["agents.10xr.co"],
    "enable_load_balancer": true,
    "enable_service_discovery": true,
    "deregistration_delay": 60,  # Longer delay for production
    "additional_task_policies": {
      "S3Access": "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    }
  },
  "livekit-proxy": {
    "image": "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/livekit-proxy-service",
    "image_tag": "1.0.0",
    "port": 9000,
    "cpu": 2048,      # Doubled for production
    "memory": 4096,   # Doubled for production
    "desired_count": 2, # Increased for production
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
      "start_period": 90,
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
    "auto_scaling_min_capacity": 2,
    "auto_scaling_max_capacity": 12,
    "auto_scaling_cpu_target": 60,
    "auto_scaling_memory_target": 70,
    "enable_default_routing": false,
    "alb_host_headers": ["proxy.10xr.co"],
    "enable_load_balancer": true,
    "enable_service_discovery": true,
    "deregistration_delay": 60
  },
  "agent-analytics": {
    "image": "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/agent-analytics-service",
    "image_tag": "latest",
    "port": 9800,
    "cpu": 2048,      # Doubled for production
    "memory": 4096,   # Doubled for production
    "desired_count": 2, # Increased for production
    "environment": {
      "LOG_LEVEL": "INFO",
      "SERVICE_PORT": "9800"
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
      "command": "curl -f http://localhost:9800/management/health || exit 1",
      "interval": 30,
      "timeout": 20,
      "start_period": 120,
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
    "auto_scaling_min_capacity": 2,
    "auto_scaling_max_capacity": 12,
    "auto_scaling_cpu_target": 60,
    "auto_scaling_memory_target": 70,
    "enable_default_routing": false,
    "alb_host_headers": ["analytics.10xr.co"],
    "enable_load_balancer": true,
    "enable_service_discovery": true,
    "deregistration_delay": 60
  },
  "ui-console": {
    "image": "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/ui-console",
    "image_tag": "prod-1.0.0",  # Production tag
    "port": 3000,
    "cpu": 1024,
    "memory": 2048,
    "desired_count": 2,  # Increased for production
    "environment": {
      "LOG_LEVEL": "INFO",
      "REACT_APP_API_URL": "https://services.10xr.co",
      "SERVICE_PORT": "3000"
    },
    "secrets": [],
    "capacity_provider_strategy": [
      {
        "capacity_provider": "FARGATE",
        "weight": 1,
        "base": 4  # Higher base for production
      }
    ],
    "container_health_check": {
      "command": "curl -f http://localhost:3000/api/management/health || exit 1",
      "interval": 30,
      "timeout": 20,
      "start_period": 90,
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
    "auto_scaling_min_capacity": 4,
    "auto_scaling_max_capacity": 12,
    "auto_scaling_cpu_target": 60,
    "auto_scaling_memory_target": 70,
    "enable_default_routing": true,
    "alb_host_headers": ["10xr.co", "ui.10xr.co"],
    "enable_load_balancer": true,
    "enable_service_discovery": true,
    "deregistration_delay": 60
  },
  "agentic-services": {
    "image": "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/agentic-framework-service",
    "image_tag": "latest",
    "port": 8080,
    "cpu": 2048,      # Doubled for production
    "memory": 4096,   # Doubled for production
    "desired_count": 2, # Increased for production
    "environment": {
      "LOG_LEVEL": "INFO",
      "SERVICE_PORT": "8080"
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
      "command": "curl -f http://localhost:8080/actuator/health || exit 1",
      "interval": 30,
      "timeout": 20,
      "start_period": 120,
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
    "auto_scaling_min_capacity": 2,
    "auto_scaling_max_capacity": 12,
    "auto_scaling_cpu_target": 60,
    "auto_scaling_memory_target": 70,
    "enable_default_routing": false,
    "alb_host_headers": ["api.10xr.co"],
    "enable_load_balancer": true,
    "enable_service_discovery": true,
    "deregistration_delay": 60,
    "efs_config": {
      "enabled": false,
      "mount_path": "/app/storage"
    }
  },
  "automation-service-mcp": {
    "image": "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/automation-service-mcp",
    "image_tag": "v1.0.0",
    "port": 8090,
    "cpu": 2048,      # Doubled for production
    "memory": 4096,   # Doubled for production
    "desired_count": 2, # Increased for production
    "environment": {
      "LOG_LEVEL": "INFO",
      "SERVICE_PORT": "8090"
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
      "command": "curl -f http://localhost:8090/health || exit 1",
      "interval": 30,
      "timeout": 20,
      "start_period": 120,
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
    "auto_scaling_min_capacity": 2,
    "auto_scaling_max_capacity": 10,
    "auto_scaling_cpu_target": 60,
    "auto_scaling_memory_target": 70,
    "enable_default_routing": false,
    "alb_host_headers": ["automation.10xr.co"],
    "enable_load_balancer": true,
    "enable_service_discovery": true,
    "deregistration_delay": 60
  }
}

# MongoDB Configuration - Production settings
mongodb_replica_count    = 5         # Increased for production
mongodb_instance_type    = "m5.xlarge"  # Larger instance for production

mongodb_version          = "8.0"
mongodb_admin_username   = "admin"
mongodb_default_database = "ten_xr_agents_prod"

# Storage Configuration - Production settings
mongodb_root_volume_size       = 50   # Increased for production
mongodb_data_volume_size       = 500  # Increased for production
mongodb_data_volume_type       = "gp3"
mongodb_data_volume_iops       = 6000  # Increased for production
mongodb_data_volume_throughput = 250   # Increased for production

# Security Configuration
mongodb_allow_ssh       = false  # Disabled for production
mongodb_ssh_cidr_blocks = []

# Monitoring and Logging
mongodb_enable_monitoring  = true
mongodb_log_retention_days = 30  # Longer retention for production

# DNS Configuration
mongodb_create_dns_records = true
mongodb_private_domain     = "mongodb.prod.10xr.local"

# Backup Configuration - Production settings
mongodb_backup_enabled        = true
mongodb_backup_schedule       = "cron(0 2 * * ? *)"  # Daily at 2 AM
mongodb_backup_retention_days = 30  # Longer retention for production

# Additional Features
mongodb_store_connection_string_in_ssm = true
mongodb_enable_encryption_at_rest      = true
mongodb_enable_audit_logging          = true

# Redis Configuration - Production settings
redis_node_type                    = "cache.r6g.large"  # Larger instance for production
redis_engine_version              = "7.0"
redis_num_cache_clusters          = 3  # Increased for production
redis_multi_az_enabled            = true
redis_automatic_failover_enabled  = true
redis_snapshot_retention_limit    = 30  # Longer retention for production
redis_snapshot_window             = "03:00-05:00"
redis_maintenance_window          = "sun:05:00-sun:07:00"
redis_auth_token_enabled          = true
redis_transit_encryption_enabled  = true
redis_at_rest_encryption_enabled  = true

redis_parameters = [
  {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  },
  {
    name  = "timeout"
    value = "300"
  },
  {
    name  = "tcp-keepalive"
    value = "300"
  }
]

redis_store_connection_details_in_ssm = true
redis_create_cloudwatch_log_group     = true
redis_cloudwatch_log_retention_days   = 30  # Longer retention for production

# NLB Configuration
create_nlb = true
nlb_internal = false
nlb_enable_deletion_protection = true  # Enabled for production
nlb_enable_cross_zone_load_balancing = true

# Target Group Configuration
create_http_target_group = true
http_port = 80
https_port = 443
target_type = "alb"
deregistration_delay = 300

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

# Access Logs - Enabled for production
nlb_access_logs_enabled = true
nlb_connection_logs_enabled = true

# Global Accelerator Configuration
create_global_accelerator = true
global_accelerator_enabled = true
global_accelerator_ip_address_type = "IPV4"
global_accelerator_flow_logs_enabled = true
global_accelerator_flow_logs_s3_prefix = "global-accelerator-flow-logs"
global_accelerator_client_affinity = "NONE"
global_accelerator_protocol = "TCP"
global_accelerator_health_check_grace_period = 30
global_accelerator_health_check_interval = 30
global_accelerator_health_check_path = "/health"
global_accelerator_health_check_port = 80
global_accelerator_health_check_protocol = "HTTP"
global_accelerator_threshold_count = 3
global_accelerator_traffic_dial_percentage = 100

# Cloudflare Configuration
cloudflare_api_token  = "jTm01UhNhNDE-Md4jrQwBS0w3vHsqVikxC9cop9r"
cloudflare_zone_id    = "3ae048b26df2c81c175c609f802feafb"
cloudflare_account_id = "929c1d893cb7bb8455e151ae08f3b538"
cloudflare_api_key    = "ef7027a662a457c814bfc30e81fcf49baa969"

# Domain Configuration
domain = "app.10xr.co"
base_domain_name = "10xr.co"
create_cloudflare_dns_records = true
dns_proxied = true  # Enabled for production (better security and performance)
manage_cloudflare_zone_settings = false  # Disable for now to avoid conflicts

# Production DNS records
app_dns_records = {
  "prod-main" = {
    name     = "prod"  # Root domain
    content  = "" # Will be set by module to Global Accelerator DNS name
    type     = "CNAME"
    proxied  = true
    ttl      = 300
    comment  = "Main production environment - routes to UI console"
    tags     = ["prod", "ui", "main"]
  },
  "prod-service" = {
    name     = "api.prod"
    content  = "" # Will be set by module to Global Accelerator DNS name
    type     = "CNAME"
    proxied  = true
    ttl      = 300
    comment  = "Production Service environment - routes to backend services"
    tags     = ["prod", "service", "api"]
  },
  "prod-proxy" = {
    name     = "proxy.prod"
    content  = "" # Will be set by module to Global Accelerator DNS name
    type     = "CNAME"
    proxied  = true
    ttl      = 300
    comment  = "Production LiveKit Proxy environment - routes to LiveKit proxy"
    tags     = ["prod", "livekit", "proxy"]
  },
  "prod-automation" = {
    name     = "automation.prod"
    content  = "" # Will be set by module to Global Accelerator DNS name
    type     = "CNAME"
    proxied  = true
    ttl      = 300
    comment  = "Production Automation Service environment - routes to automation MCP service"
    tags     = ["prod", "automation", "mcp"]
  }
}

# Zone Settings - Enabled for production
cloudflare_ssl_mode = "strict"  # Strict SSL for production
cloudflare_always_use_https = "on"  # Always HTTPS for production
cloudflare_min_tls_version = "1.2"
cloudflare_security_level = "high"  # Higher security for production

################################################################################
# TFE Configuration - UPDATE THESE WITH YOUR ACTUAL VALUES
################################################################################

# TFE Configuration (replace with your actual values)
tfe_organization_name = "10xr"

documentdb_github_repo = "10xr-agents/ten_xr_storage_infra"

# DocumentDB Configuration
documentdb_workspace_auto_apply = true
documentdb_instance_count = 3
documentdb_instance_class = "db.r6g.large"

# Tags
tags = {
  Environment = "prod"
  Project     = "10xR Agents"
  Platform    = "Application"
  Terraform   = "true"
}