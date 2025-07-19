# modules/mongodb/variables.tf

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

#------------------------------------------------------------------------------
# VPC Peering Configuration Variables
#------------------------------------------------------------------------------

variable "vpc_name" {
  description = "Name of the AWS VPC to peer with MongoDB Atlas"
  type        = string
  default     = ""
}

variable "atlas_cidr_block" {
  description = "CIDR block for MongoDB Atlas network container"
  type        = string
  default     = "192.168.248.0/21"
  validation {
    condition = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.atlas_cidr_block))
    error_message = "Atlas CIDR block must be a valid CIDR notation."
  }
}

variable "mongodb_atlas_project_id" {
  description = "MongoDB Atlas project ID"
  type        = string
}

variable "mongodb_atlas_container_id" {
  description = "Existing MongoDB Atlas container ID (required if use_existing_container is true)"
  type        = string
  default     = ""
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks to whitelist in MongoDB Atlas"
  type        = list(string)
  default     = []
}

variable "whitelist_private_subnets" {
  description = "Whether to individually whitelist private subnet CIDRs in MongoDB Atlas"
  type        = bool
  default     = false
}

variable "create_security_group" {
  description = "Create security group for MongoDB Atlas access"
  type        = bool
  default     = true
}
