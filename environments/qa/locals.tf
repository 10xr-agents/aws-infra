# environments/qa/locals.tf

locals {
  # Load services configuration from JSON file
  services_json = jsondecode(file("${path.module}/services-qa.json"))

  # Or define inline if preferred
  ecs_services = local.services_json

  # You can also merge with environment-specific overrides
  ecs_services_with_overrides = { for name, config in local.services_json : name => merge(
    config,
    {
      # Override specific values per environment if needed
      environment = merge(
        config.environment,
        {
          ENVIRONMENT = var.environment
          CLUSTER_NAME = var.cluster_name
        }
      )
    }
  )}
}

# Then in your terraform.tfvars or when calling the module:
# ecs_services = local.ecs_services_with_overrides