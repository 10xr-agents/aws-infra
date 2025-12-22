# environments/qa/providers.tf

provider "aws" {
  region = var.region
}

# Cloudflare provider - supports both API token and API key authentication
# API token (preferred): Set cloudflare_api_token with Zone:DNS:Edit permission
# API key (legacy): Set cloudflare_api_key and cloudflare_email
provider "cloudflare" {
  api_token = var.cloudflare_api_token != "" ? var.cloudflare_api_token : null
  api_key   = var.cloudflare_api_key != "" ? var.cloudflare_api_key : null
  email     = var.cloudflare_email != "" ? var.cloudflare_email : null
}
