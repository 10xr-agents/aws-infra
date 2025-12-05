variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "domain" {
  description = "Domain name for 10xR services"
  type        = string
  default     = "10xr.co"
}

variable "subject_alternative_domains" {
  description = "Subject alternative domain names"
  type        = list(string)
  default     = []
}