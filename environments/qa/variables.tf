# environments/qa/variables.tf

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "qa"
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "livekit"
}

variable "domain" {
  description = "Domain name for LiveKit services"
  type        = string
  default     = "qa.10xr.com"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "database_subnets" {
  description = "List of database subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
}

variable "enable_nat_gateway" {
  description = "Whether to enable NAT Gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Whether to use a single NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Whether to use one NAT Gateway per availability zone"
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch" {
  description = "Whether to assign public IP to resources within public subnets"
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Whether to enable ECS Exec for debugging"
  type        = bool
  default     = false
}

# ECS Configuration
variable "enable_container_insights" {
  description = "Whether to enable Container Insights for the ECS cluster"
  type        = bool
  default     = true
}

variable "enable_fargate" {
  description = "Whether to enable Fargate capacity provider"
  type        = bool
  default     = true
}

variable "enable_fargate_spot" {
  description = "Whether to enable Fargate Spot capacity provider"
  type        = bool
  default     = true
}

variable "enable_ec2" {
  description = "Whether to enable EC2 capacity provider"
  type        = bool
  default     = false
}

# EC2 Capacity Provider Configuration (if enabled)
variable "ec2_asg_min_size" {
  description = "Minimum size of the EC2 Auto Scaling Group"
  type        = number
  default     = 0
}

variable "ec2_asg_max_size" {
  description = "Maximum size of the EC2 Auto Scaling Group"
  type        = number
  default     = 10
}

variable "ec2_asg_desired_capacity" {
  description = "Desired capacity of the EC2 Auto Scaling Group"
  type        = number
  default     = 2
}

variable "ec2_instance_types" {
  description = "List of EC2 instance types for the capacity provider"
  type        = list(string)
  default     = ["m5.large", "m5.xlarge"]
}

variable "ec2_ami_id" {
  description = "AMI ID for EC2 instances (defaults to latest ECS-optimized AMI)"
  type        = string
  default     = ""
}

# ALB Configuration
variable "alb_enable_deletion_protection" {
  description = "Whether to enable deletion protection on the ALB"
  type        = bool
  default     = false
}

variable "alb_enable_http2" {
  description = "Whether to enable HTTP2 on the ALB"
  type        = bool
  default     = true
}

variable "alb_idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
  default     = ""
}

# Storage Configuration
variable "efs_performance_mode" {
  description = "Performance mode for EFS"
  type        = string
  default     = "generalPurpose"
}

variable "efs_throughput_mode" {
  description = "Throughput mode for EFS"
  type        = string
  default     = "bursting"
}

variable "efs_provisioned_throughput" {
  description = "Provisioned throughput in MiB/s (required if throughput_mode is provisioned)"
  type        = number
  default     = null
}

variable "create_recordings_bucket" {
  description = "Whether to create S3 bucket for recordings"
  type        = bool
  default     = true
}

variable "recordings_expiration_days" {
  description = "Number of days after which recordings expire"
  type        = number
  default     = 30
}

# Voice Agent Configuration
variable "voice_agent_ecr_repository_url" {
  description = "URL of the ECR repository for the voice agent image"
  type        = string
  default     = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/voice-agent"
}

variable "voice_agent_image_tag" {
  description = "Tag of the Docker image to deploy"
  type        = string
  default     = "latest"
}

variable "voice_agent_port" {
  description = "Port that the voice agent container listens on"
  type        = number
  default     = 9600
}

variable "voice_agent_cpu" {
  description = "CPU units for the voice agent task (1024 = 1 vCPU)"
  type        = number
  default     = 2048
}

variable "voice_agent_memory" {
  description = "Memory for the voice agent task in MB"
  type        = number
  default     = 4096
}

variable "voice_agent_desired_count" {
  description = "Desired number of voice agent tasks"
  type        = number
  default     = 2
}

# Voice Agent Application Configuration
variable "voice_agent_log_level" {
  description = "Log level for the voice agent"
  type        = string
  default     = "DEBUG"
}

variable "voice_agent_agent_collection_name" {
  description = "MongoDB collection name for agent context data"
  type        = string
  default     = "agent-context-data"
}

variable "voice_agent_frames_collection_name" {
  description = "MongoDB collection name for voice AI frames"
  type        = string
  default     = "voice-ai-frames"
}

