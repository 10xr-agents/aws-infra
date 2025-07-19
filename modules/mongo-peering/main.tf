
# Data source to get VPC information
data "aws_vpc" "main" {

  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "private" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main[0].id]
  }

  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

data "aws_route_tables" "private" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main[0].id]
  }

  filter {
    name   = "association.subnet-id"
    values = data.aws_subnets.private[0].ids
  }
}

data "aws_caller_identity" "current" {}

resource "mongodbatlas_network_peering" "main" {
  project_id               = var.mongodb_atlas_project_id
  container_id             = var.mongodb_atlas_container_id
  accepter_region_name     = var.region
  provider_name            = "AWS"
  route_table_cidr_block   = data.aws_vpc.main.cidr_block
  vpc_id                   = data.aws_vpc.main.id
  aws_account_id           = data.aws_caller_identity.current.account_id
}

# Accept the VPC Peering Connection on AWS side
resource "aws_vpc_peering_connection_accepter" "main" {
  vpc_peering_connection_id = mongodbatlas_network_peering.main.connection_id
  auto_accept               = true

  tags = {
    Name        = "${var.cluster_name}-${var.environment}-mongodb-peering"
    Environment = var.environment
    Project     = var.cluster_name
    Service     = "MongoDB"
    Managed_by  = "terraform"
  }

  depends_on = [mongodbatlas_network_peering.main]
}

# Add routes to AWS route tables to reach MongoDB Atlas
resource "aws_route" "mongodb_atlas" {
  count                     = length(data.aws_route_tables.private.ids)
  route_table_id            = tolist(data.aws_route_tables.private.ids)[count.index]
  destination_cidr_block    = var.atlas_cidr_block
  vpc_peering_connection_id = mongodbatlas_network_peering.main[0].connection_id

  depends_on = [aws_vpc_peering_connection_accepter.main]
}

# Create IP Access List entries for your VPC CIDR (whitelist your VPC)
resource "mongodbatlas_project_ip_access_list" "vpc_cidr" {
  project_id = var.mongodb_atlas_project_id
  cidr_block = data.aws_vpc.main.cidr_block
  comment    = "VPC CIDR for ${var.cluster_name} ${var.environment} - ${data.aws_vpc.main.cidr_block}"

  depends_on = [mongodbatlas_network_peering.main]
}

# Optional: Add specific subnet CIDRs to IP access list
resource "mongodbatlas_project_ip_access_list" "private_subnets" {
  count      = var.whitelist_private_subnets ? length(var.private_subnet_cidrs) : 0
  project_id = var.mongodb_atlas_project_id
  cidr_block = var.private_subnet_cidrs[count.index]
  comment    = "Private subnet ${count.index + 1} for ${var.cluster_name} ${var.environment}"

  depends_on = [mongodbatlas_network_peering.main]
}

# Create security group for MongoDB Atlas access (optional but recommended)
resource "aws_security_group" "mongodb_atlas_access" {
  name        = "${var.cluster_name}-${var.environment}-mongodb-atlas-access"
  description = "Security group for MongoDB Atlas access via VPC peering"
  vpc_id      = data.aws_vpc.main.id

  # Allow outbound traffic to MongoDB Atlas on port 27017
  egress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [var.atlas_cidr_block]
    description = "MongoDB Atlas access via VPC peering"
  }

  # Allow outbound traffic to MongoDB Atlas on port 27016 (for sharded clusters)
  egress {
    from_port   = 27016
    to_port     = 27016
    protocol    = "tcp"
    cidr_blocks = [var.atlas_cidr_block]
    description = "MongoDB Atlas sharded cluster access via VPC peering"
  }

  # Allow HTTPS for Atlas API calls
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for Atlas API calls"
  }

  tags = {
    Name        = "${var.cluster_name}-${var.environment}-mongodb-atlas-access"
    Environment = var.environment
    Project     = var.cluster_name
    Service     = "MongoDB"
    Managed_by  = "terraform"
  }
}