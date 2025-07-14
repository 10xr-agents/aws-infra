# environments/prod/locals.tf

resource "random_password" "mongo_auth_token" {
  length  = 32
  special = false
}

# Generate DocumentDB keyfile content for replica set authentication (if needed for compatibility)
resource "random_password" "documentdb_keyfile" {
  length = 756  # DocumentDB keyfile should be between 6-1024 characters
  special = false
  upper   = true
  lower   = true
  numeric = true
}

locals {

  ecs_services = var.ecs_services

  #DocumentDB connection details from separate repository via SSM
  documentdb_connection_string = data.aws_ssm_parameter.documentdb_connection_string.value
  documentdb_endpoint          = data.aws_ssm_parameter.documentdb_endpoint.value
  documentdb_port             = data.aws_ssm_parameter.documentdb_port.value
  documentdb_username         = data.aws_ssm_parameter.documentdb_username.value

  acm_certificate_arn = aws_acm_certificate.main.arn

  # Updated ECS services configuration with DocumentDB instead of MongoDB
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
            CLUSTER_NAME = var.cluster_name
            # Add Redis connection details to all services
            REDIS_URL              = module.redis.redis_connection_string
            REDIS_HOST             = module.redis.redis_primary_endpoint
            REDIS_PORT             = tostring(module.redis.redis_port)
            REDIS_USERNAME         = module.redis.redis_username
            REDIS_TLS_ENABLED      = tostring(var.redis_transit_encryption_enabled)

            #DocumentDB connection details (replaces MongoDB) - COMMENTED OUT
            DOCUMENTDB_URI         = local.documentdb_connection_string
            DOCUMENTDB_HOST        = local.documentdb_endpoint
            DOCUMENTDB_PORT        = local.documentdb_port
            DOCUMENTDB_DATABASE    = var.documentdb_default_database
            DATABASE_NAME          = var.documentdb_default_database

            #For backward compatibility with existing code - COMMENTED OUT
            SPRING_DATA_MONGODB_URI = local.documentdb_connection_string
            MONGO_DB_URL            = local.documentdb_connection_string
            MONGO_DB_URI            = local.documentdb_connection_string
            MONGODB_DATABASE        = var.documentdb_default_database
          }
        )
        # Add DocumentDB auth token as a secret for all services that need it
        secrets = concat(
          lookup(config, "secrets", []),
          [
            {
              name       = "REDIS_PASSWORD"
              value_from = module.redis.ssm_parameter_redis_auth_token
            },
            # DocumentDB secrets - COMMENTED OUT
            {
              name       = "DOCUMENTDB_PASSWORD"
              value_from = data.aws_ssm_parameter.documentdb_password.name
            },
            {
              name       = "DOCUMENTDB_USERNAME"
              value_from = data.aws_ssm_parameter.documentdb_username.name
            }
          ]
        )

        # ADD IAM permissions for Redis/ElastiCache and DocumentDB
        additional_task_policies = merge(
          lookup(config, "additional_task_policies", {}),
          {
            "ElastiCacheAccess" = aws_iam_policy.ecs_elasticache_policy.arn
            # DocumentDB IAM policy - COMMENTED OUT
            "DocumentDBAccess"  = aws_iam_policy.ecs_documentdb_policy.arn
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

# IAM Policy for DocumentDB access (replaces MongoDB policy) - COMMENTED OUT
resource "aws_iam_policy" "ecs_documentdb_policy" {
  name        = "${local.cluster_name}-ecs-documentdb-policy"
  description = "IAM policy for ECS tasks to access DocumentDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # DocumentDB permissions
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances",
          "rds:DescribeDBSubnetGroups",
          "rds:ListTagsForResource",
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