# terraform.tfvars

region               = "us-east-1"
project_name         = "10xr-infra-demo"
environment          = "demo"
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.3.0/24", "10.0.5.0/24"]
private_subnet_cidrs = ["10.0.2.0/24", "10.0.4.0/24", "10.0.6.0/24"]
single_nat_gateway   = false

acm_certificate_arn = "arn:aws:acm:us-east-1:761018882607:certificate/6af0470e-edcb-4e68-8926-157102b36c53"
tags = {
  Environment = "demo"
  Project     = "10xR-Infra"
  ManagedBy   = "Terraform"
}

mongodb_connection_string = "mongodb+srv://converseDev:firstPassword1@10xr-demo.3njzs.mongodb.net/converse-server?retryWrites=true&w=majority&appName=10xR-demo"
eks_cluster_version       = "1.30"
eks_node_groups = {
  general = {
    name           = "general-node-group"
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 20
    scaling_config = {
      desired_size = 3
      max_size     = 5
      min_size     = 1
    }
    labels = {
      "node-group" = "converse-general"
    }
    taints = []
  },
  spot = {
    name           = "spot-node-group"
    instance_types = ["t3.small", "t3.medium"]
    capacity_type  = "SPOT"
    disk_size      = 20
    scaling_config = {
      desired_size = 2
      max_size     = 3
      min_size     = 1
    }
    labels = {
      "node-group" = "converse-spot"
    }
    taints = []
  }
}

eks_public_access_cidrs = ["0.0.0.0/0"] # Replace with your IP or desired CIDR range