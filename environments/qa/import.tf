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

# ECS Service VPC ingress rule for hospice service (sg-09f6ef79285a6ddc9)
import {
  to = module.ecs.aws_security_group_rule.ecs_service_from_vpc["hospice"]
  id = "sgr-0d46d51038e31b6e7"
}

# ECS Service VPC ingress rule for home-health service (sg-01967587e440b20a1)
import {
  to = module.ecs.aws_security_group_rule.ecs_service_from_vpc["home-health"]
  id = "sgr-0349c3427e385d48c"
}

# ALB egress rule to ECS services (sg-0c92cb84278774c73)
import {
  to = module.ecs.aws_security_group_rule.alb_to_ecs_services[0]
  id = "sgr-0e62b78992e9f8574"
}
