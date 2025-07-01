# environments/qa/versions.tf

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.99.0"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.1.0"
    }
    # # Cloudflare provider - COMMENTED OUT
    # cloudflare = {
    #   source  = "cloudflare/cloudflare"
    #   version = "~> 4.40.0"
    # }
  }
}