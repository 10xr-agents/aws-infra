# environments/prod/locals.tf

resource "random_password" "redis_auth_token" {
  length  = 32
  special = false
}

locals {
  ecs_services = var.ecs_services

  redis_connection_string = module.redis.redis_connection_string
  acm_certificate_arn = aws_acm_certificate.main.arn
  cluster_name = "${var.cluster_name}-${var.environment}"

  # MongoDB connection details will be fetched conditionally
  # This removes the circular dependency
  mongodb_connection_string = try(data.aws_ssm_parameter.mongodb_connection_info.value, "{}")
  mongodb_details = try(jsondecode(data.aws_ssm_parameter.mongodb_connection_info.value), {
    default_database = var.mongodb_default_database
  })
  
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

            # Add MongoDB connection details to all services
            # Use try() to avoid failures during initial apply
            SPRING_DATA_MONGODB_URI = try(data.aws_ssm_parameter.mongodb_connection_info.value, "")
            MONGO_DB_URL            = try(data.aws_ssm_parameter.mongodb_connection_info.value, "")
            MONGO_DB_URI            = try(data.aws_ssm_parameter.mongodb_connection_info.value, "")
            MONGODB_DATABASE        = try(local.mongodb_details.default_database, var.mongodb_default_database)
            DATABASE_NAME           = try(local.mongodb_details.default_database, var.mongodb_default_database)
          }
        )
        
        # Add Redis auth token as a secret for all services
        secrets = concat(
          lookup(config, "secrets", []),
          [
            {
              name       = "REDIS_PASSWORD"
              value_from = module.redis.ssm_parameter_redis_auth_token
            }
          ]
        )

        # ADD IAM permissions for Redis/ElastiCache and MongoDB
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