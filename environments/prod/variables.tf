# environments/prod/variables.tf

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "ten_xr_app_prod"
}

variable "domain" {
  description = "Domain name for 10xR services"
  type        = string
  default     = "10xr.co"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "azs" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
}

variable "database_subnets" {
  description = "List of database subnet CIDR blocks"
  type        = list(string)
  default     = ["10.1.201.0/24", "10.1.202.0/24", "10.1.203.0/24"]
}

variable "enable_nat_gateway" {
  description = "Whether to enable NAT Gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Whether to use a single NAT Gateway for all private subnets"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Whether to use one NAT Gateway per availability zone"
  type        = bool
  default     = false
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
  default     = true  # Enabled for production
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
  default     = "provisioned"  # Changed to provisioned for production
}

variable "efs_provisioned_throughput" {
  description = "Provisioned throughput in MiB/s (required if throughput_mode is provisioned)"
  type        = number
  default     = 100  # Set provisioned throughput for production
}

variable "create_recordings_bucket" {
  description = "Whether to create S3 bucket for recordings"
  type        = bool
  default     = true
}

variable "recordings_expiration_days" {
  description = "Number of days after which recordings expire"
  type        = number
  default     = 90  # Longer retention for production
}

# MongoDB Configuration Variables
variable "mongodb_replica_count" {
  description = "Number of MongoDB replica set members (should be odd number: 1, 3, 5, etc.)"
  type        = number
  default     = 5  # Increased for production
}

variable "mongodb_instance_type" {
  description = "EC2 instance type for MongoDB nodes"
  type        = string
  default     = "m5.xlarge"  # Larger instance for production
}

variable "mongodb_ami_id" {
  description = "AMI ID for MongoDB instances. If empty, will use latest Ubuntu 22.04"
  type        = string
  default     = ""
}

variable "mongodb_version" {
  description = "MongoDB version to install"
  type        = string
  default     = "8.0"
}

variable "mongodb_admin_username" {
  description = "MongoDB admin username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "mongodb_default_database" {
  description = "Default database name"
  type        = string
  default     = "ten_xr_app_prod"
}

variable "mongodb_root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 50  # Increased for production
}

variable "mongodb_data_volume_size" {
  description = "Size of the data EBS volume in GB"
  type        = number
  default     = 500  # Increased for production
}

variable "mongodb_data_volume_type" {
  description = "Type of the data EBS volume (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "mongodb_data_volume_iops" {
  description = "IOPS for the data volume (only for gp3, io1, io2)"
  type        = number
  default     = 6000  # Increased for production
}

variable "mongodb_data_volume_throughput" {
  description = "Throughput in MiB/s for the data volume (only for gp3)"
  type        = number
  default     = 250  # Increased for production
}

variable "mongodb_allow_ssh" {
  description = "Whether to allow SSH access to MongoDB instances"
  type        = bool
  default     = false  # Disabled for production
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
  default     = 30  # Longer retention for production
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
  default     = 30  # Longer retention for production
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
  default     = true
}

# Redis Configuration Variables
variable "redis_node_type" {
  description = "Node type for Redis instances"
  type        = string
  default     = "cache.r6g.large"  # Larger instance for production
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_num_cache_clusters" {
  description = "Number of cache clusters (nodes) for replication group"
  type        = number
  default     = 3  # Increased for production
}

variable "redis_multi_az_enabled" {
  description = "Enable Multi-AZ for Redis"
  type        = bool
  default     = true
}

variable "redis_automatic_failover_enabled" {
  description = "Enable automatic failover for Redis"
  type        = bool
  default     = true
}

variable "redis_snapshot_retention_limit" {
  description = "Number of days to retain Redis snapshots"
  type        = number
  default     = 30  # Longer retention for production
}

variable "redis_snapshot_window" {
  description = "Daily time range for Redis snapshots (UTC)"
  type        = string
  default     = "03:00-05:00"
}

variable "redis_maintenance_window" {
  description = "Weekly time range for Redis maintenance (UTC)"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "redis_auth_token_enabled" {
  description = "Whether to enable Redis AUTH token (password)"
  type        = bool
  default     = true
}

variable "redis_transit_encryption_enabled" {
  description = "Enable encryption in transit for Redis"
  type        = bool
  default     = true
}

variable "redis_at_rest_encryption_enabled" {
  description = "Enable encryption at rest for Redis"
  type        = bool
  default     = true
}

variable "redis_parameters" {
  description = "Redis parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    },
    {
      name  = "timeout"
      value = "300"
    }
  ]
}

variable "redis_store_connection_details_in_ssm" {
  description = "Whether to store Redis connection details in SSM Parameter Store"
  type        = bool
  default     = true
}

