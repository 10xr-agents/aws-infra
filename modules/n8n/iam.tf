#------------------------------------------------------------------------------
# n8n Module - IAM Roles and Policies
# ECS Execution Role and Task Role with least-privilege access
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# ECS Task Execution Role
# Used by ECS agent to pull images and write logs
#------------------------------------------------------------------------------

resource "aws_iam_role" "ecs_execution_role" {
  name_prefix = "${local.name_prefix}-exec-"
  description = "ECS task execution role for n8n services"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-execution-role"
  })
}

# Attach AWS managed policy for basic ECS execution
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for Secrets Manager access
resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "${local.name_prefix}-execution-secrets"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          module.rds.credentials_secret_arn,
          aws_secretsmanager_secret.n8n_encryption_key.arn,
          # Include Redis secret if provided
        ]
      },
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          module.rds.kms_key_arn
        ]
      }
    ]
  })
}

# Add Redis secret access if provided
resource "aws_iam_role_policy" "ecs_execution_redis_secrets" {
  count = var.enable_redis ? 1 : 0

  name = "${local.name_prefix}-execution-redis-secrets"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RedisSecretsAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.redis_auth_token_secret_arn
        ]
      }
    ]
  })
}

#------------------------------------------------------------------------------
# ECS Task Role
# Used by the n8n application for AWS API access
#------------------------------------------------------------------------------

resource "aws_iam_role" "n8n_task_role" {
  name_prefix = "${local.name_prefix}-task-"
  description = "ECS task role for n8n services"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-task-role"
  })
}

# CloudWatch Logs write access
resource "aws_iam_role_policy" "n8n_task_logs" {
  name = "${local.name_prefix}-task-logs"
  role = aws_iam_role.n8n_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.n8n_main.arn}:*",
          "${aws_cloudwatch_log_group.n8n_webhook.arn}:*",
          "${aws_cloudwatch_log_group.n8n_worker.arn}:*"
        ]
      }
    ]
  })
}

# SSM Parameter Store access (for additional configuration)
resource "aws_iam_role_policy" "n8n_task_ssm" {
  name = "${local.name_prefix}-task-ssm"
  role = aws_iam_role.n8n_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMParameterAccess"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/n8n/${var.environment}/*"
        ]
      }
    ]
  })
}

# S3 access for n8n binary data storage (optional)
resource "aws_iam_role_policy" "n8n_task_s3" {
  name = "${local.name_prefix}-task-s3"
  role = aws_iam_role.n8n_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.name_prefix}-n8n-${var.environment}",
          "arn:aws:s3:::${var.name_prefix}-n8n-${var.environment}/*"
        ]
      }
    ]
  })
}

# SES access for sending emails (optional - n8n email nodes)
resource "aws_iam_role_policy" "n8n_task_ses" {
  name = "${local.name_prefix}-task-ses"
  role = aws_iam_role.n8n_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SESAccess"
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ses:FromAddress" = "n8n@${var.environment}.10xr.co"
          }
        }
      }
    ]
  })
}

# X-Ray tracing (optional)
resource "aws_iam_role_policy" "n8n_task_xray" {
  name = "${local.name_prefix}-task-xray"
  role = aws_iam_role.n8n_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "XRayAccess"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
          "xray:GetSamplingStatisticSummaries"
        ]
        Resource = "*"
      }
    ]
  })
}
