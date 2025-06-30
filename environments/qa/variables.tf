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

variable "enable_service_discovery" {
  description = "Whether to enable service discovery"
  type        = bool
  default     = true
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

variable "ssl_policy" {
  description = "SSL policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
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

# Removed mongodb_key_name variable - key pair will be created automatically

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

# environments/qa/variables-ecs.tf

variable "ecs_services" {
  description = "Map of ECS services to create with their configurations"
  type = map(object({
    # Core configuration
    image         = string
    image_tag     = optional(string, "latest")
    port          = number
    cpu           = number
    memory        = number
    desired_count = number

    # Environment and secrets
    environment = optional(map(string), {})
    secrets = optional(list(object({
      name       = string
      value_from = string
    })), [])

    # Capacity provider strategy
    capacity_provider_strategy = list(object({
      capacity_provider = string
      weight           = number
      base             = number
    }))

    # Health checks
    health_check = optional(object({
      path                = optional(string, "/health")
      interval            = optional(number, 30)
      timeout             = optional(number, 20)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 3)
      matcher             = optional(string, "200")
    }), {})

    container_health_check = optional(object({
      command      = string
      interval     = optional(number, 30)
      timeout      = optional(number, 20)
      retries      = optional(number, 3)
      start_period = optional(number, 90)
    }))

    # Auto scaling
    enable_auto_scaling       = optional(bool, true)
    auto_scaling_min_capacity = optional(number, 1)
    auto_scaling_max_capacity = optional(number, 10)
    auto_scaling_cpu_target   = optional(number, 70)
    auto_scaling_memory_target = optional(number, 80)

    # Service discovery and load balancer
    enable_service_discovery = optional(bool, true)
    enable_load_balancer     = optional(bool, true)
    deregistration_delay     = optional(number, 30)

    # ALB routing
    alb_priority      = optional(number)
    alb_path_patterns = optional(list(string))

    # Additional configuration
    efs_config = optional(object({
      enabled    = bool
      mount_path = string
    }))
    additional_task_policies = optional(map(string), {})
    memory_reservation      = optional(number)
    linux_parameters        = optional(any)
    ulimits                = optional(any)
  }))
}

variable "create_alb_rules" {
  description = "Whether to create ALB listener rules"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {
    Environment = "qa"
    Project     = "10xR-Agents"
    Platform    = "AWS"
    Terraform   = "true"
  }
}