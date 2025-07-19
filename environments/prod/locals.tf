# environments/prod/locals.tf
locals {
  cluster_name = "${var.cluster_name}-prod"
  vpc_name     = "${var.cluster_name}-${var.environment}-${var.region}"

  ecs_services = var.ecs_services

  # MongoDB connection from Secrets Manager (from separate repository)
  mongodb_secret_arn = var.mongodb_secret_manager_arn

  acm_certificate_arn = module.certs.acm_certificate_arn

  # Updated ECS services configuration with MongoDB Atlas
  ecs_services_with_overrides = {
    for name, config in local.ecs_services : name => merge(
      config,
      {
        # Override specific values per environment if needed
        environment = merge(
          config.environment,
          {
            ENVIRONMENT            = "production"
            ECS_ENVIRONMENT        = "production"
            SPRING_PROFILES_ACTIVE = "production"
            CLUSTER_NAME = var.cluster_name

            # Add Redis connection details to all services
            REDIS_URL              = module.redis.redis_connection_string
            REDIS_HOST             = module.redis.redis_primary_endpoint
            REDIS_PORT = tostring(module.redis.redis_port)
            REDIS_USERNAME         = module.redis.redis_username
            REDIS_TLS_ENABLED = tostring(var.redis_transit_encryption_enabled)

            # MongoDB Atlas database configuration
            MONGODB_DATABASE        = var.mongodb_database_name
            DATABASE_NAME           = var.mongodb_database_name
            MONGODB_SSL_ENABLED     = "true"
            MONGODB_AUTH_SOURCE     = "admin"
          }
        )

        # Add MongoDB and Redis secrets for all services that need them
        secrets = concat(
          lookup(config, "secrets", []),
          [
            {
              name       = "REDIS_PASSWORD"
              value_from = module.redis.ssm_parameter_redis_auth_token
            },
            # MongoDB connection secrets from Secrets Manager
            {
              name       = "MONGODB_CONNECTION_URI"
              value_from = "${local.mongodb_secret_arn}:app_connection_uri::"
            },
            {
              name       = "MONGODB_USERNAME"
              value_from = "${local.mongodb_secret_arn}:app_username::"
            },
            {
              name       = "MONGODB_PASSWORD"
              value_from = "${local.mongodb_secret_arn}:app_password::"
            },
            {
              name       = "SPRING_DATA_MONGODB_URI"
              value_from = "${local.mongodb_secret_arn}:app_connection_uri::"
            },
            {
              name       = "MONGO_DB_URL"
              value_from = "${local.mongodb_secret_arn}:app_connection_uri::"
            },
            {
              name       = "MONGO_DB_URI"
              value_from = "${local.mongodb_secret_arn}:app_connection_uri::"
            }
          ]
        )

        # ADD IAM permissions for Redis/ElastiCache and MongoDB Atlas
        additional_task_policies = merge(
          lookup(config, "additional_task_policies", {}),
          {
            "ElastiCacheAccess" = aws_iam_policy.ecs_elasticache_policy.arn
            "DocumentDBAccess"  = aws_iam_policy.ecs_documentdb_policy.arn
            "MongoDBAccess"     = aws_iam_policy.ecs_mongodb_policy.arn
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
          # EC2 permissions for MongoDB instances
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
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

# IAM Policy for MongoDB Atlas access via Secrets Manager
resource "aws_iam_policy" "ecs_mongodb_policy" {
  name        = "${local.cluster_name}-ecs-mongodb-policy"
  description = "IAM policy for ECS tasks to access MongoDB Atlas"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Secrets Manager permissions for MongoDB credentials
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          local.mongodb_secret_arn,
          "${local.mongodb_secret_arn}:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          # SSM permissions for connection details
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
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

# IAM Policy for DocumentDB access (replaces MongoDB policy) - KEEP THIS
# This policy definition can stay, we just won't reference it in ECS services yet
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
          # EC2 permissions for MongoDB instances
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          # SSM permissions for connection details
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          # Secrets Manager permissions
          "secretsmanager:GetSecretValue",
          # KMS permissions for decryption
          "kms:Decrypt",
          "kms:DescribeKey",
          # Route53 permissions for DNS resolution
          "route53:ListHostedZones",
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}