variable "voice_agent_database_name" {
  description = "MongoDB database name"
  type        = string
  default     = "converse-server-qa"
}

variable "voice_agent_mongodb_uri" {
  description = "MongoDB connection URI"
  type        = string
  default     = "mongodb+srv://doadmin:by6n2k14L8g53dt7@db-mongodb-nyc3-70786-efaf17f9.mongo.ondigitalocean.com/ten_xr_temp_agents_local?tls=true&authSource=admin&replicaSet=db-mongodb-nyc3-70786"
  sensitive   = true
}

# Voice Agent LiveKit Configuration
variable "voice_agent_livekit_service" {
  description = "Name of the LiveKit service"
  type        = string
  default     = "livekit-server"
}

variable "voice_agent_livekit_api_key" {
  description = "LiveKit API key"
  type        = string
  default     = "APIaSovFA9uQ4p5"
  sensitive   = true
}

variable "voice_agent_livekit_api_secret" {
  description = "LiveKit API secret"
  type        = string
  default     = "lTxgQzxS0e2n1vqwOhaiFUiwKWvYeyJukHvnJegbITmA"
  sensitive   = true
}

# Voice Agent Secrets Configuration
variable "voice_agent_anthropic_api_key_secret_arn" {
  description = "ARN of the secret containing Anthropic API key"
  type        = string
  default     = ""
}

variable "voice_agent_deepgram_api_key_secret_arn" {
  description = "ARN of the secret containing Deepgram API key"
  type        = string
  default     = ""
}

variable "voice_agent_cartesia_api_key_secret_arn" {
  description = "ARN of the secret containing Cartesia API key"
  type        = string
  default     = ""
}

variable "voice_agent_livekit_api_key_secret_arn" {
  description = "ARN of the secret containing LiveKit API key"
  type        = string
  default     = ""
}

variable "voice_agent_livekit_api_secret_secret_arn" {
  description = "ARN of the secret containing LiveKit API secret"
  type        = string
  default     = ""
}

# Voice Agent Additional Environment Variables
variable "voice_agent_additional_environment_variables" {
  description = "Additional environment variables for the voice agent"
  type        = map(string)
  default     = {}
}

# Voice Agent Health Check Configuration
variable "voice_agent_enable_health_check" {
  description = "Whether to enable container health checks for voice agent"
  type        = bool
  default     = true
}

variable "voice_agent_health_check_command" {
  description = "Health check command for voice agent"
  type        = string
  default     = "curl -f http://localhost:9600/health || exit 1"
}

variable "voice_agent_health_check_path" {
  description = "Health check path for voice agent target group"
  type        = string
  default     = "/health"
}

variable "voice_agent_health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "voice_agent_health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 20
}

variable "voice_agent_health_check_start_period" {
  description = "Health check start period in seconds"
  type        = number
  default     = 90
}

# Voice Agent Auto Scaling Configuration
variable "voice_agent_enable_auto_scaling" {
  description = "Whether to enable auto scaling for voice agent"
  type        = bool
  default     = true
}

variable "voice_agent_min_capacity" {
  description = "Minimum number of voice agent tasks"
  type        = number
  default     = 1
}

variable "voice_agent_max_capacity" {
  description = "Maximum number of voice agent tasks"
  type        = number
  default     = 10
}

variable "voice_agent_cpu_target" {
  description = "Target CPU utilization for voice agent auto scaling"
  type        = number
  default     = 70
}

variable "voice_agent_memory_target" {
  description = "Target memory utilization for voice agent auto scaling"
  type        = number
  default     = 80
}

# Voice Agent Service Discovery Configuration
variable "voice_agent_enable_service_discovery" {
  description = "Whether to enable service discovery for voice agent"
  type        = bool
  default     = true
}

# Voice Agent EFS Configuration
variable "voice_agent_enable_efs" {
  description = "Whether to mount EFS storage for voice agent"
  type        = bool
  default     = false
}

variable "voice_agent_efs_mount_path" {
  description = "Path to mount EFS in the voice agent container"
  type        = string
  default     = "/app/storage"
}

# LiveKit Proxy Configuration
variable "livekit_proxy_ecr_repository_url" {
  description = "URL of the ECR repository for the LiveKit proxy image"
  type        = string
  default     = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/livekit-proxy-service"
}

