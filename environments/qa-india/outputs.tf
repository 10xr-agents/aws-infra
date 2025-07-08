# environments/qa-india/outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "availability_zones" {
  description = "Availability zones used"
  value       = var.availability_zones
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.livekit_proxy.id
}

output "ec2_instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.livekit_proxy.private_ip
}

output "ec2_instance_public_ip" {
  description = "Public IP address of the EC2 instance (before EIP association)"
  value       = aws_instance.livekit_proxy.public_ip
}

output "elastic_ip" {
  description = "Elastic IP address attached to the EC2 instance"
  value       = aws_eip.livekit_proxy.public_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ec2.id
}

output "ssh_key_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.ec2.key_name
}

output "proxy_url" {
  description = "URL for the LiveKit proxy service"
  value       = "https://${var.domain_name}"
}

output "cloudflare_record_id" {
  description = "ID of the Cloudflare DNS record"
  value       = cloudflare_record.livekit_proxy_cname.id
}

output "cloudflare_record_name" {
  description = "Name of the Cloudflare DNS record"
  value       = cloudflare_record.livekit_proxy_cname.name
}

# Network Architecture Summary
output "network_architecture" {
  description = "Summary of the network architecture"
  value = {
    vpc_id             = aws_vpc.main.id
    vpc_cidr           = aws_vpc.main.cidr_block
    public_subnet_ids  = aws_subnet.public[*].id
    availability_zones = var.availability_zones
    internet_gateway_id = aws_internet_gateway.main.id
    route_table_id     = aws_route_table.public.id
  }
}

# EC2 Instance Summary
output "ec2_instance_details" {
  description = "Summary of the EC2 instance details"
  value = {
    instance_id        = aws_instance.livekit_proxy.id
    instance_type      = aws_instance.livekit_proxy.instance_type
    ami_id             = aws_instance.livekit_proxy.ami
    availability_zone  = aws_instance.livekit_proxy.availability_zone
    private_ip         = aws_instance.livekit_proxy.private_ip
    public_ip          = aws_eip.livekit_proxy.public_ip
    security_group_id  = aws_security_group.ec2.id
    key_name           = aws_key_pair.ec2.key_name
  }
}

# Application URLs Summary
output "application_urls" {
  description = "Complete summary of application access URLs"
  value = {
    livekit_proxy_url  = "https://${var.domain_name}"
    livekit_proxy_ip   = aws_eip.livekit_proxy.public_ip
    livekit_proxy_port = 9000
  }
}