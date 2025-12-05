# environments/qa/locals.tf

locals {
  ecs_services = var.ecs_services

  acm_certificate_arn = module.certs.acm_certificate_arn

  # DocumentDB database name
  documentdb_database_name = "ten_xr_agents_${var.environment}"

  # You can also merge with environment-specific overrides
  ecs_services_with_overrides = {
    for name, config in local.ecs_services : name => merge(
      config,
      {
        # Override specific values per environment if needed
        environment = merge(
          config.environment,
          {
            ENVIRONMENT            = var.environment
            ECS_ENVIRONMENT        = var.environment
            SPRING_PROFILES_ACTIVE = var.environment
            CLUSTER_NAME           = var.cluster_name

            # Redis connection details (when Redis module is enabled)
            # REDIS_URL              = module.redis.redis_connection_string
            # REDIS_HOST             = module.redis.redis_primary_endpoint
            # REDIS_PORT             = tostring(module.redis.redis_port)
            # REDIS_USERNAME         = module.redis.redis_username
            # REDIS_TLS_ENABLED      = tostring(var.redis_transit_encryption_enabled)

            # DocumentDB connection details (replaces MongoDB)
            DOCUMENTDB_HOST          = module.documentdb.endpoint
            DOCUMENTDB_READER_HOST   = module.documentdb.reader_endpoint
            DOCUMENTDB_PORT          = tostring(module.documentdb.port)
            DOCUMENTDB_DATABASE      = local.documentdb_database_name
            DOCUMENTDB_TLS_ENABLED   = "true"

            # MongoDB-compatible environment variables pointing to DocumentDB
            SPRING_DATA_MONGODB_URI  = ""  # Will be injected via secrets
            MONGO_DB_URL             = ""  # Will be injected via secrets
            MONGO_DB_URI             = ""  # Will be injected via secrets
            MONGODB_DATABASE         = local.documentdb_database_name
            DATABASE_NAME            = local.documentdb_database_name
          }
        )

        # Add secrets for DocumentDB credentials
        secrets = concat(
          lookup(config, "secrets", []),
          [
            # DocumentDB credentials from Secrets Manager
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
            # MongoDB-compatible secret references (for applications using MongoDB driver)
            {
              name       = "SPRING_DATA_MONGODB_URI"
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
            {
              name       = "MONGODB_PASSWORD"
              value_from = "${module.documentdb.secrets_manager_secret_arn}:password::"
            }
            # Redis password (when Redis module is enabled)
            # {
            #   name       = "REDIS_PASSWORD"
            #   value_from = module.redis.ssm_parameter_redis_auth_token
            # }
          ]
        )

        # ADD IAM permissions for DocumentDB and ElastiCache
        additional_task_policies = merge(
          lookup(config, "additional_task_policies", {}),
          {
            "DocumentDBAccess"  = module.documentdb.iam_policy_arn
            "ElastiCacheAccess" = aws_iam_policy.ecs_elasticache_policy.arn
          }
        )
      }
    )
  }
}

# IAM Policy for ElastiCache access
resource "aws_iam_policy" "ecs_elasticache_policy" {
  name        = "${local.cluster_name}-ecs-elasticache-policy"
  description = "IAM policy for ECS tasks to access ElastiCache"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # ElastiCache permissions
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeReplicationGroups",
          "elasticache:DescribeCacheSubnetGroups",
          "elasticache:ListTagsForResource",
          # SSM permissions for connection details
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          # Secrets Manager permissions
          "secretsmanager:GetSecretValue",
          # KMS permissions for decryption
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for DocumentDB CloudWatch metrics (optional)
resource "aws_iam_policy" "ecs_documentdb_monitoring_policy" {
  name        = "${local.cluster_name}-ecs-documentdb-monitoring-policy"
  description = "IAM policy for ECS tasks to access DocumentDB CloudWatch metrics"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}
