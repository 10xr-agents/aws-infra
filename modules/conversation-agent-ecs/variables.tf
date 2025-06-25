# modules/conversation-agent-ecs/variables.tf

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

# Container Configuration (matching EKS deployment)
variable "ecr_repository_url" {
  description = "URL of the ECR repository for the conversation agent image"
  type        = string
  default     = "761018882607.dkr.ecr.us-east-1.amazonaws.com/10xr/conversation-agent"
}

variable "image_tag" {
  description = "Tag of the Docker image to deploy"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Port that the conversation agent container listens on"
  type        = number
  default     = 9600  # Matching the EKS deployment
}

variable "task_cpu" {
  description = "CPU units for the task (1024 = 1 vCPU)"
  type        = number
  default     = 2048  # Matching app_cpu_limit from EKS
}

variable "task_memory" {
  description = "Memory for the task in MB"
  type        = number
  default     = 4096  # Matching app_memory_limit from EKS (4Gi)
}

variable "enable_fargate" {
  description = "Whether to use Fargate launch type"
  type        = bool
  default     = true
}

# Service Configuration
variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2  # Matching app_replicas from EKS
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent during deployment"
  type        = number
  default     = 50
}

variable "deployment_maximum_percent" {
  description = "Maximum percent during deployment"
  type        = number
  default     = 200
}

variable "enable_execute_command" {
  description = "Whether to enable ECS Exec for debugging"
  type        = bool
  default     = false
}

# Application Configuration (matching EKS variables)
variable "log_level" {
  description = "Log level for the application"
  type        = string
  default     = "DEBUG"
}

variable "agent_collection_name" {
  description = "MongoDB collection name for agent context data"
  type        = string
  default     = "agent-context-data"
}

variable "frames_collection_name" {
  description = "MongoDB collection name for voice AI frames"
  type        = string
  default     = "voice-ai-frames"
}

variable "database_name" {
  description = "MongoDB database name"
  type        = string
  default     = "converse-server-qa"
}

variable "mongodb_uri" {
  description = "MongoDB connection URI"
  type        = string
  default     = "mongodb+srv://doadmin:by6n2k14L8g53dt7@db-mongodb-nyc3-70786-efaf17f9.mongo.ondigitalocean.com/ten_xr_temp_agents_local?tls=true&authSource=admin&replicaSet=db-mongodb-nyc3-70786"
  sensitive   = true
}

# LiveKit Configuration
variable "livekit_service_name" {
  description = "Name of the LiveKit service for service discovery"
  type        = string
  default     = "livekit-server"
}

variable "service_discovery_namespace" {
  description = "Service discovery namespace for internal communication"
  type        = string
}

# Secrets Configuration (using AWS Secrets Manager or SSM Parameter Store)
variable "anthropic_api_key_secret_arn" {
  description = "ARN of the secret containing Anthropic API key"
  type        = string
  default     = ""
}

variable "deepgram_api_key_secret_arn" {
  description = "ARN of the secret containing Deepgram API key"
  type        = string
  default     = ""
}

variable "cartesia_api_key_secret_arn" {
  description = "ARN of the secret containing Cartesia API key"
  type        = string
  default     = ""
}

variable "livekit_api_key_secret_arn" {
  description = "ARN of the secret containing LiveKit API key"
  type        = string
  default     = ""
}

variable "livekit_api_secret_secret_arn" {
  description = "ARN of the secret containing LiveKit API secret"
  type        = string
  default     = ""
}

# Default API Keys (for development, use secrets in production)
variable "livekit_api_key" {
  description = "LiveKit API key (use secret for production)"
  type        = string
  default     = "APIoiCmJzAYqd5v"
  sensitive   = true
}

variable "livekit_api_secret" {
  description = "LiveKit API secret (use secret for production)"
  type        = string
  default     = "upXGZbqbwpeftLexnICK401jqQFfvrl1o42N84lsSWcC"
  sensitive   = true
}

# Additional Environment Variables
variable "additional_environment_variables" {
  description = "Additional environment variables for the conversation agent"
  type        = map(string)
  default     = {}
}

# Health Check Configuration
variable "enable_health_check" {
  description = "Whether to enable container health checks"
  type        = bool
  default     = true
}

variable "health_check_command" {
  description = "Health check command"
  type        = string
  default     = "curl -f http://localhost:9600/health || exit 1"
}

variable "health_check_path" {
  description = "Health check path for target group"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 20
}

variable "health_check_retries" {
  description = "Health check retries"
  type        = number
  default     = 5
}

variable "health_check_start_period" {
  description = "Health check start period in seconds"
  type        = number
  default     = 90
}

# Target Group Configuration
variable "target_group_health_check_healthy_threshold" {
  description = "Number of consecutive health checks successes required"
  type        = number
  default     = 2
}

variable "target_group_health_check_unhealthy_threshold" {
  description = "Number of consecutive health check failures required"
  type        = number
  default     = 5
}

variable "target_group_health_check_timeout" {
  description = "Health check timeout"
  type        = number
  default     = 10
}

variable "target_group_health_check_interval" {
  description = "Health check interval"
  type        = number
  default     = 15
}

variable "target_group_health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "target_group_health_check_matcher" {
  description = "Health check matcher"
  type        = string
  default     = "200"
}

variable "target_group_deregistration_delay" {
  description = "Target group deregistration delay"
  type        = number
  default     = 30
}

# Auto Scaling Configuration
variable "enable_auto_scaling" {
  description = "Whether to enable auto scaling"
  type        = bool
  default     = true
}

variable "auto_scaling_min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "auto_scaling_max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 10
}

variable "auto_scaling_cpu_target" {
  description = "Target CPU utilization for auto scaling"
  type        = number
  default     = 70
}

variable "auto_scaling_memory_target" {
  description = "Target memory utilization for auto scaling"
  type        = number
  default     = 80
}

variable "auto_scaling_scale_in_cooldown" {
  description = "Scale in cooldown period in seconds"
  type        = number
  default     = 300
}

variable "auto_scaling_scale_out_cooldown" {
  description = "Scale out cooldown period in seconds"
  type        = number
  default     = 300
}

# Capacity Provider Strategy
variable "capacity_provider_strategy" {
  description = "Capacity provider strategy for the service"
  type = list(object({
    capacity_provider = string
    weight           = number
    base             = number
  }))
  default = [
    {
      capacity_provider = "FARGATE"
      weight           = 1
      base             = 1
    }
  ]
}

# Service Discovery
variable "enable_service_discovery" {
  description = "Whether to enable service discovery"
  type        = bool
  default     = true
}

variable "service_discovery_namespace_id" {
  description = "ID of the service discovery namespace"
  type        = string
  default     = ""
}

# EFS Configuration
variable "enable_efs" {
  description = "Whether to mount EFS storage"
  type        = bool
  default     = false
}

variable "efs_file_system_id" {
  description = "EFS file system ID"
  type        = string
  default     = ""
}

variable "efs_access_point_id" {
  description = "EFS access point ID"
  type        = string
  default     = ""
}

variable "efs_mount_path" {
  description = "Path to mount EFS in the container"
  type        = string
  default     = "/app/storage"
}

# Logging
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}