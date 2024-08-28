# terraform.tfvars

region         = "us-east-1"
project_name   = "10xr-infra-demo"
environment    = "demo"
vpc_cidr       = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
single_nat_gateway   = true

acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

tags = {
  Environment = "demo"
  Project     = "10xR-Infra"
  ManagedBy   = "Terraform"
}

mongodb_connection_string = "mongodb+srv://username:password@your-cluster.mongodb.net/your-database"

eks_cluster_version = "1.24"
eks_node_groups = {
  general = {
    desired_size   = 2
    max_size       = 3
    min_size       = 1
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    labels = {
      "node-group" = "general"
    }
  },
  spot = {
    desired_size   = 1
    max_size       = 2
    min_size       = 0
    instance_types = ["t3.small", "t3.medium"]
    capacity_type  = "SPOT"
    labels = {
      "node-group" = "spot"
    }
  }
}

eks_public_access_cidrs = ["YOUR_IP_ADDRESS/32"]  # Replace with your IP or desired CIDR range
