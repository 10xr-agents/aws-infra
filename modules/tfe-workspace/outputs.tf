# modules/tfe-workspace/outputs.tf

output "workspace_id" {
  description = "Sub-workspace ID"
  value       = tfe_workspace.sub_workspace.id
}

output "workspace_name" {
  description = "Sub-workspace name"
  value       = tfe_workspace.sub_workspace.name
}

output "workspace_url" {
  description = "Sub-workspace URL"
  value       = "https://app.terraform.io/app/${data.tfe_organization.main.name}/workspaces/${tfe_workspace.sub_workspace.name}"
}