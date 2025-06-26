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

# EKS Configuration
enable_eks                    = true
eks_kubernetes_version        = "1.28"
eks_endpoint_private_access   = true
eks_endpoint_public_access    = true
eks_public_access_cidrs       = ["0.0.0.0/0"]
eks_enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
eks_log_retention_days        = 7

# EKS Node Group Configuration
eks_node_group_capacity_type   = "ON_DEMAND"
eks_node_group_instance_types  = ["t3.medium", "t3.large"]
eks_node_group_ami_type        = "AL2_x86_64"
eks_node_group_disk_size       = 20
eks_node_group_desired_size    = 2
eks_node_group_max_size        = 4
eks_node_group_min_size        = 1
eks_node_group_max_unavailable = 1
eks_enable_launch_template     = false

# EKS Add-ons (use latest versions by default)
eks_vpc_cni_version        = null
eks_coredns_version        = null
eks_kube_proxy_version     = null
eks_enable_ebs_csi_driver  = true
eks_ebs_csi_driver_version = null

# ALB Configuration
alb_enable_deletion_protection = false
alb_enable_http2              = true
alb_idle_timeout              = 60
# acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# LiveKit Configuration (for EKS)
livekit_namespace = "livekit"
efs_performance_mode       = "generalPurpose"
efs_throughput_mode        = "bursting"
create_recordings_bucket   = true
recordings_expiration_days = 30

# Conversation Agent Configuration (ECS deployment)
conversation_agent_ecr_repository_url = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/conversation-agent"
conversation_agent_image_tag          = "latest"
conversation_agent_port               = 9600
conversation_agent_cpu                = 2048  # 2000m from EKS config
conversation_agent_memory             = 4096  # 4Gi from EKS config
conversation_agent_desired_count      = 2

conversation_agent_log_level               = "DEBUG"
conversation_agent_agent_collection_name   = "agent-context-data"
conversation_agent_frames_collection_name  = "voice-ai-frames"
conversation_agent_database_name          = "converse-server-qa"

conversation_agent_mongodb_uri = "mongodb+srv://doadmin:by6n2k14L8g53dt7@db-mongodb-nyc3-70786-efaf17f9.mongo.ondigitalocean.com/ten_xr_temp_agents_local?tls=true&authSource=admin&replicaSet=db-mongodb-nyc3-70786"

conversation_agent_livekit_service    = "livekit-server"
conversation_agent_livekit_api_key    = "APIoiCmJzAYqd5v"
conversation_agent_livekit_api_secret = "upXGZbqbwpeftLexnICK401jqQFfvrl1o42N84lsSWcC"

# Secrets Configuration (use these ARNs for production deployment)
# Store sensitive API keys in AWS Secrets Manager and reference them here
# conversation_agent_anthropic_api_key_secret_arn    = "arn:aws:secretsmanager:us-east-1:123456789012:secret:conversation-agent/anthropic-api-key-AbCdEf"
# conversation_agent_deepgram_api_key_secret_arn     = "arn:aws:secretsmanager:us-east-1:123456789012:secret:conversation-agent/deepgram-api-key-GhIjKl"
# conversation_agent_cartesia_api_key_secret_arn     = "arn:aws:secretsmanager:us-east-1:123456789012:secret:conversation-agent/cartesia-api-key-MnOpQr"
# conversation_agent_livekit_api_key_secret_arn      = "arn:aws:secretsmanager:us-east-1:123456789012:secret:conversation-agent/livekit-api-key-StUvWx"
# conversation_agent_livekit_api_secret_secret_arn   = "arn:aws:secretsmanager:us-east-1:123456789012:secret:conversation-agent/livekit-api-secret-YzAbCd"

# Additional Environment Variables (if needed)
conversation_agent_additional_environment_variables = {
  # Add any additional environment variables specific to your deployment
}

# Health Check Configuration (matching EKS timeouts)
conversation_agent_enable_health_check    = true
conversation_agent_health_check_command   = "curl -f http://localhost:9600/health || exit 1"
conversation_agent_health_check_path      = "/health"
conversation_agent_health_check_interval  = 30
conversation_agent_health_check_timeout   = 20
conversation_agent_health_check_start_period = 90  # Increased initial delay

# Auto Scaling Configuration
conversation_agent_enable_auto_scaling = true
conversation_agent_min_capacity        = 1
conversation_agent_max_capacity        = 10
conversation_agent_cpu_target          = 70
conversation_agent_memory_target       = 80

# Service Discovery
conversation_agent_enable_service_discovery = true

# EFS Storage (enable if your conversation agent needs persistent storage)
conversation_agent_enable_efs     = false
conversation_agent_efs_mount_path = "/app/storage"

# Tags
tags = {
  Environment = "qa"
  Project     = "LiveKit"
  Platform    = "ECS-EKS"
  Terraform   = "true"
}