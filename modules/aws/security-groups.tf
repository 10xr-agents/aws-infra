# # Security group configurations
# locals {
#   security_groups = {
#     alb = {
#       name        = "${local.name}-alb-sg"
#       description = "Security group for ALB"
#       vpc_id      = module.vpc.vpc_id
#       ingress_rules = ["http-80-tcp", "https-443-tcp"]
#       egress_rules  = ["all-all"]
#     }
#
#     ecs = {
#       name        = "${local.name}-ecs-sg"
#       description = "Security group for ECS tasks"
#       vpc_id      = module.vpc.vpc_id
#       computed_ingress_with_source_security_group_id = [
#         {
#           rule                     = "http-80-tcp"
#           source_security_group_id = module.alb_sg.security_group_id
#         }
#       ]
#       computed_ingress_with_self = [
#         {
#           rule = "all-all"
#         }
#       ]
#       egress_rules = ["all-all"]
#     }
#
#     redis = {
#       name        = "${local.name}-redis-sg"
#       description = "Security group for Redis cluster"
#       vpc_id      = module.vpc.vpc_id
#       ingress_with_source_security_group_id = [
#         {
#           from_port                = 6379
#           to_port                  = 6379
#           protocol                 = "tcp"
#           description             = "Redis access"
#           source_security_group_id = module.ecs_sg.security_group_id
#         }
#       ]
#       egress_rules = ["all-all"]
#     }
#
#     efs = {
#       name        = "${local.name}-efs-sg"
#       description = "Security group for EFS"
#       vpc_id      = module.vpc.vpc_id
#       ingress_with_source_security_group_id = [
#         {
#           from_port                = 2049
#           to_port                  = 2049
#           protocol                 = "tcp"
#           description             = "NFS access"
#           source_security_group_id = module.ecs_sg.security_group_id
#         }
#       ]
#       egress_rules = ["all-all"]
#     }
#   }
# }
#
# module "security_groups" {
#   source  = "terraform-aws-modules/security-group/aws"
#   version = "~> 5.0"
#
#   for_each = local.security_groups
#
#   name        = each.value.name
#   description = each.value.description
#   vpc_id      = each.value.vpc_id
#
#   ingress_rules                               = try(each.value.ingress_rules, [])
#   egress_rules                                = try(each.value.egress_rules, [])
#   computed_ingress_with_source_security_group_id = try(each.value.computed_ingress_with_source_security_group_id, [])
#   computed_ingress_with_self                     = try(each.value.computed_ingress_with_self, [])
#   ingress_with_source_security_group_id          = try(each.value.ingress_with_source_security_group_id, [])
#
#   tags = local.tags
# }