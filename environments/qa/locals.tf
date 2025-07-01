# # environments/qa/locals.tf
#
# locals {
#
#   ecs_services = var.ecs_services
#
#   # You can also merge with environment-specific overrides
#   ecs_services_with_overrides = { for name, config in local.ecs_services : name => merge(
#     config,
#     {
#       # Override specific values per environment if needed
#       environment = merge(
#         config.environment,
#         {
#           ENVIRONMENT = var.environment
#           ECS_ENVIRONMENT = var.environment
#           SPRING_PROFILES_ACTIVE = var.environment
#           CLUSTER_NAME = var.cluster_name
#           # Add Redis connection details to all services
#           REDIS_URL = module.redis.redis_connection_string
#           REDIS_ENDPOINT = module.redis.redis_endpoint
#           REDIS_PORT = tostring(module.redis.redis_port)
#           REDIS_USERNAME = module.redis.redis_username
#         }
#       )
#       # Add Redis auth token as a secret for all services that need it
#       secrets = concat(
#         lookup(config, "secrets", []),
#         [
#           {
#             name       = "REDIS_PASSWORD"
#             value_from = module.redis.ssm_parameter_redis_auth_token
#           }
#         ]
#       )
#     }
#   )}
# }
#
# # Then in your terraform.tfvars or when calling the module:
# # ecs_services = local.ecs_services_with_overrides