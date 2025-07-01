# environments/qa/providers.tf

provider "aws" {
  region = var.region
}

# # Cloudflare provider - COMMENTED OUT
# provider "cloudflare" {
#   api_token = var.cloudflare_api_token
# }