# modules/ecs-refactored/outputs.tf

# Cluster Outputs
output "cluster_arn" {
  description = "ARN that identifies the cluster"
  value       = module.ecs.cluster_arn
}

output "cluster_id" {
  description = "ID that identifies the cluster"
  value       = module.ecs.cluster_id
}

output "cluster_name" {
  description = "Name that identifies the cluster"
  value       = module.ecs.cluster_name
}

output "cluster_capacity_providers" {
  description = "Map of cluster capacity providers attributes"
  value       = module.ecs.cluster_capacity_providers
}

# Services Outputs
output "services" {
  description = "Map of services created and their attributes"
  value       = module.ecs.services
}

# Service IDs
output "service_ids" {
  description = "Map of service names to their ARNs"
  value = {
    for name, service in module.ecs.services : name => service.id
  }
}

# Service Discovery Outputs
output "service_discovery_namespace_id" {
  description = "ID of the service discovery namespace"
  value       = try(aws_service_discovery_private_dns_namespace.main[0].id, null)
}

output "service_discovery_namespace_name" {
  description = "Name of the service discovery namespace"
  value       = try(aws_service_discovery_private_dns_namespace.main[0].name, null)
}

output "service_discovery_services" {
  description = "Map of service discovery service ARNs"
  value = {
    for name, service in aws_service_discovery_service.services : name => service.arn
  }
}

# Service URLs
output "service_urls" {
  description = "Map of service URLs (internal service discovery)"
  value       = var.enable_service_discovery ? {
    for name, config in var.services : name =>
    "http://${name}.${local.name_prefix}.local:${config.port}"
    if lookup(config, "enable_service_discovery", true)
  } : {}
}