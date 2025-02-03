# environment/dev/providers.tf

terraform {
  cloud {
    organization = "10xR"
    workspaces {
      name = "dev-us-east-1-ten-xr-app"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.81.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.18.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment    = var.environment
      Project        = var.project_name
      ManagedBy      = "10xR"
      EnvironmentTag = var.environment == "prod" ? "Production" : ( var.environment == "prod" ? "QA" : "Development")
    }
  }
}