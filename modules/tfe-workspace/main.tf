# modules/tfe-workspace/main.tf

# Get organization
data "tfe_organization" "main" {
  name = var.tfe_organization_name
}

# Get parent workspace
data "tfe_workspace" "parent" {
  name         = var.parent_workspace_name
  organization = data.tfe_organization.main.name
}

################################################################################
# Create Sub-Workspace
################################################################################

resource "tfe_workspace" "sub_workspace" {
  name         = "${var.environment}-${var.region}-${var.workspace_suffix}"
  organization = data.tfe_organization.main.name
  description  = var.workspace_description
  
  auto_apply            = var.auto_apply
  file_triggers_enabled = true
  execution_mode        = "remote"
  
  vcs_repo {
    identifier     = var.github_repo
    branch         = var.github_branch
    oauth_token_id = var.github_oauth_token_id
  }

  working_directory = var.working_directory
}

################################################################################
# Set Variables in Sub-Workspace
################################################################################

resource "tfe_variable" "variables" {
  for_each = var.workspace_variables

  key          = each.key
  value        = each.value.value
  category     = each.value.category
  workspace_id = tfe_workspace.sub_workspace.id
  description  = each.value.description
  sensitive    = lookup(each.value, "sensitive", false)
  hcl          = lookup(each.value, "hcl", false)
}

################################################################################
# Run Trigger
################################################################################

resource "tfe_run_trigger" "sub_workspace_trigger" {
  count = var.enable_run_trigger ? 1 : 0
  
  workspace_id  = tfe_workspace.sub_workspace.id
  sourceable_id = data.tfe_workspace.parent.id
}