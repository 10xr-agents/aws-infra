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
# Security Group Rule Imports
# These rules already exist in AWS but are not in Terraform state
################################################################################

# ECS Service VPC ingress rule for hospice service
import {
  to = module.ecs.aws_security_group_rule.ecs_service_from_vpc["hospice"]
  id = "sgr-0aade5f031c8baeb0"
}

# ECS Service VPC ingress rule for home-health service
import {
  to = module.ecs.aws_security_group_rule.ecs_service_from_vpc["home-health"]
  id = "sgr-026a4e4a5945cf397"
}

# ALB egress rule to ECS services
import {
  to = module.ecs.aws_security_group_rule.alb_to_ecs_services[0]
  id = "sgr-0489b08eda21dee37"
}
