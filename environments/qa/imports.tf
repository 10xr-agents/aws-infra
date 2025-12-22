# environments/qa/imports.tf
#
# Import blocks for security group rules that exist in AWS but not in Terraform state.
# After successful import (terraform plan shows no changes for these resources),
# this file can be deleted.
#
# These rules were created outside Terraform or state was lost.

################################################################################
# Security Group Rule Imports
################################################################################

# ALB egress rule to ECS services (VPC CIDR)
import {
  to = module.ecs.aws_security_group_rule.alb_to_ecs_services[0]
  id = "sg-0f0b2b4b350d276ff_egress_tcp_0_65535_10.0.0.0/16"
}

# ECS Hospice service ingress from VPC CIDR
import {
  to = module.ecs.aws_security_group_rule.ecs_service_from_vpc["hospice"]
  id = "sg-0c8d5cda13a8dcb67_ingress_tcp_0_65535_10.0.0.0/16"
}

# ECS Home-Health service ingress from VPC CIDR
import {
  to = module.ecs.aws_security_group_rule.ecs_service_from_vpc["home-health"]
  id = "sg-0ae646e5a1391da56_ingress_tcp_0_65535_10.0.0.0/16"
}
