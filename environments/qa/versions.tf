# environments/qa/versions.tf

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.99.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.1.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.15"
    }
  }
}