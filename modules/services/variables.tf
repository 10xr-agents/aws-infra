# modules/services/variables.tf

# Common Variables
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

variable "enable_fargate" {
  description = "Whether to use Fargate launch type"
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Whether to enable ECS Exec for debugging"
  type        = bool
  default     = false
}

# Service Discovery
variable "service_discovery_namespace" {
  description = "Service discovery namespace for internal communication"
  type        = string
}

variable "service_discovery_namespace_id" {
  description = "ID of the service discovery namespace"
  type        = string
}

variable "livekit_service_name" {
  description = "Name of the LiveKit service for service discovery"
  type        = string
  default     = "livekit-server"
}

# Capacity Provider Strategy
variable "capacity_provider_strategy" {
  description = "Capacity provider strategy for the services"
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

# EFS Configuration
variable "efs_file_system_id" {
  description = "EFS file system ID"
  type        = string
  default     = ""
}

# Logging
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# Voice Agent Configuration
variable "voice_agent_ecr_repository_url" {
  description = "URL of the ECR repository for the voice agent image"
  type        = string
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

variable "voice_agent_deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent during deployment"
  type        = number
  default     = 50
}

variable "voice_agent_deployment_maximum_percent" {
  description = "Maximum percent during deployment"
  type        = number
  default     = 200
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
  sensitive   = true
}

variable "voice_agent_livekit_api_key" {
  description = "LiveKit API key for voice agent"
  type        = string
  default     = ""
  sensitive   = true
}

variable "voice_agent_livekit_api_secret" {
  description = "LiveKit API secret for voice agent"
  type        = string
  default     = ""
  sensitive   = true
}

# Voice Agent Secrets
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

variable "voice_agent_additional_environment_variables" {
  description = "Additional environment variables for the voice agent"
  type        = map(string)
  default     = {}
}

# Voice Agent Health Check
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

variable "voice_agent_health_check_retries" {
  description = "Health check retries"
  type        = number
  default     = 5
}

variable "voice_agent_health_check_start_period" {
  description = "Health check start period in seconds"
  type        = number
  default     = 90
}

# Voice Agent Target Group Configuration
variable "voice_agent_target_group_health_check_healthy_threshold" {
  description = "Number of consecutive health checks successes required"
  type        = number
  default     = 2
}

variable "voice_agent_target_group_health_check_unhealthy_threshold" {
  description = "Number of consecutive health check failures required"
  type        = number
  default     = 5
}

variable "voice_agent_target_group_health_check_timeout" {
  description = "Health check timeout"
  type        = number
  default     = 10
}

variable "voice_agent_target_group_health_check_interval" {
  description = "Health check interval"
  type        = number
  default     = 15
}

variable "voice_agent_target_group_health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "voice_agent_target_group_health_check_matcher" {
  description = "Health check matcher"
  type        = string
  default     = "200"
}

variable "voice_agent_target_group_deregistration_delay" {
  description = "Target group deregistration delay"
  type        = number
  default     = 30
}

# Voice Agent Auto Scaling
variable "voice_agent_enable_auto_scaling" {
  description = "Whether to enable auto scaling for voice agent"
  type        = bool
  default     = true
}

variable "voice_agent_auto_scaling_min_capacity" {
  description = "Minimum number of voice agent tasks"
  type        = number
  default     = 1
}

variable "voice_agent_auto_scaling_max_capacity" {
  description = "Maximum number of voice agent tasks"
  type        = number
  default     = 10
}

variable "voice_agent_auto_scaling_cpu_target" {
  description = "Target CPU utilization for voice agent auto scaling"
  type        = number
  default     = 70
}

variable "voice_agent_auto_scaling_memory_target" {
  description = "Target memory utilization for voice agent auto scaling"
  type        = number
  default     = 80
}

variable "voice_agent_auto_scaling_scale_in_cooldown" {
  description = "Scale in cooldown period in seconds"
  type        = number
  default     = 300
}

