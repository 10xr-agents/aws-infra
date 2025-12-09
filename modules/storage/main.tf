# modules/tfe-workspace/main.tf - Data Source Approach

# Get organization
data "tfe_organization" "main" {
  name = var.tfe_organization_name
}

# Get parent workspace
data "tfe_workspace" "parent" {
  name         = var.parent_workspace_name
  organization = data.tfe_organization.main.name
}

# Get existing sub-workspace (instead of creating it)
data "tfe_workspace" "sub_workspace" {
  name         = "${var.environment}-${var.region}-${var.workspace_suffix}"
  organization = data.tfe_organization.main.name
}

################################################################################
# Set Variables in Existing Sub-Workspace
################################################################################

resource "tfe_variable" "variables" {
  for_each = var.workspace_variables

  key          = each.key
  value        = each.value.value
  category     = each.value.category
  workspace_id = data.tfe_workspace.sub_workspace.id
  description  = each.value.description
  sensitive    = lookup(each.value, "sensitive", false)
  hcl          = lookup(each.value, "hcl", false)
}

################################################################################
# Run Trigger
################################################################################

resource "tfe_run_trigger" "sub_workspace_trigger" {
  count = var.enable_run_trigger ? 1 : 0

  workspace_id  = data.tfe_workspace.sub_workspace.id
  sourceable_id = data.tfe_workspace.parent.id
}