# environments/qa/import.tf
#
# One-time import file for existing AWS resources
# After successful import, this file can be deleted
#
# Usage:
#   1. Run: terraform plan (verify imports will work)
#   2. Run: terraform apply (imports happen automatically)
#   3. Delete this file after successful apply
################################################################################
# CloudWatch Log Group Imports
################################################################################

# RDS PostgreSQL log group for n8n
import {
  to = module.n8n.module.rds.aws_cloudwatch_log_group.rds["postgresql"]
  id = "/aws/rds/instance/ten-xr-app-qa/postgresql"
}
