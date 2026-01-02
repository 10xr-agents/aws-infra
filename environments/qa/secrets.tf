# environments/qa/secrets.tf
# Secrets Manager secrets for sensitive configuration values
# These secrets should be manually populated in AWS Console or via CLI before deployment

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
    NEXTAUTH_SECRET           = var.nextauth_secret
    ONTUNE_SECRET             = var.ontune_secret
    ADMIN_API_KEY             = var.admin_api_key
    NEXT_PUBLIC_ADMIN_API_KEY = var.admin_api_key
    GEMINI_API_KEY            = var.gemini_api_key
    OPENAI_API_KEY            = var.openai_api_key
  })

  lifecycle {
    ignore_changes = [secret_string] # Allow manual updates without Terraform override
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
    NEXTAUTH_SECRET           = var.nextauth_secret
    ONTUNE_SECRET             = var.ontune_secret
    ADMIN_API_KEY             = var.admin_api_key
    NEXT_PUBLIC_ADMIN_API_KEY = var.admin_api_key
    GEMINI_API_KEY            = var.gemini_api_key
  })

  lifecycle {
    ignore_changes = [secret_string] # Allow manual updates without Terraform override
  }
}

################################################################################
# Voice AI Service Secrets
################################################################################

resource "aws_secretsmanager_secret" "voice_ai" {
  name                    = "${local.secret_prefix}/voice-ai/secrets"
  description             = "Secrets for Voice AI service"
  recovery_window_in_days = 30

  tags = merge(var.tags, {
    Service = "voice-ai"
    HIPAA   = "false"
  })
}

resource "aws_secretsmanager_secret_version" "voice_ai" {
  secret_id = aws_secretsmanager_secret.voice_ai.id
  secret_string = jsonencode({
    NEXTAUTH_SECRET    = var.nextauth_secret
    OPENAI_API_KEY     = var.openai_api_key
    LIVEKIT_API_KEY    = var.livekit_api_key
    LIVEKIT_API_SECRET = var.livekit_api_secret
  })

  lifecycle {
    ignore_changes = [secret_string] # Allow manual updates without Terraform override
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

# Voice AI SSM Parameters
resource "aws_ssm_parameter" "voice_ai_base_url" {
  name        = "/${local.secret_prefix}/voice-ai/NEXT_PUBLIC_BASE_URL"
  description = "Base URL for Voice AI service"
  type        = "String"
  value       = "https://voice.${var.domain}"

  tags = merge(var.tags, {
    Service = "voice-ai"
  })
}

resource "aws_ssm_parameter" "voice_ai_nextauth_url" {
  name        = "/${local.secret_prefix}/voice-ai/NEXTAUTH_URL"
  description = "NextAuth URL for Voice AI service"
  type        = "String"
  value       = "https://voice.${var.domain}"

  tags = merge(var.tags, {
    Service = "voice-ai"
  })
}

resource "aws_ssm_parameter" "voice_ai_node_env" {
  name        = "/${local.secret_prefix}/voice-ai/NODE_ENV"
  description = "Node environment for Voice AI service"
  type        = "String"
  value       = "production"

  tags = merge(var.tags, {
    Service = "voice-ai"
  })
}

################################################################################
# Common LiveKit Secrets (Shared across all ECS services)
################################################################################

resource "aws_secretsmanager_secret" "livekit" {
  name                    = "${local.secret_prefix}/common/livekit"
  description             = "LiveKit credentials shared across all ECS services"
  recovery_window_in_days = 30

  tags = merge(var.tags, {
    Component = "livekit"
    Shared    = "true"
  })
}

resource "aws_secretsmanager_secret_version" "livekit" {
  secret_id = aws_secretsmanager_secret.livekit.id
  secret_string = jsonencode({
    LIVEKIT_API_KEY    = var.livekit_api_key
    LIVEKIT_API_SECRET = var.livekit_api_secret
  })

  lifecycle {
    ignore_changes = [secret_string] # Allow manual updates without Terraform override
  }
}

################################################################################
# Common SSM Parameters (Shared across all ECS services)
################################################################################

resource "aws_ssm_parameter" "livekit_url" {
  name        = "/${local.secret_prefix}/common/LIVEKIT_URL"
  description = "LiveKit server URL"
  type        = "String"
  value       = var.livekit_url

  tags = merge(var.tags, {
    Component = "livekit"
    Shared    = "true"
  })
}

resource "aws_ssm_parameter" "agent_name" {
  name        = "/${local.secret_prefix}/common/AGENT_NAME"
  description = "Agent name for service identification"
  type        = "String"
  value       = var.agent_name

  tags = merge(var.tags, {
    Component = "common"
    Shared    = "true"
  })
}

################################################################################
# LiveKit Agent Service Secrets
################################################################################

resource "aws_secretsmanager_secret" "livekit_agent" {
  name                    = "${local.secret_prefix}/livekit-agent/secrets"
  description             = "Secrets for LiveKit Agent service (AI provider API keys)"
  recovery_window_in_days = 30

  tags = merge(var.tags, {
    Service = "livekit-agent"
  })
}

resource "aws_secretsmanager_secret_version" "livekit_agent" {
  secret_id = aws_secretsmanager_secret.livekit_agent.id
  secret_string = jsonencode({
    DEEPGRAM_API_KEY = var.deepgram_api_key
    CARTESIA_API_KEY = var.cartesia_api_key
    ELEVEN_API_KEY   = var.eleven_api_key
    GOOGLE_API_KEY   = var.google_api_key
    ONTUNE_SECRET    = var.ontune_secret
    OPENAI_API_KEY   = var.openai_api_key
  })

  lifecycle {
    ignore_changes = [secret_string] # Allow manual updates without Terraform override
  }
}