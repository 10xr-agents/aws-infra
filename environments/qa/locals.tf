# environments/qa/locals.tf

locals {

  ecs_services = var.ecs_services

  # You can also merge with environment-specific overrides
  ecs_services_with_overrides = { for name, config in local.ecs_services : name => merge(
    config,
    {
      # Override specific values per environment if needed
      environment = merge(
        config.environment,
        {
          ENVIRONMENT = var.environment
          ECS_ENVIRONMENT = var.environment
          SPRING_PROFILES_ACTIVE = var.environment
          CLUSTER_NAME = var.cluster_name
        }
      )
    }
  )}
}

# Then in your terraform.tfvars or when calling the module:
# ecs_services = local.ecs_services_with_overrides