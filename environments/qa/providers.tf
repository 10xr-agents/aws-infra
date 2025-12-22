# environments/qa/providers.tf

provider "aws" {
  region = var.region
}

# Cloudflare provider - uses API key + email authentication
provider "cloudflare" {
  api_key = var.cloudflare_api_key
  email   = var.cloudflare_email
}
