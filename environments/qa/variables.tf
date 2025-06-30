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

# environments/qa/variables.tf

# Most existing variables remain the same
# Replace conversation_agent variables with voice_agent

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

# Application Configuration
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

# LiveKit Configuration
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

# Secrets Configuration
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

# Additional Environment Variables
variable "voice_agent_additional_environment_variables" {
  description = "Additional environment variables for the voice agent"
  type        = map(string)
  default     = {}
}

# Health Check Configuration
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

# Auto Scaling Configuration
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

# Service Discovery Configuration
variable "voice_agent_enable_service_discovery" {
  description = "Whether to enable service discovery for voice agent"
  type        = bool
  default     = true
}

# EFS Configuration
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