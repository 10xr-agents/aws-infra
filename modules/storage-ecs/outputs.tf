# modules/storage-ecs/outputs.tf

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

output "recordings_bucket_name" {
  description = "The name of the S3 bucket for recordings"
  value       = var.create_recordings_bucket ? aws_s3_bucket.recordings[0].id : null
}

output "recordings_bucket_arn" {
  description = "The ARN of the S3 bucket for recordings"
  value       = var.create_recordings_bucket ? aws_s3_bucket.recordings[0].arn : null
}

output "task_role_arn" {
  description = "The ARN of the IAM role for ECS tasks"
  value       = aws_iam_role.ecs_task.arn
}

output "task_role_name" {
  description = "The name of the IAM role for ECS tasks"
  value       = aws_iam_role.ecs_task.name
}