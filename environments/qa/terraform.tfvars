# environments/qa/terraform.tfvars

# AWS Region
region = "us-east-1"
environment = "qa"

# Cluster Configuration
cluster_name = "ten-xr-agents"

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
acm_certificate_arn = ""  # Add your ACM certificate ARN here for HTTPS
ssl_policy          = "ELBSecurityPolicy-TLS-1-2-2017-01"

# ECS Services Configuration (keeping your existing services)
ecs_services = {
  "voice-agent": {
    "image": "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/voice-agent",
    "image_tag": "v1.0.0",
    "port": 9600,
    "cpu": 4096,
    "memory": 8192,
    "desired_count": 2,
    "environment": {
      "MONGODB_URI": "mongodb+srv://doadmin:by6n2k14L8g53dt7@db-mongodb-nyc3-70786-efaf17f9.mongo.ondigitalocean.com/ten_xr_temp_agents_local?tls=true&authSource=admin&replicaSet=db-mongodb-nyc3-70786",
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
      "command": "curl -f http://localhost:9600/health || exit 1",
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
    "auto_scaling_max_capacity": 10,
    "auto_scaling_cpu_target": 40,
    "auto_scaling_memory_target": 50,
    "enable_default_routing": false,
    "alb_path_patterns": ["/agents/*"],
    "enable_load_balancer": true,
    "enable_service_discovery": true,
    "deregistration_delay": 30,
    "additional_task_policies": {
      "S3Access": "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    }
  },
  "livekit-proxy": {
    "image": "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/livekit-proxy-service",
    "image_tag": "0.1.0",
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
    "alb_path_patterns": ["/livekit/*"],
    "alb_host_headers": ["proxy.qa.10xr.co"],
    "enable_load_balancer": true,
    "enable_service_discovery": true,
    "deregistration_delay": 30
  },
  "agent-analytics": {
    "image": "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/agent-analytics-service",
    "image_tag": "latest",
    "port": 9800,
    "cpu": 1024,
    "memory": 2048,
    "desired_count": 2,
    "environment": {
      "LOG_LEVEL": "INFO",
      "MONGODB_URI": "mongodb+srv://doadmin:by6n2k14L8g53dt7@db-mongodb-nyc3-70786-efaf17f9.mongo.ondigitalocean.com/ten_xr_temp_agents_local?tls=true&authSource=admin&replicaSet=db-mongodb-nyc3-70786",
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
    "alb_path_patterns": ["/analytics/*"],
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
      "path": "/api/management/health",
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
    "alb_host_headers": ["qa.10xr.co"],
    "alb_path_patterns": ["/ui/*", "/"],
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
      "MONGODB_URI": "mongodb+srv://doadmin:by6n2k14L8g53dt7@db-mongodb-nyc3-70786-efaf17f9.mongo.ondigitalocean.com/ten_xr_temp_agents_local?tls=true&authSource=admin&replicaSet=db-mongodb-nyc3-70786",
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
    "alb_path_patterns": ["/services/*"],
    "enable_load_balancer": true,
    "enable_service_discovery": true,
    "deregistration_delay": 30,
    "efs_config": {
      "enabled": false,
      "mount_path": "/app/storage"
    }
  }
}

# MongoDB Configuration
mongodb_replica_count    = 3
mongodb_instance_type    = "t3.large"

mongodb_version          = "7.0"
mongodb_admin_username   = "admin"
mongodb_admin_password   = "TenXR-MongoDB-QA-2024!"  # Please change this to a secure password
mongodb_keyfile_content  = ""  # Generate a secure keyfile content for replica set authentication

mongodb_default_database = "ten_xr_agents_qa"

# Storage Configuration
mongodb_root_volume_size       = 30
mongodb_data_volume_size       = 200
mongodb_data_volume_type       = "gp3"
mongodb_data_volume_iops       = 3000
mongodb_data_volume_throughput = 125

# Security Configuration
mongodb_allow_ssh       = true
mongodb_ssh_cidr_blocks = ["10.0.0.0/16"]  # Allow SSH from within VPC

# Monitoring and Logging
mongodb_enable_monitoring  = true
mongodb_log_retention_days = 7

# DNS Configuration
mongodb_create_dns_records = true
mongodb_private_domain     = "mongodb.qa.10xr.local"

# Backup Configuration
mongodb_backup_enabled        = true
mongodb_backup_schedule       = "cron(0 2 * * ? *)"  # Daily at 2 AM
mongodb_backup_retention_days = 7

# Additional Features
mongodb_store_connection_string_in_ssm = true
mongodb_enable_encryption_at_rest      = true
mongodb_enable_audit_logging          = true

# Redis Configuration
redis_node_type                    = "cache.t3.micro"
redis_engine_version              = "7.0"
redis_num_cache_clusters          = 2
redis_multi_az_enabled            = true
redis_automatic_failover_enabled  = true
redis_snapshot_retention_limit    = 7
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
redis_cloudwatch_log_retention_days   = 7

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
domain_name = "10xr.co"
create_cloudflare_dns_records = true
dns_proxied = true  # Enable Cloudflare proxy for CDN and protection
dns_ttl = 300

# Custom DNS Records for specific subdomain routing
app_dns_records = {
  "qa-main" = {
    name     = "qa"
    content  = "" # Will be set by module to Global Accelerator DNS name
    type     = "CNAME"
    proxied  = true
    ttl      = 300
    comment  = "Main QA environment - routes to UI console"
    tags     = ["qa", "ui", "main"]
  },
  "qa-service" = {
    name     = "api.qa"
    content  = "" # Will be set by module to Global Accelerator DNS name
    type     = "CNAME"
    proxied  = true
    ttl      = 300
    comment  = "QA Service environment - routes to backend services"
    tags     = ["qa", "service", "api"]
  },
  "qa-livekit" = {
    name     = "proxy.qa"
    content  = "" # Will be set by module to Global Accelerator DNS name
    type     = "CNAME"
    proxied  = true
    ttl      = 300
    comment  = "QA LiveKit environment - routes to LiveKit proxy"
    tags     = ["qa", "livekit", "proxy"]
  }
}

# Zone Settings (optional)
manage_cloudflare_zone_settings = false
cloudflare_ssl_mode = "flexible"
cloudflare_always_use_https = "off"
cloudflare_min_tls_version = "1.2"
cloudflare_security_level = "medium"

# Tags
tags = {
  Environment = "qa"
  Project     = "10xR Agents"
  Platform    = "Application"
  Terraform   = "true"
}