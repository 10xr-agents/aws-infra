
###############################################################################
# VPC Module
# This module creates a production-grade VPC infrastructure with the following:
# - A VPC with DNS support and custom CIDR block
# - Public subnets across multiple AZs for internet-facing resources
# - Private subnets across multiple AZs for internal resources
# - Proper tagging for cost allocation and resource management
###############################################################################

locals {
  region = var.aws_region  # Change this to your desired region
  name = "${var.project_name}-${var.environment}"

  # Break VPC CIDR into three /18 blocks
  cidr_blocks = cidrsubnets(var.vpc_cidr, 2, 2, 2)

  # Derive subnets for each block
  public_subnets = [for cidr in cidrsubnets(local.cidr_blocks[0], 4, 4, 4) : cidr]  # /22 subnets from first /18
  private_subnets = [for cidr in cidrsubnets(local.cidr_blocks[1], 4, 4, 4) : cidr]  # /22 subnets from second /18
  elasticache_subnets = [for cidr in cidrsubnets(local.cidr_blocks[2], 4, 4, 4) : cidr] # /22 subnets from fourth /18

  # Map subnets to availability zones
  azs = slice(data.aws_availability_zones.available.names, 0, length(local.cidr_blocks))

  tags = merge(var.tags, {
    Environment = var.environment
    Terraform   = "true"
    Project     = var.project_name
  })
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}