variable "livekit_proxy_image_tag" {
  description = "Tag of the Docker image to deploy"
  type        = string
  default     = "latest"
}

variable "livekit_proxy_port" {
  description = "Port that the LiveKit proxy container listens on"
  type        = number
  default     = 8080
}

variable "livekit_proxy_cpu" {
  description = "CPU units for the LiveKit proxy task (1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "livekit_proxy_memory" {
  description = "Memory for the LiveKit proxy task in MB"
  type        = number
  default     = 2048
}

variable "livekit_proxy_desired_count" {
  description = "Desired number of LiveKit proxy tasks"
  type        = number
  default     = 2
}

# LiveKit Proxy Application Configuration
variable "livekit_proxy_log_level" {
  description = "Log level for the LiveKit proxy"
  type        = string
  default     = "INFO"
}

# LiveKit Proxy LiveKit Configuration
variable "livekit_proxy_livekit_service" {
  description = "Name of the LiveKit service"
  type        = string
  default     = "livekit-server"
}

variable "livekit_proxy_livekit_api_key" {
  description = "LiveKit API key for proxy"
  type        = string
  default     = "APIaSovFA9uQ4p5"
  sensitive   = true
}

variable "livekit_proxy_livekit_api_secret" {
  description = "LiveKit API secret for proxy"
  type        = string
  default     = "lTxgQzxS0e2n1vqwOhaiFUiwKWvYeyJukHvnJegbITmA"
  sensitive   = true
}

# LiveKit Proxy Secrets Configuration
variable "livekit_proxy_livekit_api_key_secret_arn" {
  description = "ARN of the secret containing LiveKit API key for proxy"
  type        = string
  default     = ""
}

variable "livekit_proxy_livekit_api_secret_secret_arn" {
  description = "ARN of the secret containing LiveKit API secret for proxy"
  type        = string
  default     = ""
}

# LiveKit Proxy Additional Environment Variables
variable "livekit_proxy_additional_environment_variables" {
  description = "Additional environment variables for the LiveKit proxy"
  type        = map(string)
  default     = {}
}

# LiveKit Proxy Health Check Configuration
variable "livekit_proxy_enable_health_check" {
  description = "Whether to enable container health checks for LiveKit proxy"
  type        = bool
  default     = true
}

variable "livekit_proxy_health_check_command" {
  description = "Health check command for LiveKit proxy"
  type        = string
  default     = "curl -f http://localhost:8080/health || exit 1"
}

variable "livekit_proxy_health_check_path" {
  description = "Health check path for LiveKit proxy target group"
  type        = string
  default     = "/health"
}

variable "livekit_proxy_health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "livekit_proxy_health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 20
}

variable "livekit_proxy_health_check_start_period" {
  description = "Health check start period in seconds"
  type        = number
  default     = 90
}

# LiveKit Proxy Auto Scaling Configuration
variable "livekit_proxy_enable_auto_scaling" {
  description = "Whether to enable auto scaling for LiveKit proxy"
  type        = bool
  default     = true
}

variable "livekit_proxy_min_capacity" {
  description = "Minimum number of LiveKit proxy tasks"
  type        = number
  default     = 1
}

variable "livekit_proxy_max_capacity" {
  description = "Maximum number of LiveKit proxy tasks"
  type        = number
  default     = 10
}

variable "livekit_proxy_cpu_target" {
  description = "Target CPU utilization for LiveKit proxy auto scaling"
  type        = number
  default     = 70
}

variable "livekit_proxy_memory_target" {
  description = "Target memory utilization for LiveKit proxy auto scaling"
  type        = number
  default     = 80
}

# LiveKit Proxy Service Discovery Configuration
variable "livekit_proxy_enable_service_discovery" {
  description = "Whether to enable service discovery for LiveKit proxy"
  type        = bool
  default     = true
}

# LiveKit Proxy EFS Configuration
variable "livekit_proxy_enable_efs" {
  description = "Whether to mount EFS storage for LiveKit proxy"
  type        = bool
  default     = false
}

variable "livekit_proxy_efs_mount_path" {
  description = "Path to mount EFS in the LiveKit proxy container"
  type        = string
  default     = "/app/storage"
}

