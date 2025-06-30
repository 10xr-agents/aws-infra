# environments/qa/terraform.tfvars

# AWS Region
region = "us-east-1"
environment = "qa"

# Cluster Configuration
cluster_name = "ten-xr-livekit"

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

# ALB Configuration
alb_enable_deletion_protection = false
alb_enable_http2              = true
alb_idle_timeout              = 60

# Storage Configuration
efs_performance_mode       = "generalPurpose"
efs_throughput_mode        = "bursting"
create_recordings_bucket   = true
recordings_expiration_days = 30

# Voice Agent Configuration
voice_agent_ecr_repository_url = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/voice-agent"
voice_agent_image_tag          = "v1.0.0"
voice_agent_port               = 9600
voice_agent_cpu                = 2048
voice_agent_memory             = 4096
voice_agent_desired_count      = 2

voice_agent_log_level               = "DEBUG"
voice_agent_agent_collection_name   = "agent-context-data"
voice_agent_frames_collection_name  = "voice-ai-frames"
voice_agent_database_name          = "converse-server-qa"

voice_agent_mongodb_uri = "mongodb+srv://doadmin:by6n2k14L8g53dt7@db-mongodb-nyc3-70786-efaf17f9.mongo.ondigitalocean.com/ten_xr_temp_agents_local?tls=true&authSource=admin&replicaSet=db-mongodb-nyc3-70786"

voice_agent_livekit_service    = "livekit-server"
voice_agent_livekit_api_key    = "APIoiCmJzAYqd5v"
voice_agent_livekit_api_secret = "upXGZbqbwpeftLexnICK401jqQFfvrl1o42N84lsSWcC"

# Voice Agent Secrets Configuration (use these ARNs for production deployment)
# voice_agent_anthropic_api_key_secret_arn    = "arn:aws:secretsmanager:us-east-1:123456789012:secret:voice-agent/anthropic-api-key-AbCdEf"
# voice_agent_deepgram_api_key_secret_arn     = "arn:aws:secretsmanager:us-east-1:123456789012:secret:voice-agent/deepgram-api-key-GhIjKl"
# voice_agent_cartesia_api_key_secret_arn     = "arn:aws:secretsmanager:us-east-1:123456789012:secret:voice-agent/cartesia-api-key-MnOpQr"
# voice_agent_livekit_api_key_secret_arn      = "arn:aws:secretsmanager:us-east-1:123456789012:secret:voice-agent/livekit-api-key-StUvWx"
# voice_agent_livekit_api_secret_secret_arn   = "arn:aws:secretsmanager:us-east-1:123456789012:secret:voice-agent/livekit-api-secret-YzAbCd"

# Voice Agent Additional Environment Variables (if needed)
voice_agent_additional_environment_variables = {
  # Add any additional environment variables specific to your deployment
}

# Voice Agent Health Check Configuration
voice_agent_enable_health_check    = true
voice_agent_health_check_command   = "curl -f http://localhost:9600/health || exit 1"
voice_agent_health_check_path      = "/health"
voice_agent_health_check_interval  = 30
voice_agent_health_check_timeout   = 20
voice_agent_health_check_start_period = 90

# Voice Agent Auto Scaling Configuration
voice_agent_enable_auto_scaling = true
voice_agent_min_capacity        = 1
voice_agent_max_capacity        = 10
voice_agent_cpu_target          = 70
voice_agent_memory_target       = 80

# Voice Agent Service Discovery
voice_agent_enable_service_discovery = true

# Voice Agent EFS Storage (enable if your voice agent needs persistent storage)
voice_agent_enable_efs     = false
voice_agent_efs_mount_path = "/app/storage"

# LiveKit Proxy Configuration
livekit_proxy_ecr_repository_url = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/livekit-proxy-service"
livekit_proxy_image_tag          = "0.1.0"
livekit_proxy_port               = 8080
livekit_proxy_cpu                = 1024
livekit_proxy_memory             = 2048
livekit_proxy_desired_count      = 2

livekit_proxy_log_level = "INFO"

livekit_proxy_livekit_service    = "livekit-server"
livekit_proxy_livekit_api_key    = "APIoiCmJzAYqd5v"
livekit_proxy_livekit_api_secret = "upXGZbqbwpeftLexnICK401jqQFfvrl1o42N84lsSWcC"

# LiveKit Proxy Secrets Configuration (use these ARNs for production deployment)
# livekit_proxy_livekit_api_key_secret_arn      = "arn:aws:secretsmanager:us-east-1:123456789012:secret:livekit-proxy/livekit-api-key-StUvWx"
# livekit_proxy_livekit_api_secret_secret_arn   = "arn:aws:secretsmanager:us-east-1:123456789012:secret:livekit-proxy/livekit-api-secret-YzAbCd"

# LiveKit Proxy Additional Environment Variables (if needed)
livekit_proxy_additional_environment_variables = {
  # Add any additional environment variables specific to your deployment
}

# LiveKit Proxy Health Check Configuration
livekit_proxy_enable_health_check    = true
livekit_proxy_health_check_command   = "curl -f http://localhost:8080/health || exit 1"
livekit_proxy_health_check_path      = "/health"
livekit_proxy_health_check_interval  = 30
livekit_proxy_health_check_timeout   = 20
livekit_proxy_health_check_start_period = 90

# LiveKit Proxy Auto Scaling Configuration
livekit_proxy_enable_auto_scaling = true
livekit_proxy_min_capacity        = 1
livekit_proxy_max_capacity        = 10
livekit_proxy_cpu_target          = 70
livekit_proxy_memory_target       = 80

# LiveKit Proxy Service Discovery
livekit_proxy_enable_service_discovery = true

