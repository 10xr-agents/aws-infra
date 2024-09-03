variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "The CIDR blocks for the public subnets"
  type        = list(string)
}

variable "services" {
  description = "List of services to deploy"
  type = list(object({
    name          = string
    ecr_repo      = string
    cpu           = number
    memory        = number
    desired_count = number
    compute_type  = string  # New field: "on_demand" or "spot"
  }))
}

variable "instance_type_on_demand" {
  description = "EC2 instance type for on-demand instances in ECS cluster"
  type        = string
}

variable "instance_type_spot" {
  description = "EC2 instance type for spot instances in ECS cluster"
  type        = string
}

variable "asg_on_demand_min_size" {
  description = "Minimum number of on-demand EC2 instances in the ASG"
  type        = number
}

variable "asg_on_demand_max_size" {
  description = "Maximum number of on-demand EC2 instances in the ASG"
  type        = number
}

variable "asg_on_demand_desired_capacity" {
  description = "Desired number of on-demand EC2 instances in the ASG"
  type        = number
}

variable "asg_spot_min_size" {
  description = "Minimum number of spot EC2 instances in the ASG"
  type        = number
}

variable "asg_spot_max_size" {
  description = "Maximum number of spot EC2 instances in the ASG"
  type        = number
}

variable "asg_spot_desired_capacity" {
  description = "Desired number of spot EC2 instances in the ASG"
  type        = number
}