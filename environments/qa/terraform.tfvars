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

################################################################################
# GPU ECS Services Configuration - Updated for P4 A100 instances
################################################################################

gpu_ecs_services = {
  "indic-tts" = {
    image         = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/tts-streaming-service:main-21a86ac"
    image_tag     = "latest"
    port          = 8000
    cpu           = 32768  # 32 vCPUs (increased for p4d.24xlarge - can use up to 96)
    memory        = 131072 # 128 GB RAM (conservative allocation from 1152 GB available)
    gpu_count     = 2      # 2 GPUs per task (from 8 available A100s)
    desired_count = 1      # Start with 1 for testing

    # Environment variables for Indic TTS - Updated for P4 A100 performance
    environment = {
      ENVIRONMENT     = "qa"
      DEVICE         = "cuda"
      ULTRA_FAST_MODE = "true"
      
      # Performance settings optimized for P4 A100 GPUs
      TARGET_FIRST_CHUNK_MS     = "15"   # Faster with A100s
      MODEL_POOL_SIZE           = "8"    # Increased for multiple GPUs
      MAX_CONCURRENT_REQUESTS   = "500"  # Higher capacity with P4
      WARMUP_ON_STARTUP        = "true"
      
      # Redis configuration (Redis connection details will be merged in main.tf)
      ENABLE_REDIS    = "true"
      
      # Caching - optimized for P4 memory capacity
      ENABLE_AUDIO_CACHING  = "true"
      ENABLE_VOICE_CACHING  = "true"
      ENABLE_MODEL_CACHING  = "true"
      CACHE_COMPRESSION     = "true"
      
      # Model configuration
      MODEL_NAME        = "ai4bharat/indic-parler-tts"
      AUDIO_SAMPLE_RATE = "24000"
      MAX_TEXT_LENGTH   = "4000"  # Increased for P4 capacity
      
      # Logging and monitoring
      LOG_LEVEL                  = "INFO"
      ENABLE_PERFORMANCE_LOGGING = "true"
      ENABLE_REQUEST_LOGGING     = "true"
      ENABLE_METRICS            = "true"
      
      # API configuration
      HOST = "0.0.0.0"
      PORT = "8000"
      
      # Production settings for QA
      ENABLE_TEST_INTERFACE = "true"
      ENABLE_OPENAPI_DOCS   = "true"
      
      # CORS settings
      ALLOWED_ORIGINS = "[\"https://qa.10xr.co\", \"https://api.qa.10xr.co\", \"https://tts.qa.10xr.co\"]"
      
      # Performance optimizations for A100 GPUs
      TORCH_COMPILE_MODE     = "max-autotune"  # More aggressive optimization for A100
      TORCH_COMPILE_DYNAMIC  = "false"
      CUDA_LAUNCH_BLOCKING   = "0"
      PYTORCH_CUDA_ALLOC_CONF = "expandable_segments:True,max_split_size_mb:512"
      
      # Multi-GPU configuration
      CUDA_VISIBLE_DEVICES   = "0,1"  # Use first 2 GPUs
      NCCL_DEBUG            = "INFO"
      
      # Batch processing - optimized for multiple A100s
      ENABLE_BATCH_PROCESSING = "true"
      MAX_BATCH_SIZE         = "16"  # Increased for A100 capacity
      BATCH_TIMEOUT_MS       = "30"  # Faster with A100s
      
      # Quality settings
      DEFAULT_QUALITY     = "high"
      ENABLE_VOICE_CLONING = "true"
      
      # API features
      ENABLE_WEBSOCKET_STREAMING = "true"
      ENABLE_SERVER_SENT_EVENTS  = "true"
      
      # Monitoring
      PROMETHEUS_METRICS_PORT = "9090"
      
      # Rate limiting - increased for P4 capacity
      RATE_LIMIT_REQUESTS_PER_MINUTE = "600"
      
      # Memory management for large instance
      MAX_MEMORY_USAGE_PCT = "80"
      GARBAGE_COLLECTION_THRESHOLD = "0.8"
    }

    # Secrets (Redis password will be added in main.tf)
    secrets = []

    # Health check configuration
    health_check = {
      path                = "/health/liveness"
      interval            = 30
      timeout             = 10
      healthy_threshold   = 2
      unhealthy_threshold = 3
      matcher             = "200"
    }

    # Container health check with longer startup time for P4 multi-GPU model loading
    container_health_check = {
      command      = "curl -f http://localhost:8000/health/liveness || exit 1"
      interval     = 30
      timeout      = 10
      retries      = 3
      start_period = 240  # 4 minutes for P4 multi-GPU model loading
    }

    # Load balancer integration
    enable_load_balancer = true
    deregistration_delay = 60

    # Docker configuration for P4 GPU workload
    docker_labels = {
      service_type = "indic-tts"
      gpu_enabled  = "true"
      gpu_type     = "a100"
      gpu_count    = "2"
      instance_type = "p4d"
      model_type   = "parler-tts"
    }

    # System limits for P4 GPU workload - optimized for high-memory instance
    ulimits = [
      {
        name       = "memlock"
        soft_limit = -1
        hard_limit = -1
      },
      {
        name       = "nofile"
        soft_limit = 1048576  # Increased for P4
        hard_limit = 1048576
      },
      {
        name       = "nproc"
        soft_limit = 65536
        hard_limit = 65536
      }
    ]
  }
}

