module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "~> 1.6.5"

  name = "${local.name}-efs"

  # Mount targets / security groups
  mount_targets = { for k, v in zipmap(
    module.vpc.azs,
    module.vpc.private_subnets
  ) : k => { subnet_id = v } }

  security_group_description = "${local.name} EFS security group"
  security_group_vpc_id     = module.vpc.vpc_id
  security_group_rules = {
    ecs = {
      description              = "Allow ECS tasks to access EFS"
      source_security_group_id = aws_security_group.ecs_sg.id
    }
  }

  # File system policy
  attach_policy = true
  policy_statements = [
    {
      sid    = "AllowECSAccess"
      effect = "Allow"
      actions = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite"
      ]
      principals = [{
        type = "AWS"
        identifiers = ["*"]
      }]
      conditions = [{
        test     = "Bool"
        variable = "aws:SecureTransport"
        values   = ["true"]
      }]
    }
  ]

  # Backup policy
  enable_backup_policy = true

  # Lifecycle policy
  lifecycle_policy = {
    transition_to_ia = "AFTER_30_DAYS"
  }

  # Performance mode
  performance_mode = "generalPurpose"

  # Throughput mode
  throughput_mode = "bursting"

  tags = local.tags
}

# Create EFS Access Points for each service
resource "aws_efs_access_point" "service" {
  count = length(var.services)

  file_system_id = module.efs.id

  root_directory {
    path = "/${var.services[count.index].name}"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  posix_user {
    gid = 1000
    uid = 1000
  }

  tags = merge(local.tags, {
    Name = "${local.name}-${var.services[count.index].name}"
  })
}

# Create CloudWatch alarms for EFS
resource "aws_cloudwatch_metric_alarm" "efs_burst_credit_balance" {
  alarm_name          = "${local.name}-efs-burst-credits"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "BurstCreditBalance"
  namespace           = "AWS/EFS"
  period              = "300"
  statistic           = "Average"
  threshold           = "50000000000" # 50 GB
  alarm_description   = "This metric monitors EFS burst credit balance"
  alarm_actions       = var.alarm_actions

  dimensions = {
    FileSystemId = module.efs.id
  }

  tags = local.tags
}