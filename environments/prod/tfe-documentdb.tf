# environments/prod/tfe-documentdb.tf
# TFE Provider configuration for managing DocumentDB sub-workspace



# TFE Provider configuration
provider "tfe" {
}

# Data source to get the current organization
data "tfe_organization" "main" {
  name = var.tfe_organization_name
}

# Data source to get the current workspace (main workspace)
data "tfe_workspace" "main" {
  name         = var.tfe_main_workspace_name
  organization = data.tfe_organization.main.name
}

################################################################################
# DocumentDB Sub-Workspace Creation
################################################################################

resource "tfe_workspace" "documentdb" {
  name              = "prod-us-east-1-storage"  # Matches your naming pattern
  organization      = data.tfe_organization.main.name
  description       = "DocumentDB infrastructure for ${var.cluster_name} ${var.environment} environment"
  
  # Workspace settings
  auto_apply            = var.documentdb_workspace_auto_apply
  file_triggers_enabled = true
  queue_all_runs       = false
  speculative_enabled  = true
  structured_run_output_enabled = true
  
  # VCS settings for the sub-workspace repository
  vcs_repo {
    identifier     = var.documentdb_github_repo
    branch         = var.documentdb_github_branch
    oauth_token_id = var.github_oauth_token_id
  }

  # Working directory for the DocumentDB sub-workspace
  working_directory = "environments/${var.environment}"

  # Execution mode
  execution_mode = "remote"

  # Tags
  tag_names = [
    "environment:${var.environment}",
    "component:documentdb",
    "project:10xr-agents",
    "managed-by:terraform"
  ]
}

################################################################################
# Variable Sets for DocumentDB Workspace
################################################################################

# Create variable set for DocumentDB workspace
resource "tfe_variable_set" "documentdb" {
  name         = "${var.cluster_name}-documentdb-${var.environment}-vars"
  description  = "Variables for DocumentDB workspace"
  organization = data.tfe_organization.main.name
}

# Associate variable set with DocumentDB workspace
resource "tfe_workspace_variable_set" "documentdb" {
  workspace_id    = tfe_workspace.documentdb.id
  variable_set_id = tfe_variable_set.documentdb.id
}

################################################################################
# DocumentDB Workspace Variables
################################################################################

# AWS Region
resource "tfe_variable" "documentdb_aws_region" {
  key          = "aws_region"
  value        = var.region
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "AWS region for DocumentDB deployment"
}

# Environment
resource "tfe_variable" "documentdb_environment" {
  key          = "environment"
  value        = var.environment
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "Environment name"
}

# Cluster identifier
resource "tfe_variable" "documentdb_cluster_identifier" {
  key          = "cluster_identifier"
  value        = "${var.cluster_name}-docdb"
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "DocumentDB cluster identifier"
}

# VPC name (derived from main workspace)
resource "tfe_variable" "documentdb_vpc_name" {
  key          = "vpc_name"
  value        = "${var.cluster_name}-${var.environment}-${var.region}"
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "VPC name to find via data source"
}

# DocumentDB instance configuration
resource "tfe_variable" "documentdb_instance_count" {
  key          = "instance_count"
  value        = var.documentdb_instance_count
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "Number of DocumentDB instances"
}

resource "tfe_variable" "documentdb_instance_class" {
  key          = "instance_class"
  value        = var.documentdb_instance_class
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "DocumentDB instance class"
}

# Database configuration
resource "tfe_variable" "documentdb_master_username" {
  key          = "master_username"
  value        = var.documentdb_master_username
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "DocumentDB master username"
  sensitive    = true
}

resource "tfe_variable" "documentdb_database_name" {
  key          = "database_name"
  value        = var.documentdb_default_database
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "Default database name"
}

# Network configuration
resource "tfe_variable" "documentdb_allowed_cidr_blocks" {
  key          = "allowed_cidr_blocks"
  value        = jsonencode([var.vpc_cidr])
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "CIDR blocks allowed to access DocumentDB"
  hcl          = true
}

# Backup and maintenance configuration
resource "tfe_variable" "documentdb_backup_retention_period" {
  key          = "backup_retention_period"
  value        = var.documentdb_backup_retention_period
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "Backup retention period in days"
}

