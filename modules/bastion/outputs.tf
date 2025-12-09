# modules/bastion/outputs.tf

################################################################################
# Instance Outputs
################################################################################

output "instance_id" {
  description = "ID of the bastion EC2 instance"
  value       = aws_instance.bastion.id
}

output "instance_arn" {
  description = "ARN of the bastion EC2 instance"
  value       = aws_instance.bastion.arn
}

output "private_ip" {
  description = "Private IP address of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "instance_state" {
  description = "Current state of the bastion instance"
  value       = aws_instance.bastion.instance_state
}

################################################################################
# Security Group Outputs
################################################################################

output "security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "security_group_arn" {
  description = "ARN of the bastion security group"
  value       = aws_security_group.bastion.arn
}

################################################################################
# IAM Outputs
################################################################################

output "iam_role_arn" {
  description = "ARN of the bastion IAM role"
  value       = aws_iam_role.bastion.arn
}

output "iam_role_name" {
  description = "Name of the bastion IAM role"
  value       = aws_iam_role.bastion.name
}

output "instance_profile_arn" {
  description = "ARN of the bastion instance profile"
  value       = aws_iam_instance_profile.bastion.arn
}

################################################################################
# Connection Information
################################################################################

output "ssm_start_session_command" {
  description = "AWS CLI command to start an SSM session to the bastion host"
  value       = "aws ssm start-session --target ${aws_instance.bastion.id} --region ${data.aws_region.current.name}"
}

output "ssm_port_forward_documentdb_command" {
  description = "AWS CLI command to port forward DocumentDB through the bastion"
  value       = <<-EOT
    aws ssm start-session \
      --target ${aws_instance.bastion.id} \
      --document-name AWS-StartPortForwardingSessionToRemoteHost \
      --parameters '{"host":["<DOCUMENTDB_ENDPOINT>"],"portNumber":["27017"],"localPortNumber":["27017"]}' \
      --region ${data.aws_region.current.name}
  EOT
}

output "ssm_port_forward_redis_command" {
  description = "AWS CLI command to port forward Redis through the bastion"
  value       = <<-EOT
    aws ssm start-session \
      --target ${aws_instance.bastion.id} \
      --document-name AWS-StartPortForwardingSessionToRemoteHost \
      --parameters '{"host":["<REDIS_ENDPOINT>"],"portNumber":["6379"],"localPortNumber":["6379"]}' \
      --region ${data.aws_region.current.name}
  EOT
}

################################################################################
# Data Sources
################################################################################

data "aws_region" "current" {}
