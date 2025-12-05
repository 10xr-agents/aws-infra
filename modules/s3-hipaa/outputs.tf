# modules/s3-hipaa/outputs.tf

################################################################################
# S3 Bucket Outputs
################################################################################

output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket regional domain name"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_region" {
  description = "The AWS region the bucket resides in"
  value       = data.aws_region.current.name
}

################################################################################
# KMS Key Outputs
################################################################################

output "kms_key_id" {
  description = "The ID of the KMS key"
  value       = var.create_kms_key ? aws_kms_key.s3[0].key_id : null
}

output "kms_key_arn" {
  description = "The ARN of the KMS key"
  value       = var.create_kms_key ? aws_kms_key.s3[0].arn : var.kms_key_arn
}

output "kms_alias_arn" {
  description = "The ARN of the KMS alias"
  value       = var.create_kms_key ? aws_kms_alias.s3[0].arn : null
}

################################################################################
# IAM Policy Outputs
################################################################################

output "iam_policy_arn" {
  description = "The ARN of the IAM policy for S3 access"
  value       = aws_iam_policy.s3_access.arn
}

output "iam_policy_name" {
  description = "The name of the IAM policy for S3 access"
  value       = aws_iam_policy.s3_access.name
}

################################################################################
# Access Logs Bucket Outputs
################################################################################

output "access_logs_bucket_id" {
  description = "The name of the access logs bucket"
  value       = var.enable_access_logging ? aws_s3_bucket.access_logs[0].id : null
}

output "access_logs_bucket_arn" {
  description = "The ARN of the access logs bucket"
  value       = var.enable_access_logging ? aws_s3_bucket.access_logs[0].arn : null
}

################################################################################
# ECS Environment Variables
################################################################################

output "ecs_environment_variables" {
  description = "Environment variables for ECS task definitions"
  value = {
    S3_BUCKET_NAME   = aws_s3_bucket.this.id
    S3_BUCKET_ARN    = aws_s3_bucket.this.arn
    S3_BUCKET_REGION = data.aws_region.current.name
  }
}