variable "voice_agent_auto_scaling_scale_out_cooldown" {
  description = "Scale out cooldown period in seconds"
  type        = number
  default     = 300
}

# Voice Agent Service Discovery
variable "voice_agent_enable_service_discovery" {
  description = "Whether to enable service discovery for voice agent"
  type        = bool
  default     = true
}

# Voice Agent EFS
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

variable "livekit_proxy_deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent during deployment"
  type        = number
  default     = 50
}

variable "livekit_proxy_deployment_maximum_percent" {
  description = "Maximum percent during deployment"
  type        = number
  default     = 200
}

# LiveKit Proxy Application Configuration
variable "livekit_proxy_log_level" {
  description = "Log level for the LiveKit proxy"
  type        = string
  default     = "INFO"
}

variable "livekit_proxy_livekit_api_key" {
  description = "LiveKit API key for proxy"
  type        = string
  default     = ""
  sensitive   = true
}

variable "livekit_proxy_livekit_api_secret" {
  description = "LiveKit API secret for proxy"
  type        = string
  default     = ""
  sensitive   = true
}

# LiveKit Proxy Secrets
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

variable "livekit_proxy_additional_environment_variables" {
  description = "Additional environment variables for the LiveKit proxy"
  type        = map(string)
  default     = {}
}

# LiveKit Proxy Health Check
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

variable "livekit_proxy_health_check_retries" {
  description = "Health check retries"
  type        = number
  default     = 5
}

variable "livekit_proxy_health_check_start_period" {
  description = "Health check start period in seconds"
  type        = number
  default     = 90
}

# LiveKit Proxy Target Group Configuration
variable "livekit_proxy_target_group_health_check_healthy_threshold" {
  description = "Number of consecutive health checks successes required"
  type        = number
  default     = 2
}

variable "livekit_proxy_target_group_health_check_unhealthy_threshold" {
  description = "Number of consecutive health check failures required"
  type        = number
  default     = 5
}

variable "livekit_proxy_target_group_health_check_timeout" {
  description = "Health check timeout"
  type        = number
  default     = 10
}

variable "livekit_proxy_target_group_health_check_interval" {
  description = "Health check interval"
  type        = number
  default     = 15
}

variable "livekit_proxy_target_group_health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "livekit_proxy_target_group_health_check_matcher" {
  description = "Health check matcher"
  type        = string
  default     = "200"
}

variable "livekit_proxy_target_group_deregistration_delay" {
  description = "Target group deregistration delay"
  type        = number
  default     = 30
}

# LiveKit Proxy Auto Scaling
variable "livekit_proxy_enable_auto_scaling" {
  description = "Whether to enable auto scaling for LiveKit proxy"
  type        = bool
  default     = true
}

variable "livekit_proxy_auto_scaling_min_capacity" {
  description = "Minimum number of LiveKit proxy tasks"
  type        = number
  default     = 1
}

variable "livekit_proxy_auto_scaling_max_capacity" {
  description = "Maximum number of LiveKit proxy tasks"
  type        = number
  default     = 10
}

variable "livekit_proxy_auto_scaling_cpu_target" {
  description = "Target CPU utilization for LiveKit proxy auto scaling"
  type        = number
  default     = 70
}

variable "livekit_proxy_auto_scaling_memory_target" {
  description = "Target memory utilization for LiveKit proxy auto scaling"
  type        = number
  default     = 80
}

variable "livekit_proxy_auto_scaling_scale_in_cooldown" {
  description = "Scale in cooldown period in seconds"
  type        = number
  default     = 300
}

variable "livekit_proxy_auto_scaling_scale_out_cooldown" {
  description = "Scale out cooldown period in seconds"
  type        = number
  default     = 300
}

# LiveKit Proxy Service Discovery
variable "livekit_proxy_enable_service_discovery" {
  description = "Whether to enable service discovery for LiveKit proxy"
  type        = bool
  default     = true
}

# LiveKit Proxy EFS
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

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}