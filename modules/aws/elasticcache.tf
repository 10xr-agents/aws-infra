# module "elasticache" {
#   source = "terraform-aws-modules/elasticache/aws"
#   version = "~> 1.4.1"
#
#   cluster_id           = "${local.name}-redis"
#   engine              = "redis"
#   engine_version      = "7.0"
#   node_type           = "cache.t3.medium"
#   num_cache_nodes     = 2
#   port                = 6379
#
#   subnet_ids          = module.vpc.elasticache_subnets
#   security_group_ids  = [module.redis_sg.security_group_id]
#
#   maintenance_window       = "mon:03:00-mon:04:00"
#   snapshot_window         = "04:00-05:00"
#   snapshot_retention_limit = 7
#
#   at_rest_encryption_enabled = true
#   transit_encryption_enabled = true
#
#   apply_immediately = true
#   family           = "redis7"
#
#   tags = local.tags
# }
#
# # Redis Security Group
# module "redis_sg" {
#   source  = "terraform-aws-modules/security-group/aws"
#   version = "~> 5.3.0"
#
#   name        = "${local.name}-redis-sg"
#   description = "Security group for Redis cluster"
#   vpc_id      = module.vpc.vpc_id
#
#   ingress_with_source_security_group_id = [
#     {
#       from_port                = 6379
#       to_port                  = 6379
#       protocol                 = "tcp"
#       description              = "Redis access from ECS tasks"
#       source_security_group_id = aws_security_group.ecs_sg.id
#     }
#   ]
#
#   egress_rules = ["all-all"]
#
#   tags = local.tags
# }