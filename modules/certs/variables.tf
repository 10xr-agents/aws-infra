# modules/certs/variables.tf

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

variable "wait_for_validation" {
  description = "Whether to wait for certificate validation to complete"
  type        = bool
  default     = true
}

variable "validation_timeout" {
  description = "Timeout for certificate validation"
  type        = string
  default     = "45m"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
