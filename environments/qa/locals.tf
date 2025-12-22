# environments/qa/locals.tf

locals {
  # Local cluster name for naming resources
  cluster_name = "${var.cluster_name}-${var.environment}"

  # Secret prefix for consistent naming
  secret_prefix = local.cluster_name

  # Get ECS services from tfvars
  ecs_services = var.ecs_services

  # ACM certificate ARN - use validated cert when Cloudflare DNS is enabled
  # The certificate must be validated before use (Cloudflare creates validation records)
  acm_certificate_arn = var.enable_cloudflare_dns ? module.certs.validated_certificate_arn : module.certs.acm_certificate_arn

  # DocumentDB database names per service
  documentdb_database_home_health = "10XR_Home_Health_${var.environment}"
  documentdb_database_hospice     = "10XR_Hospice_${var.environment}"

  # ECS services with all environment and secret overrides
  ecs_services_with_overrides = {
    for name, config in local.ecs_services : name => merge(
      config,
      {
        # Environment variables (non-sensitive)
        environment = merge(
          config.environment,
          {
            # Common environment variables
            ENVIRONMENT     = var.environment
            ECS_ENVIRONMENT = var.environment
            CLUSTER_NAME    = var.cluster_name
            NODE_ENV        = "production"

            # Service-specific URLs based on service name
            NEXT_PUBLIC_BASE_URL = name == "home-health" ? "https://homehealth.${var.domain}" : "https://hospice.${var.domain}"
            NEXTAUTH_URL         = name == "home-health" ? "https://homehealth.${var.domain}" : "https://hospice.${var.domain}"

            # DocumentDB connection details (non-sensitive)
            DOCUMENTDB_HOST        = module.documentdb.endpoint
            DOCUMENTDB_READER_HOST = module.documentdb.reader_endpoint
            DOCUMENTDB_PORT        = tostring(module.documentdb.port)
            DOCUMENTDB_DATABASE    = name == "home-health" ? local.documentdb_database_home_health : local.documentdb_database_hospice
            DOCUMENTDB_TLS_ENABLED = "true"
            MONGODB_DATABASE       = name == "home-health" ? local.documentdb_database_home_health : local.documentdb_database_hospice
            DATABASE_NAME          = name == "home-health" ? local.documentdb_database_home_health : local.documentdb_database_hospice

            # S3 Configuration (using IAM roles instead of access keys)
            S3_BUCKET_NAME = module.s3_patients.bucket_id
            AWS_REGION     = var.region
          }
        )

        # Secrets from Secrets Manager
        secrets = concat(
          lookup(config, "secrets", []),
          [
            # DocumentDB credentials
            {
              name       = "DOCUMENTDB_USERNAME"
              value_from = "${module.documentdb.secrets_manager_secret_arn}:username::"
            },
            {
              name       = "DOCUMENTDB_PASSWORD"
              value_from = "${module.documentdb.secrets_manager_secret_arn}:password::"
            },
            {
              name       = "DOCUMENTDB_CONNECTION_STRING"
              value_from = "${module.documentdb.secrets_manager_secret_arn}:connection_string::"
            },
            # MongoDB-compatible connection strings (for Next.js apps using MongoDB driver)
            {
              name       = "MONGODB_URI"
              value_from = "${module.documentdb.secrets_manager_secret_arn}:connection_string::"
            },
            {
              name       = "MONGO_DB_URL"
              value_from = "${module.documentdb.secrets_manager_secret_arn}:connection_string::"
            },
            {
              name       = "MONGO_DB_URI"
              value_from = "${module.documentdb.secrets_manager_secret_arn}:connection_string::"
            },
            # Service-specific secrets from Secrets Manager
            {
              name       = "NEXTAUTH_SECRET"
              value_from = name == "home-health" ? "${aws_secretsmanager_secret.home_health.arn}:NEXTAUTH_SECRET::" : "${aws_secretsmanager_secret.hospice.arn}:NEXTAUTH_SECRET::"
            },
            {
              name       = "ONTUNE_SECRET"
              value_from = name == "home-health" ? "${aws_secretsmanager_secret.home_health.arn}:ONTUNE_SECRET::" : "${aws_secretsmanager_secret.hospice.arn}:ONTUNE_SECRET::"
            },
            {
              name       = "ADMIN_API_KEY"
              value_from = name == "home-health" ? "${aws_secretsmanager_secret.home_health.arn}:ADMIN_API_KEY::" : "${aws_secretsmanager_secret.hospice.arn}:ADMIN_API_KEY::"
            },
            {
              name       = "NEXT_PUBLIC_ADMIN_API_KEY"
              value_from = name == "home-health" ? "${aws_secretsmanager_secret.home_health.arn}:NEXT_PUBLIC_ADMIN_API_KEY::" : "${aws_secretsmanager_secret.hospice.arn}:NEXT_PUBLIC_ADMIN_API_KEY::"
            },
            {
              name       = "GEMINI_API_KEY"
              value_from = name == "home-health" ? "${aws_secretsmanager_secret.home_health.arn}:GEMINI_API_KEY::" : "${aws_secretsmanager_secret.hospice.arn}:GEMINI_API_KEY::"
            }
          ],
          # Add OpenAI API key only for home-health
          name == "home-health" ? [
            {
              name       = "OPENAI_API_KEY"
              value_from = "${aws_secretsmanager_secret.home_health.arn}:OPENAI_API_KEY::"
            }
          ] : []
        )

        # IAM policies for accessing DocumentDB, S3, and Secrets Manager
        additional_task_policies = merge(
          lookup(config, "additional_task_policies", {}),
          {
            "DocumentDBAccess" = module.documentdb.iam_policy_arn
            "S3PatientAccess"  = module.s3_patients.iam_policy_arn
            "SecretsAccess"    = aws_iam_policy.ecs_secrets_policy.arn
          }
        )
      }
    )
  }
}

# IAM Policy for Secrets Manager and SSM access
resource "aws_iam_policy" "ecs_secrets_policy" {
  name        = "${local.cluster_name}-ecs-secrets-policy"
  description = "IAM policy for ECS tasks to access Secrets Manager and SSM"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.home_health.arn,
          aws_secretsmanager_secret.hospice.arn,
          module.documentdb.secrets_manager_secret_arn
        ]
      },
      {
        Sid    = "SSMParameterAccess"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${local.secret_prefix}/*"
        ]
      },
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          module.documentdb.kms_key_arn,
          module.s3_patients.kms_key_arn
        ]
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for DocumentDB CloudWatch metrics
resource "aws_iam_policy" "ecs_documentdb_monitoring_policy" {
  name        = "${local.cluster_name}-ecs-documentdb-monitoring-policy"
  description = "IAM policy for ECS tasks to access DocumentDB CloudWatch metrics"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/docdb/${var.cluster_name}-${var.environment}*"
        ]
      }
    ]
  })

  tags = var.tags
}