resource "tfe_variable" "documentdb_preferred_backup_window" {
  key          = "preferred_backup_window"
  value        = var.documentdb_preferred_backup_window
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "Preferred backup window"
}

resource "tfe_variable" "documentdb_preferred_maintenance_window" {
  key          = "preferred_maintenance_window"
  value        = var.documentdb_preferred_maintenance_window
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "Preferred maintenance window"
}

# Encryption settings
resource "tfe_variable" "documentdb_storage_encrypted" {
  key          = "storage_encrypted"
  value        = "true"
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "Whether to encrypt storage"
}

# Monitoring configuration
resource "tfe_variable" "documentdb_enabled_cloudwatch_logs_exports" {
  key          = "enabled_cloudwatch_logs_exports"
  value        = jsonencode(["audit", "profiler"])
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "List of log types to export to CloudWatch"
  hcl          = true
}

resource "tfe_variable" "documentdb_monitoring_interval" {
  key          = "monitoring_interval"
  value        = "60"
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "Enhanced monitoring interval"
}

# SSM parameter prefix
resource "tfe_variable" "documentdb_ssm_parameter_prefix" {
  key          = "ssm_parameter_prefix"
  value        = "/documentdb"
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "SSM parameter prefix for storing connection details"
}

# Tags
resource "tfe_variable" "documentdb_tags" {
  key          = "tags"
  value        = jsonencode(merge(var.tags, {
    Component     = "DocumentDB"
    ManagedBy     = "10xR"
    SubWorkspace  = "true"
    ParentWorkspace = data.tfe_workspace.main.name
  }))
  category     = "terraform"
  workspace_id = tfe_workspace.documentdb.id
  description  = "Tags for DocumentDB resources"
  hcl          = true
}

# AWS Default Region
resource "tfe_variable" "documentdb_aws_default_region" {
  key          = "AWS_DEFAULT_REGION"
  value        = var.region
  category     = "env"
  workspace_id = tfe_workspace.documentdb.id
  description  = "AWS Default Region"
}

################################################################################
# Workspace Dependencies and Run Triggers
################################################################################

# Create run trigger to automatically run DocumentDB workspace when main workspace completes
resource "tfe_run_trigger" "documentdb_from_main" {
  workspace_id    = tfe_workspace.documentdb.id
  sourceable_id   = data.tfe_workspace.main.id
}

################################################################################
# Team Access for DocumentDB Workspace
################################################################################

# Grant access to the same teams that have access to the main workspace
resource "tfe_team_access" "documentdb_admin" {
  count        = var.grant_admin_team_access ? 1 : 0
  access       = "admin"
  team_id      = var.admin_team_id
  workspace_id = tfe_workspace.documentdb.id
}

resource "tfe_team_access" "documentdb_write" {
  count        = var.grant_write_team_access ? 1 : 0
  access       = "write"
  team_id      = var.write_team_id
  workspace_id = tfe_workspace.documentdb.id
}

resource "tfe_team_access" "documentdb_read" {
  count        = var.grant_read_team_access ? 1 : 0
  access       = "read"
  team_id      = var.read_team_id
  workspace_id = tfe_workspace.documentdb.id
}

################################################################################
# Notification Configuration
################################################################################

resource "tfe_notification_configuration" "documentdb_slack" {
  count            = var.enable_slack_notifications ? 1 : 0
  name             = "DocumentDB Workspace Notifications"
  enabled          = true
  destination_type = "slack"
  triggers         = ["run:completed", "run:errored", "run:needs_attention"]
  url              = var.slack_webhook_url
  workspace_id     = tfe_workspace.documentdb.id
}

################################################################################
# Outputs
################################################################################

output "documentdb_workspace_id" {
  description = "DocumentDB workspace ID"
  value       = tfe_workspace.documentdb.id
}

output "documentdb_workspace_name" {
  description = "DocumentDB workspace name"
  value       = tfe_workspace.documentdb.name
}

output "documentdb_workspace_url" {
  description = "DocumentDB workspace URL"
  value       = "https://app.terraform.io/app/${data.tfe_organization.main.name}/workspaces/${tfe_workspace.documentdb.name}"
}