variable "redis_create_cloudwatch_log_group" {
  description = "Whether to create CloudWatch log group for Redis"
  type        = bool
  default     = true
}

variable "redis_cloudwatch_log_retention_days" {
  description = "Number of days to retain Redis CloudWatch logs"
  type        = number
  default     = 30  # Longer retention for production
}

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
    enable_default_routing = optional(bool, false),
    alb_host_headers = optional(list(string))

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

################################################################################
# Networking Module Variables
################################################################################

variable "create_nlb" {
  description = "Whether to create Network Load Balancer"
  type        = bool
  default     = true
}

variable "nlb_internal" {
  description = "Whether the NLB should be internal (private) or external (public)"
  type        = bool
  default     = false
}

variable "nlb_enable_deletion_protection" {
  description = "Whether to enable deletion protection for the NLB"
  type        = bool
  default     = true  # Enabled for production
}

variable "nlb_enable_cross_zone_load_balancing" {
  description = "Whether to enable cross-zone load balancing for the NLB"
  type        = bool
  default     = true
}

# Target Group Configuration
variable "create_http_target_group" {
  description = "Whether to create HTTP target group"
  type        = bool
  default     = true
}

variable "http_port" {
  description = "HTTP port for target group"
  type        = number
  default     = 80
}

variable "https_port" {
  description = "HTTPS port for target group"
  type        = number
  default     = 443
}

variable "target_type" {
  description = "Type of target for target groups (ip, instance, alb)"
  type        = string
  default     = "alb"
}

variable "deregistration_delay" {
  description = "Time to wait for in-flight requests to complete while deregistering a target"
  type        = number
  default     = 300
}

# Health Check Configuration
variable "health_check_enabled" {
  description = "Whether to enable health checks"
  type        = bool
  default     = true
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks"
  type        = number
  default     = 2
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_port" {
  description = "Port for health checks"
  type        = string
  default     = "traffic-port"
}

variable "health_check_protocol" {
  description = "Protocol for health checks"
  type        = string
  default     = "HTTP"
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 6
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks"
  type        = number
  default     = 2
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/"
}

variable "health_check_matcher" {
  description = "HTTP response codes for successful health checks"
  type        = string
  default     = "200"
}

# Listener Configuration
variable "create_http_listener" {
  description = "Whether to create HTTP listener"
  type        = bool
  default     = true
}

variable "https_listener_protocol" {
  description = "Protocol for HTTPS listener (TCP or TLS)"
  type        = string
  default     = "TCP"
  validation {
    condition     = contains(["TCP", "TLS"], var.https_listener_protocol)
    error_message = "HTTPS listener protocol must be either TCP or TLS."
  }
}

# NLB Access Logs
variable "nlb_access_logs_enabled" {
  description = "Whether to enable NLB access logs"
  type        = bool
  default     = true  # Enabled for production
}

# NLB Connection Logs
variable "nlb_connection_logs_enabled" {
  description = "Whether to enable NLB connection logs"
  type        = bool
  default     = true  # Enabled for production
}

# Security Groups (optional for NLB)
variable "create_security_groups" {
  description = "Whether to create security groups for NLB"
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the NLB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_ports" {
  description = "List of additional ports to allow in security groups"
  type        = list(number)
  default     = []
}

# Route 53 Configuration (optional)
variable "create_route53_record" {
  description = "Whether to create Route 53 record for NLB"
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
  default     = ""
}

variable "route53_record_name" {
  description = "Route 53 record name"
  type        = string
  default     = ""
}

variable "route53_evaluate_target_health" {
  description = "Whether to evaluate target health for Route 53 alias"
  type        = bool
  default     = true
}

# CloudWatch Monitoring (optional)
variable "create_cloudwatch_alarms" {
  description = "Whether to create CloudWatch alarms for NLB"
  type        = bool
  default     = true  # Enabled for production
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

variable "healthy_host_count_threshold" {
  description = "Threshold for healthy host count alarm"
  type        = number
  default     = 1
}

variable "unhealthy_host_count_threshold" {
  description = "Threshold for unhealthy host count alarm"
  type        = number
  default     = 0
}

################################################################################
# Global Accelerator Configuration Variables
################################################################################

variable "create_global_accelerator" {
  description = "Whether to create Global Accelerator"
  type        = bool
  default     = true
}

variable "global_accelerator_enabled" {
  description = "Whether the Global Accelerator is enabled"
  type        = bool
  default     = true
}

variable "global_accelerator_ip_address_type" {
  description = "IP address type for Global Accelerator (IPV4 or DUALSTACK)"
  type        = string
  default     = "IPV4"
}

variable "global_accelerator_flow_logs_enabled" {
  description = "Whether to enable flow logs for Global Accelerator"
  type        = bool
  default     = true
}

variable "global_accelerator_flow_logs_s3_prefix" {
  description = "S3 prefix for Global Accelerator flow logs"
  type        = string
  default     = "global-accelerator-flow-logs"
}

variable "global_accelerator_client_affinity" {
  description = "Client affinity for Global Accelerator listener (NONE or SOURCE_IP)"
  type        = string
  default     = "NONE"
}

variable "global_accelerator_protocol" {
  description = "Protocol for Global Accelerator listener (TCP or UDP)"
  type        = string
  default     = "TCP"
}

variable "global_accelerator_health_check_grace_period" {
  description = "Grace period before health check failures cause endpoints to be removed"
  type        = number
  default     = 30
}

variable "global_accelerator_health_check_interval" {
  description = "Interval between health checks"
  type        = number
  default     = 30
}

variable "global_accelerator_health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/"
}

