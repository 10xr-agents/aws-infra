# environments/prod/providers.tf

provider "aws" {
  region = var.region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Add TFE provider for managing Terraform Cloud workspaces
provider "tfe" {
}