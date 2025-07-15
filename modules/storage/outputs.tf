# modules/tfe-workspace/outputs.tf - Data Source Approach

output "workspace_id" {
  description = "Sub-workspace ID"
  value       = data.tfe_workspace.sub_workspace.id
}

output "workspace_name" {
  description = "Sub-workspace name"
  value       = data.tfe_workspace.sub_workspace.name
}

output "workspace_url" {
  description = "Sub-workspace URL"
  value       = "https://app.terraform.io/app/${data.tfe_organization.main.name}/workspaces/${data.tfe_workspace.sub_workspace.name}"
}