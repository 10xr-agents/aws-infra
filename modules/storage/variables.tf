# modules/tfe-workspace/variables.tf

variable "tfe_organization_name" {
  description = "Terraform Cloud organization name"
  type        = string
}

variable "parent_workspace_name" {
  description = "Name of the parent workspace"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "workspace_suffix" {
  description = "Suffix for workspace name (e.g., 'storage', 'monitoring')"
  type        = string
}

variable "workspace_description" {
  description = "Description for the workspace"
  type        = string
  default     = ""
}

variable "auto_apply" {
  description = "Whether to auto-apply changes"
  type        = bool
  default     = false
}

variable "github_repo" {
  description = "GitHub repository for the workspace"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch"
  type        = string
  default     = "main"
}

variable "github_oauth_token_id" {
  description = "GitHub OAuth token ID"
  type        = string
}

variable "working_directory" {
  description = "Working directory in the repository"
  type        = string
  default     = ""
}

variable "workspace_variables" {
  description = "Map of variables to set in the workspace"
  type = map(object({
    value       = string
    category    = string # "terraform" or "env"
    description = string
    sensitive   = optional(bool, false)
    hcl         = optional(bool, false)
  }))
  default = {}
}

variable "enable_run_trigger" {
  description = "Whether to enable run trigger from parent workspace"
  type        = bool
  default     = true
}