# MongoDB VPC Peering Configuration (Requester Side)

# Data source to retrieve MongoDB VPC information from SSM Parameter Store
data "aws_ssm_parameter" "mongodb_vpc_info" {
  name = "/${var.environment}/mongodb/vpc-info"
}

# Data source to retrieve MongoDB connection information from SSM Parameter Store
data "aws_ssm_parameter" "mongodb_connection_info" {
  name = "/${var.environment}/mongodb/connection-info"
}

locals {
  # Parse MongoDB VPC information from SSM Parameter Store
  mongodb_vpc_info = jsondecode(data.aws_ssm_parameter.mongodb_vpc_info.value)
}

# Create a VPC peering connection request to MongoDB VPC
resource "aws_vpc_peering_connection" "mongodb_peering" {
  vpc_id        = module.vpc.vpc_id  # Your application VPC ID
  peer_vpc_id   = local.mongodb_vpc_info.vpc_id
  peer_region   = local.mongodb_vpc_info.region
  auto_accept   = false  # Cannot auto-accept cross-account peering

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.environment}-to-mongodb-peering"
    Side = "Requester"
    Environment = var.environment
  })
}

# Create routes in application VPC for the MongoDB VPC CIDR
resource "aws_route" "app_to_mongodb_private" {
  count = length(module.vpc.private_route_table_ids)

  route_table_id            = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block    = local.mongodb_vpc_info.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.mongodb_peering.id
}

# Create routes in application VPC public subnets for the MongoDB VPC CIDR
resource "aws_route" "app_to_mongodb_public" {
  count = length(module.vpc.public_route_table_ids)

  route_table_id            = module.vpc.public_route_table_ids[count.index]
  destination_cidr_block    = local.mongodb_vpc_info.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.mongodb_peering.id
}

# Modify security group rules to allow traffic to MongoDB
resource "aws_security_group_rule" "ecs_to_mongodb" {
  for_each = module.ecs.security_group_ids

  type              = "egress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  cidr_blocks       = [local.mongodb_vpc_info.vpc_cidr]
  security_group_id = each.value
  description       = "Allow outbound traffic to MongoDB"
}

# Note: This resource has been removed to avoid circular dependency
# Instead, we'll directly use the SSM parameter from the MongoDB infrastructure