# terraform.tfvars

region               = "us-east-1"
project_name         = "10xr-infra-demo"
environment          = "demo"
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.2.0/24", "10.0.4.0/24"]
single_nat_gateway   = true

acm_certificate_arn = "arn:aws:acm:us-east-1:761018882607:certificate/20b79c9a-92b9-44da-ac7f-9f772c5d2756"
tags = {
  Environment = "demo"
  Project     = "10xR-Infra"
  ManagedBy   = "Terraform"
}

mongodb_connection_string = "mongodb+srv://converseDev:firstPassword1@10xr-demo.3njzs.mongodb.net/converse-server?retryWrites=true&w=majority&appName=10xR-demo"
eks_cluster_version       = "1.24"
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

eks_public_access_cidrs = ["0.0.0.0/0"] # Replace with your IP or desired CIDR range
