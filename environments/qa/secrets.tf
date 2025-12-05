# environments/qa/secrets.tf
# Secrets Manager secrets for sensitive configuration values
# These secrets should be manually populated in AWS Console or via CLI before deployment

################################################################################
# Local Variables for Secret Names
################################################################################

locals {
  secret_prefix = "${var.cluster_name}-${var.environment}"
}

################################################################################
# Home Health Service Secrets
################################################################################

resource "aws_secretsmanager_secret" "home_health" {
  name                    = "${local.secret_prefix}/home-health/secrets"
  description             = "Secrets for Home Health service"
  recovery_window_in_days = 30

  tags = merge(var.tags, {
    Service = "home-health"
    HIPAA   = "true"
  })
}

resource "aws_secretsmanager_secret_version" "home_health" {
  secret_id = aws_secretsmanager_secret.home_health.id
  secret_string = jsonencode({
    NEXTAUTH_SECRET          = var.home_health_nextauth_secret
    ONTUNE_SECRET            = var.home_health_ontune_secret
    ADMIN_API_KEY            = var.home_health_admin_api_key
    NEXT_PUBLIC_ADMIN_API_KEY = var.home_health_admin_api_key
    GEMINI_API_KEY           = var.home_health_gemini_api_key
    OPENAI_API_KEY           = var.home_health_openai_api_key
  })

  lifecycle {
    ignore_changes = [secret_string]  # Allow manual updates without Terraform override
  }
}

################################################################################
# Hospice Service Secrets
################################################################################

resource "aws_secretsmanager_secret" "hospice" {
  name                    = "${local.secret_prefix}/hospice/secrets"
  description             = "Secrets for Hospice service"
  recovery_window_in_days = 30

  tags = merge(var.tags, {
    Service = "hospice"
    HIPAA   = "true"
  })
}

resource "aws_secretsmanager_secret_version" "hospice" {
  secret_id = aws_secretsmanager_secret.hospice.id
  secret_string = jsonencode({
    NEXTAUTH_SECRET          = var.hospice_nextauth_secret
    ONTUNE_SECRET            = var.hospice_ontune_secret
    ADMIN_API_KEY            = var.hospice_admin_api_key
    NEXT_PUBLIC_ADMIN_API_KEY = var.hospice_admin_api_key
    GEMINI_API_KEY           = var.hospice_gemini_api_key
  })

  lifecycle {
    ignore_changes = [secret_string]  # Allow manual updates without Terraform override
  }
}

################################################################################
# SSM Parameters for Non-Sensitive Configuration
################################################################################

# Home Health SSM Parameters
resource "aws_ssm_parameter" "home_health_base_url" {
  name        = "/${local.secret_prefix}/home-health/NEXT_PUBLIC_BASE_URL"
  description = "Base URL for Home Health service"
  type        = "String"
  value       = "https://homehealth.${var.domain}"

  tags = merge(var.tags, {
    Service = "home-health"
  })
}

resource "aws_ssm_parameter" "home_health_nextauth_url" {
  name        = "/${local.secret_prefix}/home-health/NEXTAUTH_URL"
  description = "NextAuth URL for Home Health service"
  type        = "String"
  value       = "https://homehealth.${var.domain}"

  tags = merge(var.tags, {
    Service = "home-health"
  })
}

resource "aws_ssm_parameter" "home_health_node_env" {
  name        = "/${local.secret_prefix}/home-health/NODE_ENV"
  description = "Node environment for Home Health service"
  type        = "String"
  value       = "production"

  tags = merge(var.tags, {
    Service = "home-health"
  })
}

# Hospice SSM Parameters
resource "aws_ssm_parameter" "hospice_base_url" {
  name        = "/${local.secret_prefix}/hospice/NEXT_PUBLIC_BASE_URL"
  description = "Base URL for Hospice service"
  type        = "String"
  value       = "https://hospice.${var.domain}"

  tags = merge(var.tags, {
    Service = "hospice"
  })
}

resource "aws_ssm_parameter" "hospice_nextauth_url" {
  name        = "/${local.secret_prefix}/hospice/NEXTAUTH_URL"
  description = "NextAuth URL for Hospice service"
  type        = "String"
  value       = "https://hospice.${var.domain}"

  tags = merge(var.tags, {
    Service = "hospice"
  })
}

resource "aws_ssm_parameter" "hospice_node_env" {
  name        = "/${local.secret_prefix}/hospice/NODE_ENV"
  description = "Node environment for Hospice service"
  type        = "String"
  value       = "production"

  tags = merge(var.tags, {
    Service = "hospice"
  })
}

################################################################################
# Outputs for Use in ECS Services
################################################################################

output "home_health_secrets_arn" {
  description = "ARN of Home Health secrets in Secrets Manager"
  value       = aws_secretsmanager_secret.home_health.arn
}

output "hospice_secrets_arn" {
  description = "ARN of Hospice secrets in Secrets Manager"
  value       = aws_secretsmanager_secret.hospice.arn
}

output "home_health_ssm_parameters" {
  description = "SSM parameter ARNs for Home Health service"
  value = {
    base_url     = aws_ssm_parameter.home_health_base_url.arn
    nextauth_url = aws_ssm_parameter.home_health_nextauth_url.arn
    node_env     = aws_ssm_parameter.home_health_node_env.arn
  }
}

output "hospice_ssm_parameters" {
  description = "SSM parameter ARNs for Hospice service"
  value = {
    base_url     = aws_ssm_parameter.hospice_base_url.arn
    nextauth_url = aws_ssm_parameter.hospice_nextauth_url.arn
    node_env     = aws_ssm_parameter.hospice_node_env.arn
  }
}