# Agent Analytics Service Configuration
variable "agent_analytics_ecr_repository_url" {
  description = "URL of the ECR repository for the agent analytics image"
  type        = string
  default     = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/agent-analytics-service"
}

variable "agent_analytics_image_tag" {
  description = "Tag of the Docker image to deploy"
  type        = string
  default     = "latest"
}

variable "agent_analytics_port" {
  description = "Port that the agent analytics container listens on"
  type        = number
  default     = 3000
}

variable "agent_analytics_cpu" {
  description = "CPU units for the agent analytics task (1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "agent_analytics_memory" {
  description = "Memory for the agent analytics task in MB"
  type        = number
  default     = 2048
}

variable "agent_analytics_desired_count" {
  description = "Desired number of agent analytics tasks"
  type        = number
  default     = 2
}

# Agent Analytics Application Configuration
variable "agent_analytics_log_level" {
  description = "Log level for the agent analytics service"
  type        = string
  default     = "INFO"
}

variable "agent_analytics_mongodb_uri" {
  description = "MongoDB connection URI for agent analytics"
  type        = string
  default     = ""
  sensitive   = true
}

variable "agent_analytics_additional_environment_variables" {
  description = "Additional environment variables for the agent analytics service"
  type        = map(string)
  default     = {}
}

# Agent Analytics Health Check Configuration
variable "agent_analytics_enable_health_check" {
  description = "Whether to enable container health checks for agent analytics"
  type        = bool
  default     = true
}

variable "agent_analytics_health_check_command" {
  description = "Health check command for agent analytics"
  type        = string
  default     = "curl -f http://localhost:3000/health || exit 1"
}

variable "agent_analytics_health_check_path" {
  description = "Health check path for agent analytics target group"
  type        = string
  default     = "/health"
}

variable "agent_analytics_health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "agent_analytics_health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 20
}

variable "agent_analytics_health_check_start_period" {
  description = "Health check start period in seconds"
  type        = number
  default     = 90
}

# Agent Analytics Auto Scaling Configuration
variable "agent_analytics_enable_auto_scaling" {
  description = "Whether to enable auto scaling for agent analytics"
  type        = bool
  default     = true
}

variable "agent_analytics_min_capacity" {
  description = "Minimum number of agent analytics tasks"
  type        = number
  default     = 1
}

variable "agent_analytics_max_capacity" {
  description = "Maximum number of agent analytics tasks"
  type        = number
  default     = 10
}

variable "agent_analytics_cpu_target" {
  description = "Target CPU utilization for agent analytics auto scaling"
  type        = number
  default     = 70
}

variable "agent_analytics_memory_target" {
  description = "Target memory utilization for agent analytics auto scaling"
  type        = number
  default     = 80
}

# Agent Analytics Service Discovery Configuration
variable "agent_analytics_enable_service_discovery" {
  description = "Whether to enable service discovery for agent analytics"
  type        = bool
  default     = true
}

# Agent Analytics EFS Configuration
variable "agent_analytics_enable_efs" {
  description = "Whether to mount EFS storage for agent analytics"
  type        = bool
  default     = false
}

variable "agent_analytics_efs_mount_path" {
  description = "Path to mount EFS in the agent analytics container"
  type        = string
  default     = "/app/storage"
}

# UI Console Service Configuration
variable "ui_console_ecr_repository_url" {
  description = "URL of the ECR repository for the UI console image"
  type        = string
  default     = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/ui-console"
}

variable "ui_console_image_tag" {
  description = "Tag of the Docker image to deploy"
  type        = string
  default     = "latest"
}

variable "ui_console_port" {
  description = "Port that the UI console container listens on"
  type        = number
  default     = 80
}

variable "ui_console_cpu" {
  description = "CPU units for the UI console task (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "ui_console_memory" {
  description = "Memory for the UI console task in MB"
  type        = number
  default     = 1024
}

variable "ui_console_desired_count" {
  description = "Desired number of UI console tasks"
  type        = number
  default     = 2
}

# UI Console Application Configuration
variable "ui_console_log_level" {
  description = "Log level for the UI console service"
  type        = string
  default     = "INFO"
}

variable "ui_console_additional_environment_variables" {
  description = "Additional environment variables for the UI console service"
  type        = map(string)
  default     = {}
}

