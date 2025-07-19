# environments/prod/locals.tf
locals {

  ecs_services = var.ecs_services

  mongodb_connection_string = data.aws_ssm_parameter.documentdb_connection_string.value

  acm_certificate_arn = module.certs.acm_certificate_arn

  # Updated ECS services configuration with DocumentDB instead of MongoDB
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

            # TEMPORARILY COMMENT OUT - For backward compatibility with existing code
            # Uncomment these after DocumentDB workspace has run
            SPRING_DATA_MONGODB_URI = local.mongodb_connection_string
            MONGO_DB_URL            = local.mongodb_connection_string
            MONGO_DB_URI            = local.mongodb_connection_string
            MONGODB_DATABASE        = var.documentdb_default_database
            DATABASE_NAME           = var.documentdb_default_database
          }
        )
        # Add DocumentDB auth token as a secret for all services that need it
        secrets = concat(
          lookup(config, "secrets", []),
          [
            {
              name       = "REDIS_PASSWORD"
              value_from = module.redis.ssm_parameter_redis_auth_token
            }
          ]
        )

        # ADD IAM permissions for Redis/ElastiCache and DocumentDB
        additional_task_policies = merge(
          lookup(config, "additional_task_policies", {}),
          {
            "ElastiCacheAccess" = aws_iam_policy.ecs_elasticache_policy.arn
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
