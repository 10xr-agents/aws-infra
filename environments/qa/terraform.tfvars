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
enable_ec2               = false

# EC2 Capacity Provider Configuration (if enabled)
ec2_asg_min_size         = 0
ec2_asg_max_size         = 10
ec2_asg_desired_capacity = 2
ec2_instance_types       = ["m5.large", "m5.xlarge", "m5a.large", "m5a.xlarge"]

# ALB Configuration
alb_enable_deletion_protection = false
alb_enable_http2              = true
alb_idle_timeout              = 60
# acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Storage Configuration
efs_performance_mode       = "generalPurpose"
efs_throughput_mode        = "bursting"
create_recordings_bucket   = true
recordings_expiration_days = 30


# environments/qa/terraform.tfvars

# Most existing configuration remains the same
# Replace conversation_agent with voice_agent configuration

voice_agent_ecr_repository_url = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/voice-agent"
voice_agent_image_tag          = "latest"
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

# Secrets Configuration (use these ARNs for production deployment)
# voice_agent_anthropic_api_key_secret_arn    = "arn:aws:secretsmanager:us-east-1:123456789012:secret:voice-agent/anthropic-api-key-AbCdEf"
# voice_agent_deepgram_api_key_secret_arn     = "arn:aws:secretsmanager:us-east-1:123456789012:secret:voice-agent/deepgram-api-key-GhIjKl"
# voice_agent_cartesia_api_key_secret_arn     = "arn:aws:secretsmanager:us-east-1:123456789012:secret:voice-agent/cartesia-api-key-MnOpQr"
# voice_agent_livekit_api_key_secret_arn      = "arn:aws:secretsmanager:us-east-1:123456789012:secret:voice-agent/livekit-api-key-StUvWx"
# voice_agent_livekit_api_secret_secret_arn   = "arn:aws:secretsmanager:us-east-1:123456789012:secret:voice-agent/livekit-api-secret-YzAbCd"

# Additional Environment Variables (if needed)
voice_agent_additional_environment_variables = {
  # Add any additional environment variables specific to your deployment
}

# Health Check Configuration
voice_agent_enable_health_check    = true
voice_agent_health_check_command   = "curl -f http://localhost:9600/health || exit 1"
voice_agent_health_check_path      = "/health"
voice_agent_health_check_interval  = 30
voice_agent_health_check_timeout   = 20
voice_agent_health_check_start_period = 90

# Auto Scaling Configuration
voice_agent_enable_auto_scaling = true
voice_agent_min_capacity        = 1
voice_agent_max_capacity        = 10
voice_agent_cpu_target          = 70
voice_agent_memory_target       = 80

# Service Discovery
voice_agent_enable_service_discovery = true

# EFS Storage (enable if your voice agent needs persistent storage)
voice_agent_enable_efs     = false
voice_agent_efs_mount_path = "/app/storage"

# Tags
tags = {
  Environment = "qa"
  Project     = "LiveKit"
  Platform    = "ECS"
  Terraform   = "true"
}