# UI Console Health Check Configuration
variable "ui_console_enable_health_check" {
  description = "Whether to enable container health checks for UI console"
  type        = bool
  default     = true
}

variable "ui_console_health_check_command" {
  description = "Health check command for UI console"
  type        = string
  default     = "curl -f http://localhost:80/health || exit 1"
}

variable "ui_console_health_check_path" {
  description = "Health check path for UI console target group"
  type        = string
  default     = "/"
}

variable "ui_console_health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "ui_console_health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 20
}

variable "ui_console_health_check_start_period" {
  description = "Health check start period in seconds"
  type        = number
  default     = 90
}

# UI Console Auto Scaling Configuration
variable "ui_console_enable_auto_scaling" {
  description = "Whether to enable auto scaling for UI console"
  type        = bool
  default     = true
}

variable "ui_console_min_capacity" {
  description = "Minimum number of UI console tasks"
  type        = number
  default     = 1
}

variable "ui_console_max_capacity" {
  description = "Maximum number of UI console tasks"
  type        = number
  default     = 10
}

variable "ui_console_cpu_target" {
  description = "Target CPU utilization for UI console auto scaling"
  type        = number
  default     = 70
}

variable "ui_console_memory_target" {
  description = "Target memory utilization for UI console auto scaling"
  type        = number
  default     = 80
}

# UI Console Service Discovery Configuration
variable "ui_console_enable_service_discovery" {
  description = "Whether to enable service discovery for UI console"
  type        = bool
  default     = true
}

# UI Console EFS Configuration
variable "ui_console_enable_efs" {
  description = "Whether to mount EFS storage for UI console"
  type        = bool
  default     = false
}

variable "ui_console_efs_mount_path" {
  description = "Path to mount EFS in the UI console container"
  type        = string
  default     = "/app/storage"
}

# Agentic Framework Service Configuration
variable "agentic_framework_ecr_repository_url" {
  description = "URL of the ECR repository for the agentic framework image"
  type        = string
  default     = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr-agents/agentic-framework-service"
}

variable "agentic_framework_image_tag" {
  description = "Tag of the Docker image to deploy"
  type        = string
  default     = "latest"
}

variable "agentic_framework_port" {
  description = "Port that the agentic framework container listens on"
  type        = number
  default     = 8000
}

variable "agentic_framework_cpu" {
  description = "CPU units for the agentic framework task (1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "agentic_framework_memory" {
  description = "Memory for the agentic framework task in MB"
  type        = number
  default     = 2048
}

variable "agentic_framework_desired_count" {
  description = "Desired number of agentic framework tasks"
  type        = number
  default     = 2
}

# Agentic Framework Application Configuration
variable "agentic_framework_log_level" {
  description = "Log level for the agentic framework service"
  type        = string
  default     = "INFO"
}

variable "agentic_framework_mongodb_uri" {
  description = "MongoDB connection URI for agentic framework"
  type        = string
  default     = ""
  sensitive   = true
}

variable "agentic_framework_additional_environment_variables" {
  description = "Additional environment variables for the agentic framework service"
  type        = map(string)
  default     = {}
}

# Agentic Framework Health Check Configuration
variable "agentic_framework_enable_health_check" {
  description = "Whether to enable container health checks for agentic framework"
  type        = bool
  default     = true
}

variable "agentic_framework_health_check_command" {
  description = "Health check command for agentic framework"
  type        = string
  default     = "curl -f http://localhost:8000/health || exit 1"
}

variable "agentic_framework_health_check_path" {
  description = "Health check path for agentic framework target group"
  type        = string
  default     = "/health"
}

variable "agentic_framework_health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "agentic_framework_health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 20
}

variable "agentic_framework_health_check_start_period" {
  description = "Health check start period in seconds"
  type        = number
  default     = 90
}

# Agentic Framework Auto Scaling Configuration
variable "agentic_framework_enable_auto_scaling" {
  description = "Whether to enable auto scaling for agentic framework"
  type        = bool
  default     = true
}

variable "agentic_framework_min_capacity" {
  description = "Minimum number of agentic framework tasks"
  type        = number
  default     = 1
}

variable "agentic_framework_max_capacity" {
  description = "Maximum number of agentic framework tasks"
  type        = number
  default     = 10
}

