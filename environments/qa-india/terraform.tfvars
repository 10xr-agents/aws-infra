# environments/qa-india/terraform.tfvars

# AWS Region
region = "ap-south-1"
environment = "qa-india"

# Cluster Configuration
cluster_name = "ten-xr-agents"

# VPC Configuration
vpc_cidr = "10.1.0.0/16"
public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
availability_zones = ["ap-south-1a", "ap-south-1b"]

# EC2 Configuration
ec2_instance_type = "t3.medium"
ec2_root_volume_size = 30

# SSH Configuration
ssh_allowed_cidr_blocks = ["0.0.0.0/0"]  # Replace with your office IP for better security
# Use ssh_public_key to specify your actual public key 
# ssh_public_key = "ssh-rsa AAAA..."

# Domain Configuration
subdomain = "proxy-india.qa"
domain_name = "proxy-india.qa.10xr.co"

# Cloudflare Configuration
cloudflare_api_token  = "jTm01UhNhNDE-Md4jrQwBS0w3vHsqVikxC9cop9r"
cloudflare_zone_id    = "3ae048b26df2c81c175c609f802feafb"
cloudflare_account_id = "929c1d893cb7bb8455e151ae08f3b538"
cloudflare_api_key    = "ef7027a662a457c814bfc30e81fcf49baa969"

# Tags
tags = {
  Environment = "qa-india"
  Project     = "10xR-Agents"
  Component   = "LiveKit-Proxy"
  Platform    = "AWS"
  Terraform   = "true"
}