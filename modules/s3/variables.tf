# modules/s3/variables.tf

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_logging" {
  description = "Enable logging for the S3 bucket"
  type        = bool
  default     = false
}

variable "log_bucket" {
  description = "The S3 bucket to store logs in"
  type        = string
  default     = ""
}