# LiveKit Proxy EFS Storage (enable if your proxy needs persistent storage)
livekit_proxy_enable_efs     = false
livekit_proxy_efs_mount_path = "/app/storage"

# Agent Analytics Service Configuration
agent_analytics_ecr_repository_url = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/agent-analytics-service"
agent_analytics_image_tag          = "latest"
agent_analytics_port               = 3000
agent_analytics_cpu                = 1024
agent_analytics_memory             = 2048
agent_analytics_desired_count      = 2

agent_analytics_log_level = "INFO"

# Use the same MongoDB URI as voice agent or configure separately
agent_analytics_mongodb_uri = "mongodb+srv://doadmin:by6n2k14L8g53dt7@db-mongodb-nyc3-70786-efaf17f9.mongo.ondigitalocean.com/ten_xr_temp_agents_local?tls=true&authSource=admin&replicaSet=db-mongodb-nyc3-70786"

# Agent Analytics Additional Environment Variables (if needed)
agent_analytics_additional_environment_variables = {
  # Add any additional environment variables specific to your deployment
}

# Agent Analytics Health Check Configuration
agent_analytics_enable_health_check    = true
agent_analytics_health_check_command   = "curl -f http://localhost:3000/health || exit 1"
agent_analytics_health_check_path      = "/health"
agent_analytics_health_check_interval  = 30
agent_analytics_health_check_timeout   = 20
agent_analytics_health_check_start_period = 90

# Agent Analytics Auto Scaling Configuration
agent_analytics_enable_auto_scaling = true
agent_analytics_min_capacity        = 1
agent_analytics_max_capacity        = 10
agent_analytics_cpu_target          = 70
agent_analytics_memory_target       = 80

# Agent Analytics Service Discovery
agent_analytics_enable_service_discovery = true

# Agent Analytics EFS Storage (enable if your service needs persistent storage)
agent_analytics_enable_efs     = false
agent_analytics_efs_mount_path = "/app/storage"

# UI Console Service Configuration
ui_console_ecr_repository_url = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/ui-console"
ui_console_image_tag          = "latest"
ui_console_port               = 80
ui_console_cpu                = 512
ui_console_memory             = 1024
ui_console_desired_count      = 2

ui_console_log_level = "INFO"

# UI Console Additional Environment Variables (if needed)
ui_console_additional_environment_variables = {
  # Add any additional environment variables specific to your deployment
  # REACT_APP_API_URL = "http://your-api-url"
}

# UI Console Health Check Configuration
ui_console_enable_health_check    = true
ui_console_health_check_command   = "curl -f http://localhost:80/ || exit 1"
ui_console_health_check_path      = "/"
ui_console_health_check_interval  = 30
ui_console_health_check_timeout   = 20
ui_console_health_check_start_period = 60

# UI Console Auto Scaling Configuration
ui_console_enable_auto_scaling = true
ui_console_min_capacity        = 1
ui_console_max_capacity        = 10
ui_console_cpu_target          = 70
ui_console_memory_target       = 80

# UI Console Service Discovery
ui_console_enable_service_discovery = true

# UI Console EFS Storage (typically not needed for UI applications)
ui_console_enable_efs     = false
ui_console_efs_mount_path = "/app/storage"

# Agentic Framework Service Configuration
agentic_framework_ecr_repository_url = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/agentic-framework-service"
agentic_framework_image_tag          = "latest"
agentic_framework_port               = 8000
agentic_framework_cpu                = 1024
agentic_framework_memory             = 2048
agentic_framework_desired_count      = 2

agentic_framework_log_level = "INFO"

# Use the same MongoDB URI as voice agent or configure separately
agentic_framework_mongodb_uri = "mongodb+srv://doadmin:by6n2k14L8g53dt7@db-mongodb-nyc3-70786-efaf17f9.mongo.ondigitalocean.com/ten_xr_temp_agents_local?tls=true&authSource=admin&replicaSet=db-mongodb-nyc3-70786"

# Agentic Framework Additional Environment Variables (if needed)
agentic_framework_additional_environment_variables = {
  # Add any additional environment variables specific to your deployment
}

# Agentic Framework Health Check Configuration
agentic_framework_enable_health_check    = true
agentic_framework_health_check_command   = "curl -f http://localhost:8000/health || exit 1"
agentic_framework_health_check_path      = "/health"
agentic_framework_health_check_interval  = 30
agentic_framework_health_check_timeout   = 20
agentic_framework_health_check_start_period = 90

# Agentic Framework Auto Scaling Configuration
agentic_framework_enable_auto_scaling = true
agentic_framework_min_capacity        = 1
agentic_framework_max_capacity        = 10
agentic_framework_cpu_target          = 70
agentic_framework_memory_target       = 80

# Agentic Framework Service Discovery
agentic_framework_enable_service_discovery = true

# Agentic Framework EFS Storage (enable if your service needs persistent storage)
agentic_framework_enable_efs     = false
agentic_framework_efs_mount_path = "/app/storage"

# MongoDB Configuration
mongodb_replica_count    = 3
mongodb_instance_type    = "t3.large"
mongodb_key_name         = "ten-xr-qa-keypair"  # Replace with your actual key pair name

mongodb_version          = "7.0"
mongodb_admin_username   = "admin"
mongodb_admin_password   = "TenXR-MongoDB-QA-2024!"  # Please change this to a secure password
mongodb_keyfile_content  = ""  # Generate a secure keyfile content for replica set authentication

mongodb_default_database = "ten_xr_livekit_qa"

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
mongodb_enable_audit_logging          = false

# Tags
tags = {
  Environment = "qa"
  Project     = "LiveKit"
  Platform    = "ECS"
  Terraform   = "true"
}