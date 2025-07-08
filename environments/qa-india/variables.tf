# environments/qa-india/variables.tf

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"  # Mumbai region
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "qa-india"
}

variable "cluster_name" {
  description = "Name prefix for resources"
  type        = string
  default     = "ten-xr-agents"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for the subnets"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0caf778a172362f1c"  # Ubuntu 22.04 LTS in ap-south-1 (verify this is current)

  validation {
    condition = can(regex("^ami-[0-9a-f]{8,17}$", var.ec2_ami_id))
    error_message = "The AMI ID must be a valid AMI identifier."
  }
}

variable "ec2_instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
  default     = "t3.medium"

  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge",
      "t2.micro", "t2.small", "t2.medium", "t2.large",
      "m5.large", "m5.xlarge", "m5.2xlarge"
    ], var.ec2_instance_type)
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

variable "ec2_root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 30

  validation {
    condition = var.ec2_root_volume_size >= 20 && var.ec2_root_volume_size <= 500
    error_message = "Root volume size must be between 20 and 500 GB."
  }
}

variable "ssh_public_key" {
  description = "Public SSH key content for EC2 access"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41"
  sensitive   = false
}

variable "ssh_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to the EC2 instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Consider restricting this to your office IP for security
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain"
  type        = string
  default     = "3ae048b26df2c81c175c609f802feafb"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:Edit permissions"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  default     = "929c1d893cb7bb8455e151ae08f3b538"
}

variable "cloudflare_api_key" {
  description = "Cloudflare API key (legacy - use api_token instead)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "subdomain" {
  description = "Subdomain for the LiveKit proxy (without the main domain)"
  type        = string
  default     = "proxy-india.qa"
}

variable "domain_name" {
  description = "Full domain name for the LiveKit proxy"
  type        = string
  default     = "proxy-india.qa.10xr.co"
}

variable "enable_cloudflare_proxy" {
  description = "Whether to enable Cloudflare proxy (orange cloud)"
  type        = bool
  default     = false  # Disabled for initial testing
}

variable "dns_ttl" {
  description = "TTL for DNS records in seconds"
  type        = number
  default     = 300

  validation {
    condition = var.dns_ttl >= 120 && var.dns_ttl <= 86400
    error_message = "DNS TTL must be between 120 and 86400 seconds."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {
    Environment = "qa-india"
    Project     = "10xR-Agents"
    Component   = "LiveKit-Proxy"
    Platform    = "AWS"
    Terraform   = "true"
    ManagedBy   = "Terraform"
  }
}