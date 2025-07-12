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

  # MongoDB connection from separate VPC
  mongodb_connection_string = data.aws_ssm_parameter.app_mongodb_connection.value
  mongodb_details = jsondecode(data.aws_ssm_parameter.mongodb_connection_info.value)
  
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
            SPRING_DATA_MONGODB_URI = local.mongodb_connection_string
            MONGO_DB_URL            = local.mongodb_connection_string
            MONGO_DB_URI            = local.mongodb_connection_string
            MONGODB_DATABASE        = local.mongodb_details.default_database
            DATABASE_NAME           = local.mongodb_details.default_database
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
