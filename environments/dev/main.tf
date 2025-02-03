# environment/dev/main.tf

locals {
  name = "${var.project_name}-${var.environment}"

  tags = {
    Environment     = var.environment
    Project         = var.project_name
    ManagedBy       = "10xR"
    EnvironmentType = var.environment == "prod" ? "Production" : ( var.environment == "prod" ? "QA" : "Development")
    Terraform      = "true"
  }
}

module "aws" {
  source = "../../modules/aws"

  # Core configuration
  aws_region   = var.aws_region
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr

  # Tags configuration
  tags = merge(local.tags, var.tags, var.vpc_tags)
  public_subnet_tags = merge(
    local.tags,
    var.public_subnet_tags,
    {
      Tier = "public"
      "kubernetes.io/role/elb" = "1"
    }
  )
  private_subnet_tags = merge(
    local.tags,
    var.private_subnet_tags,
    {
      Tier = "private"
      "kubernetes.io/role/internal-elb" = "1"
    }
  )
}