variable "agentic_framework_cpu_target" {
  description = "Target CPU utilization for agentic framework auto scaling"
  type        = number
  default     = 70
}

variable "agentic_framework_memory_target" {
  description = "Target memory utilization for agentic framework auto scaling"
  type        = number
  default     = 80
}

# Agentic Framework Service Discovery Configuration
variable "agentic_framework_enable_service_discovery" {
  description = "Whether to enable service discovery for agentic framework"
  type        = bool
  default     = true
}

# Agentic Framework EFS Configuration
variable "agentic_framework_enable_efs" {
  description = "Whether to mount EFS storage for agentic framework"
  type        = bool
  default     = false
}

variable "agentic_framework_efs_mount_path" {
  description = "Path to mount EFS in the agentic framework container"
  type        = string
  default     = "/app/storage"
}

# MongoDB Configuration Variables
variable "mongodb_replica_count" {
  description = "Number of MongoDB replica set members (should be odd number: 1, 3, 5, etc.)"
  type        = number
  default     = 3
}

variable "mongodb_instance_type" {
  description = "EC2 instance type for MongoDB nodes"
  type        = string
  default     = "t3.large"
}

variable "mongodb_ami_id" {
  description = "AMI ID for MongoDB instances. If empty, will use latest Ubuntu 22.04"
  type        = string
  default     = ""
}

variable "mongodb_key_name" {
  description = "Name of the SSH key pair for MongoDB EC2 instances"
  type        = string
}

variable "mongodb_version" {
  description = "MongoDB version to install"
  type        = string
  default     = "7.0"
}

variable "mongodb_admin_username" {
  description = "MongoDB admin username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "mongodb_admin_password" {
  description = "MongoDB admin password"
  type        = string
  sensitive   = true
}

variable "mongodb_keyfile_content" {
  description = "Content of the MongoDB keyfile for replica set authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "mongodb_default_database" {
  description = "Default database name"
  type        = string
  default     = "livekit_qa"
}

variable "mongodb_root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20
}

variable "mongodb_data_volume_size" {
  description = "Size of the data EBS volume in GB"
  type        = number
  default     = 100
}

variable "mongodb_data_volume_type" {
  description = "Type of the data EBS volume (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "mongodb_data_volume_iops" {
  description = "IOPS for the data volume (only for gp3, io1, io2)"
  type        = number
  default     = 3000
}

variable "mongodb_data_volume_throughput" {
  description = "Throughput in MiB/s for the data volume (only for gp3)"
  type        = number
  default     = 125
}

variable "mongodb_allow_ssh" {
  description = "Whether to allow SSH access to MongoDB instances"
  type        = bool
  default     = false
}

variable "mongodb_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to MongoDB instances"
  type        = list(string)
  default     = []
}

variable "mongodb_enable_monitoring" {
  description = "Whether to enable CloudWatch monitoring for MongoDB"
  type        = bool
  default     = true
}

variable "mongodb_log_retention_days" {
  description = "CloudWatch log retention in days for MongoDB"
  type        = number
  default     = 7
}

variable "mongodb_create_dns_records" {
  description = "Whether to create Route53 DNS records for MongoDB"
  type        = bool
  default     = true
}

variable "mongodb_private_domain" {
  description = "Private domain for MongoDB DNS records"
  type        = string
  default     = ""
}

variable "mongodb_backup_enabled" {
  description = "Whether to enable automated EBS snapshots for MongoDB"
  type        = bool
  default     = true
}

variable "mongodb_backup_schedule" {
  description = "Cron expression for MongoDB backup schedule"
  type        = string
  default     = "cron(0 2 * * ? *)"
}

variable "mongodb_backup_retention_days" {
  description = "Number of days to retain MongoDB backups"
  type        = number
  default     = 7
}

variable "mongodb_store_connection_string_in_ssm" {
  description = "Whether to store MongoDB connection string in AWS Systems Manager Parameter Store"
  type        = bool
  default     = true
}

variable "mongodb_enable_encryption_at_rest" {
  description = "Whether to enable MongoDB encryption at rest"
  type        = bool
  default     = true
}

variable "mongodb_enable_audit_logging" {
  description = "Whether to enable MongoDB audit logging"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {
    Environment = "qa"
    Project     = "LiveKit"
    Platform    = "ECS"
    Terraform   = "true"
  }
}