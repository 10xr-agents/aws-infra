# modules/s3/outputs.tf

output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.main.arn
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for bucket encryption"
  value       = aws_kms_key.s3.arn
}