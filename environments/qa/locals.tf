# environments/qa/locals.tf

resource "random_password" "mongo_auth_token" {
  length  = 32
  special = false
}

# Generate MongoDB keyfile content for replica set authentication
resource "random_password" "mongodb_keyfile" {
  length = 756  # MongoDB keyfile should be between 6-1024 characters
  special = true
  upper   = true
  lower   = true
  numeric = true
}

locals {

  ecs_services = var.ecs_services

  mongodb_connection_string = "mongodb://${var.mongodb_admin_username}:${random_password.mongo_auth_token}@${join(",", module.mongodb.endpoints)}/${var.mongodb_default_database}?replicaSet=${module.mongodb.replica_set_name}&authSource=admin"

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
            CLUSTER_NAME = var.cluster_name
            # Add Redis connection details to all services
            REDIS_URL              = module.redis.redis_connection_string
            REDIS_HOST             = module.redis.redis_primary_endpoint
            REDIS_PORT             = tostring(module.redis.redis_port)
            REDIS_USERNAME         = module.redis.redis_username
            REDIS_TLS_ENABLED      = tostring(var.redis_transit_encryption_enabled)

            SPRING_DATA_MONGODB_URI = local.mongodb_connection_string
            MONGO_DB_URI            = local.mongodb_connection_string
            MONGODB_DATABASE        = var.mongodb_default_database
            DATABASE_NAME           = var.mongodb_default_database
          }
        )
        # Add Redis auth token as a secret for all services that need it
        secrets = concat(
          lookup(config, "secrets", []),
          [
            {
              name       = "REDIS_PASSWORD"
              value_from = module.redis.ssm_parameter_redis_auth_token
            },
            {
              name       = "MONGODB_PASSWORD"
              value_from = module.mongodb.ssm_parameter_name
            }
          ]
        )

        # ADD IAM permissions for Redis/ElastiCache
        additional_task_policies = merge(
          lookup(config, "additional_task_policies", {}),
          {
            "ElastiCacheAccess" = aws_iam_policy.ecs_elasticache_policy.arn
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

# IAM Policy for MongoDB access
resource "aws_iam_policy" "ecs_mongodb_policy" {
  name        = "${local.cluster_name}-ecs-mongodb-policy"
  description = "IAM policy for ECS tasks to access MongoDB resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
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