################################################################################
# GPU Infrastructure Configuration - Updated for P4 instances
################################################################################

# GPU Instance Configuration - UPDATED: Use P4 instance types
gpu_instance_type    = "p4d.24xlarge"  # 96 vCPUs, 1152 GB RAM, 8 A100 GPUs
gpu_instance_types   = ["p4d.24xlarge", "p4de.24xlarge"]  # Both P4 variants for better availability
gpu_min_size         = 0
gpu_max_size         = 2  # Keep conservative for cost control
gpu_desired_capacity = 1

# Cost optimization with mixed instances
gpu_on_demand_base       = 1
gpu_on_demand_percentage = 50  # 50% spot for better availability

# Storage - increased for P4 instances and model storage
gpu_root_volume_size = 500  # Increased for larger P4 instances and model storage

################################################################################
# Redis Configuration
################################################################################
redis_node_type                    = "cache.m5.4xlarge"
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
domain = "qa.10xr.co"
base_domain_name = "10xr.co"
create_cloudflare_dns_records = true
# Change these settings for HTTP access
dns_proxied = false  # Disable proxying to allow direct HTTP access
manage_cloudflare_zone_settings = false  # Don't manage zone settings for now

# Update app_dns_records to not be proxied
app_dns_records = {
  "qa-main" = {
    name     = "qa"
    content  = "" # Will be set by module to Global Accelerator DNS name
    type     = "CNAME"
    proxied  = false  # Changed from true to false
    ttl      = 300
    comment  = "Main QA environment - routes to UI console"
    tags     = ["qa", "ui", "main"]
  },
  "qa-service" = {
    name     = "api.qa"
    content  = "" # Will be set by module to Global Accelerator DNS name
    type     = "CNAME"
    proxied  = false  # Changed from true to false
    ttl      = 300
    comment  = "QA Service environment - routes to backend services"
    tags     = ["qa", "service", "api"]
  },
  "qa-proxy" = {
    name     = "proxy.qa"
    content  = "" # Will be set by module to Global Accelerator DNS name
    type     = "CNAME"
    proxied  = false  # Changed from true to false
    ttl      = 300
    comment  = "QA LiveKit Proxy environment - routes to LiveKit proxy"
    tags     = ["qa", "livekit", "proxy"]
  },
  "qa-automation" = {
    name     = "automation.qa"
    content  = "" # Will be set by module to Global Accelerator DNS name
    type     = "CNAME"
    proxied  = false
    ttl      = 300
    comment  = "QA Automation Service environment - routes to automation MCP service"
    tags     = ["qa", "automation", "mcp"]
  },
  "qa-tts" = {
    name     = "tts.qa"
    content  = ""
    type     = "CNAME"
    proxied  = false
    ttl      = 300
    comment  = "QA Indic TTS Service - Ultra-fast P4 A100 GPU-powered text-to-speech"
    tags     = ["qa", "tts", "indic", "gpu", "p4", "a100"]
  }
}

# Zone Settings (optional)
cloudflare_ssl_mode = "flexible"
cloudflare_always_use_https = "off"
cloudflare_min_tls_version = "1.2"
cloudflare_security_level = "medium"

# TTS-specific configuration
indic_tts_enable_alb = true

# Tags
tags = {
  Environment = "qa"
  Project     = "10xR Agents"
  Platform    = "Application"
  Terraform   = "true"
}