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
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 1.38.0"
    }
  }
}