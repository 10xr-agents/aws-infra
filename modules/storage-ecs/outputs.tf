# modules/storage-ecs/outputs.tf (Updated for ECS + EKS)

# EFS Outputs
output "efs_id" {
  description = "The ID of the EFS file system"
  value       = aws_efs_file_system.main.id
}

output "efs_arn" {
  description = "The ARN of the EFS file system"
  value       = aws_efs_file_system.main.arn
}

output "efs_dns_name" {
  description = "The DNS name of the EFS file system"
  value       = aws_efs_file_system.main.dns_name
}

output "livekit_access_point_id" {
  description = "The ID of the LiveKit EFS access point"
  value       = aws_efs_access_point.livekit.id
}

output "livekit_access_point_arn" {
  description = "The ARN of the LiveKit EFS access point"
  value       = aws_efs_access_point.livekit.arn
}

# S3 Outputs
output "recordings_bucket_name" {
  description = "The name of the S3 bucket for recordings"
  value       = var.create_recordings_bucket ? aws_s3_bucket.recordings[0].id : null
}

output "recordings_bucket_arn" {
  description = "The ARN of the S3 bucket for recordings"
  value       = var.create_recordings_bucket ? aws_s3_bucket.recordings[0].arn : null
}

# IAM Outputs
output "task_role_arn" {
  description = "The ARN of the IAM role for ECS tasks"
  value       = aws_iam_role.ecs_task.arn
}

output "task_role_name" {
  description = "The name of the IAM role for ECS tasks"
  value       = aws_iam_role.ecs_task.name
}

output "s3_access_policy_arn" {
  description = "The ARN of the S3 access policy"
  value       = var.create_recordings_bucket ? aws_iam_policy.s3_access[0].arn : null
}

output "eks_s3_service_account_role_arn" {
  description = "The ARN of the IAM role for EKS S3 service account"
  value       = var.enable_eks && var.create_recordings_bucket ? module.eks_s3_irsa[0].iam_role_arn : null
}

# Storage Classes (EKS only)
output "efs_storage_class_name" {
  description = "Name of the EFS storage class"
  value       = var.enable_eks ? "efs" : null
}

output "gp3_storage_class_name" {
  description = "Name of the GP3 storage class"
  value       = var.enable_eks ? "gp3" : null
}

# Security Group
output "efs_security_group_id" {
  description = "ID of the EFS security group"
  value       = aws_security_group.efs.id
}