variable "global_accelerator_health_check_port" {
  description = "Port for health checks"
  type        = number
  default     = 80
}

variable "global_accelerator_health_check_protocol" {
  description = "Protocol for health checks (TCP, HTTP, or HTTPS)"
  type        = string
  default     = "HTTP"
}

variable "global_accelerator_threshold_count" {
  description = "Number of consecutive health checks before changing endpoint health status"
  type        = number
  default     = 3
}

variable "global_accelerator_traffic_dial_percentage" {
  description = "Percentage of traffic to dial to the endpoint group"
  type        = number
  default     = 100
}

################################################################################
# Cloudflare Configuration Variables
################################################################################

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain"
  type        = string
}

variable "base_domain_name" {
  description = "Base domain name"
  type        = string
  default     = "10xr.co"
}

variable "create_cloudflare_dns_records" {
  description = "Whether to create Cloudflare DNS records"
  type        = bool
  default     = true
}

variable "dns_proxied" {
  description = "Whether DNS records should be proxied through Cloudflare"
  type        = bool
  default     = true  # Enabled for production
}

variable "dns_ttl" {
  description = "TTL for DNS records (ignored if proxied is true)"
  type        = number
  default     = 300
}

################################################################################
# Custom DNS Records
################################################################################

variable "app_dns_records" {
  description = "Map of custom DNS records to create"
  type = map(object({
    name     = string
    content  = string
    type     = string
    proxied  = optional(bool)
    ttl      = optional(number)
    priority = optional(number)
    comment  = optional(string)
    tags     = optional(list(string), [])
  }))
  default = {}
}

################################################################################
# Zone Settings
################################################################################

variable "manage_cloudflare_zone_settings" {
  description = "Whether to manage Cloudflare zone settings"
  type        = bool
  default     = true  # Enabled for production
}

variable "cloudflare_ssl_mode" {
  description = "SSL mode for Cloudflare (off, flexible, full, strict)"
  type        = string
  default     = "strict"  # Strict for production
}

variable "cloudflare_always_use_https" {
  description = "Whether to always use HTTPS"
  type        = string
  default     = "on"  # Enabled for production
}

variable "cloudflare_min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"
}

variable "cloudflare_security_level" {
  description = "Cloudflare security level (off, essentially_off, low, medium, high, under_attack)"
  type        = string
  default     = "high"  # Higher security for production
}

variable "cloudflare_api_key" {
  description = "Cloudflare API key (legacy - use api_token instead)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  default     = ""
}

variable "documentdb_default_database" {
  description = "Default DocumentDB database name"
  type        = string
  default     = "ten_xr_agents_prod"
}



# Add only these essential variables to your variables.tf

variable "tfe_organization_name" {
  description = "Terraform Cloud organization name"
  type        = string
}

variable "tfe_main_workspace_name" {
  description = "Name of the main workspace"
  type        = string
  default     = "prod-us-east-1-ten-xr-app"
}

variable "github_oauth_token_id" {
  description = "GitHub OAuth token ID"
  type        = string
  default     = ""  
}

variable "documentdb_github_repo" {
  description = "GitHub repository for DocumentDB"
  type        = string
}

variable "documentdb_github_branch" {
  description = "GitHub branch"
  type        = string
  default     = "main"
}

variable "documentdb_workspace_auto_apply" {
  description = "Auto-apply DocumentDB workspace"
  type        = bool
  default     = true
}

variable "documentdb_instance_count" {
  description = "Number of DocumentDB instances"
  type        = number
  default     = 3
}

variable "documentdb_instance_class" {
  description = "DocumentDB instance class"
  type        = string
  default     = "db.r6g.large"
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {
    Environment = "prod"
    Project     = "10xR-Agents"
    Platform    = "AWS"
    Terraform   = "true"
  }
}