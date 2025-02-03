# # monitoring.tf
#
# locals {
#   alarm_defaults = {
#     evaluation_periods  = "2"
#     period             = "300"
#     alarm_description  = "Managed by Terraform"
#     alarm_actions      = var.alarm_actions
#     tags               = local.tags
#     treat_missing_data = "missing"
#   }
#
#   # NAT Gateway alarms map
#   nat_gateway_alarms = {
#     for idx in range(length(local.azs)) : "${local.name}-nat-gateway-errors-${idx + 1}" => {
#       alarm_description   = "NAT Gateway port allocation errors in AZ ${idx + 1}"
#       comparison_operator = "GreaterThanThreshold"
#       metric_name         = "ErrorPortAllocation"
#       namespace           = "AWS/NATGateway"
#       statistic          = "Sum"
#       threshold          = 10
#
#       dimensions = {
#         NatGatewayId = module.vpc.natgw_ids[idx]
#       }
#     }
#   }
#
#   # ECS alarms map
#   ecs_alarms = {
#     for provider in ["FARGATE", "FARGATE_SPOT"] : "${local.name}-${provider}-capacity" => {
#       alarm_description   = "${provider} capacity provider reservation is high"
#       comparison_operator = "GreaterThanThreshold"
#       metric_name         = "CapacityProviderReservation"
#       namespace           = "AWS/ECS"
#       statistic          = "Average"
#       threshold          = 80
#
#       dimensions = {
#         ClusterName          = local.name
#         CapacityProviderName = provider
#       }
#     }
#   }
#
#   # EFS alarms map
#   efs_alarms = {
#     "${local.name}-efs-burst-credits" = {
#       alarm_description   = "EFS burst credits are running low"
#       comparison_operator = "LessThanThreshold"
#       metric_name         = "BurstCreditBalance"
#       namespace          = "AWS/EFS"
#       statistic          = "Average"
#       threshold          = 50000000000 # 50 GB
#
#       dimensions = {
#         FileSystemId = module.efs.id
#       }
#     },
#     "${local.name}-efs-storage" = {
#       alarm_description   = "EFS storage usage is high"
#       comparison_operator = "GreaterThanThreshold"
#       metric_name         = "StorageBytes"
#       namespace          = "AWS/EFS"
#       statistic          = "Average"
#       threshold          = 85 # 85% of storage used
#       period             = 3600 # Check hourly
#
#       dimensions = {
#         FileSystemId = module.efs.id
#       }
#     }
#   }
#
#   # Redis alarms map
#   redis_alarms = {
#     "${local.name}-redis-cpu" = {
#       alarm_description   = "Redis CPU utilization is high"
#       comparison_operator = "GreaterThanThreshold"
#       metric_name         = "CPUUtilization"
#       namespace          = "AWS/ElastiCache"
#       statistic          = "Average"
#       threshold          = 75
#
#       dimensions = {
#         CacheClusterId = module.elasticache.parameter_group_id
#       }
#     },
#     "${local.name}-redis-memory" = {
#       alarm_description   = "Redis free memory is low"
#       comparison_operator = "LessThanThreshold"
#       metric_name         = "FreeableMemory"
#       namespace          = "AWS/ElastiCache"
#       statistic          = "Average"
#       threshold          = 100000000 # 100MB
#
#       dimensions = {
#         CacheClusterId = module.elasticache.parameter_group_id
#       }
#     },
#     "${local.name}-redis-connections" = {
#       alarm_description   = "Redis connection count is high"
#       comparison_operator = "GreaterThanThreshold"
#       metric_name         = "CurrConnections"
#       namespace          = "AWS/ElastiCache"
#       statistic          = "Average"
#       threshold          = 5000
#
#       dimensions = {
#         CacheClusterId = module.elasticache.parameter_group_id
#       }
#     }
#   }
#
#   # ALB alarms map
#   alb_alarms = {
#     "${local.name}-alb-5xx" = {
#       alarm_description   = "High 5XX error rate from ALB"
#       comparison_operator = "GreaterThanThreshold"
#       metric_name         = "HTTPCode_ELB_5XX_Count"
#       namespace          = "AWS/ApplicationELB"
#       statistic          = "Sum"
#       threshold          = 10
#       period             = 300
#
#       dimensions = {
#         LoadBalancer = module.alb.arn_suffix
#       }
#     },
#     "${local.name}-alb-4xx" = {
#       alarm_description   = "High 4XX error rate from ALB"
#       comparison_operator = "GreaterThanThreshold"
#       metric_name         = "HTTPCode_ELB_4XX_Count"
#       namespace          = "AWS/ApplicationELB"
#       statistic          = "Sum"
#       threshold          = 100
#       period             = 300
#
#       dimensions = {
#         LoadBalancer = module.alb.arn_suffix
#       }
#     }
#   }
# }
#
# # Enhanced CloudWatch Dashboard
# resource "aws_cloudwatch_dashboard" "main" {
#   dashboard_name = local.name
#
#   dashboard_body = jsonencode({
#     widgets = [
#       # VPC Metrics
#       {
#         type   = "metric"
#         width  = 12
#         height = 6
#         properties = {
#           metrics = [
#             ["AWS/VPC", "NetworkConnections", "Region", var.aws_region],
#             [".", "FlowLogsIngested", ".", "."]
#           ]
#           period = 300
#           region = var.aws_region
#           title  = "VPC Network Metrics"
#           view   = "timeSeries"
#           stacked = false
#         }
#       },
#       # ECS Metrics
#       {
#         type   = "metric"
#         width  = 12
#         height = 6
#         properties = {
#           metrics = [
#             ["AWS/ECS", "CPUUtilization", "ClusterName", module.ecs.cluster_name],
#             [".", "MemoryUtilization", ".", "."],
#             [".", "RunningTaskCount", ".", "."],
#             [".", "PendingTaskCount", ".", "."]
#           ]
#           period = 300
#           region = var.aws_region
#           title  = "ECS Cluster Metrics"
#           view   = "timeSeries"
#           stacked = false
#         }
#       },
#       # EFS Metrics
#       {
#         type   = "metric"
#         width  = 12
#         height = 6
#         properties = {
#           metrics = [
#             ["AWS/EFS", "BurstCreditBalance", "FileSystemId", module.efs.id],
#             [".", "StorageBytes", ".", "."],
#             [".", "ClientConnections", ".", "."],
#             [".", "PermittedThroughput", ".", "."]
#           ]
#           period = 300
#           region = var.aws_region
#           title  = "EFS Metrics"
#           view   = "timeSeries"
#           stacked = false
#         }
#       },
#       # Redis Metrics
#       {
#         type   = "metric"
#         width  = 12
#         height = 6
#         properties = {
#           metrics = [
#             ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", module.elasticache.parameter_group_id],
#             [".", "FreeableMemory", ".", "."],
#             [".", "CacheHits", ".", "."],
#             [".", "CacheMisses", ".", "."],
#             [".", "CurrConnections", ".", "."],
#             [".", "NetworkBytesIn", ".", "."],
#             [".", "NetworkBytesOut", ".", "."]
#           ]
#           period = 300
#           region = var.aws_region
#           title  = "Redis Metrics"
#           view   = "timeSeries"
#           stacked = false
#         }
#       },
#       # ALB Metrics
#       {
#         type   = "metric"
#         width  = 12
#         height = 6
#         properties = {
#           metrics = [
#             ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", module.alb.arn_suffix],
#             [".", "TargetResponseTime", ".", "."],
#             [".", "HTTPCode_Target_5XX_Count", ".", "."],
#             [".", "HTTPCode_Target_4XX_Count", ".", "."],
#             [".", "ActiveConnectionCount", ".", "."]
#           ]
#           period = 300
#           region = var.aws_region
#           title  = "ALB Metrics"
#           view   = "timeSeries"
#           stacked = false
#         }
#       }
#     ]
#   })
# }
#
# # Centralized Log Groups with Extended Retention
# resource "aws_cloudwatch_log_group" "infrastructure_logs" {
#   for_each = {
#     vpc       = "/aws/vpc/${local.name}"
#     ecs       = "/aws/ecs/${local.name}"
#     alb       = "/aws/alb/${local.name}"
#     efs       = "/aws/efs/${local.name}"
#     redis     = "/aws/elasticache/${local.name}"
#   }
#
#   name              = each.value
#   retention_in_days = 30
#   tags              = local.tags
# }
#
# # Main CloudWatch Alarms
# module "cloudwatch_alarms" {
#   source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
#   version = "~> 5.7.0"
#
#   # Merge all alarm maps
#   metric_alarms = merge(
#     {
#       for name, alarm in merge(
#         local.nat_gateway_alarms,
#         local.ecs_alarms,
#         local.efs_alarms,
#         local.redis_alarms,
#         local.alb_alarms
#       ) : name => merge(local.alarm_defaults, alarm)
#     }
#   )
#   alarm_name          = ""
#   comparison_operator = ""
#   evaluation_periods  = 0
# }
#
# # Service Level Monitoring
# resource "aws_cloudwatch_metric_alarm" "service_errors" {
#   for_each = { for service in var.services : service.name => service }
#
#   alarm_name          = "${local.name}-${each.key}-5xx-errors"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "2"
#   metric_name         = "HTTPCode_Target_5XX_Count"
#   namespace           = "AWS/ApplicationELB"
#   period              = "300"
#   statistic           = "Sum"
#   threshold           = "10"
#   alarm_description   = "High 5XX error rate for ${each.key}"
#   alarm_actions       = var.alarm_actions
#
#   dimensions = {
#     TargetGroup  = module.alb.target_groups[each.key].arn_suffix
#     LoadBalancer = module.alb.arn_suffix
#   }
# }
#
# # Composite Alarm for Critical Services
# resource "aws_cloudwatch_composite_alarm" "critical_services" {
#   alarm_name        = "${local.name}-critical-services"
#   alarm_description = "Composite alarm for critical infrastructure services"
#
#   alarm_rule = join(" OR ", [
#     "ALARM(${local.name}-redis-cpu)",
#     "ALARM(${local.name}-redis-memory)",
#     "ALARM(${local.name}-efs-burst-credits)",
#     "ALARM(${local.name}-alb-5xx)"
#   ])
#
#   alarm_actions = var.alarm_actions
#   tags         = local.tags
# }