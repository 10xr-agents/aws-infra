# modules/security/main.tf

data "aws_caller_identity" "current" {}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from specific IP ranges"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-alb-sg" })
}

resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-eks-cluster-sg" })
}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-eks-nodes-sg"
  description = "Security group for EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Allow traffic from EKS cluster"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Allow ICE/UDP traffic"
    from_port       = 49152
    to_port         = 65535
    protocol        = "udp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Allow TURN/UDP traffic"
    from_port       = 3478
    to_port         = 3478
    protocol        = "udp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Allow TURN/TLS traffic"
    from_port       = 3478
    to_port         = 3478
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-eks-nodes-sg" })
}

# Add a new security group for the NLB
resource "aws_security_group" "nlb" {
  name        = "${var.project_name}-nlb-sg"
  description = "Security group for Network Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow ICE/UDP traffic"
    from_port   = 49152
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow TURN/UDP traffic"
    from_port   = 3478
    to_port     = 3478
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow TURN/TLS traffic"
    from_port   = 3478
    to_port     = 3478
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-nlb-sg" })
}


resource "aws_security_group_rule" "cluster_to_nodes" {
  security_group_id        = aws_security_group.eks_cluster.id
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "nodes_to_cluster" {
  security_group_id        = aws_security_group.eks_nodes.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  source_security_group_id = aws_security_group.eks_cluster.id
}

resource "aws_security_group_rule" "cluster_ingress_node_https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "node_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

# IAM Roles and Policies
resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, { Name = "${var.project_name}-eks-cluster-role" })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-eks-nodes-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, { Name = "${var.project_name}-eks-nodes-role" })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy" "eks_nodes_additional" {
  name = "${var.project_name}-eks-nodes-additional-policy"
  role = aws_iam_role.eks_nodes.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "route53:ChangeResourceRecordSets"  # Add permission for External DNS
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" : var.aws_region
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_access" {
  name = "${var.project_name}-s3-access"
  role = aws_iam_role.eks_nodes.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = [
        var.s3_bucket_arn,
        "${var.s3_bucket_arn}/*"
      ]
    }]
  })
}

# GuardDuty
resource "aws_guardduty_detector" "main" {
  count = var.enable_guardduty ? 1 : 0

  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = merge(var.tags, { Name = "${var.project_name}-guardduty" })
}

resource "aws_guardduty_organization_configuration" "main" {
  count = var.enable_guardduty && var.is_organization_master ? 1 : 0

  detector_id                      = aws_guardduty_detector.main[0].id
  auto_enable_organization_members = "ALL"

  datasources {
    s3_logs {
      auto_enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          auto_enable = true
        }
      }
    }
  }
}

# Security Hub
resource "aws_securityhub_account" "main" {
  count = var.enable_security_hub ? 1 : 0
}

resource "aws_securityhub_standards_subscription" "cis" {
  count         = var.enable_security_hub ? 1 : 0
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on    = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  count         = var.enable_security_hub ? 1 : 0
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.main]
}

# AWS Config
resource "aws_config_configuration_recorder" "main" {
  count    = var.enable_config ? 1 : 0
  name     = "${var.project_name}-config-recorder"
  role_arn = aws_iam_role.config_role[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role" "config_role" {
  count = var.enable_config ? 1 : 0
  name  = "${var.project_name}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "config.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, { Name = "${var.project_name}-config-role" })
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  count      = var.enable_config ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
  role       = aws_iam_role.config_role[0].name
}

resource "aws_config_config_rule" "instances_in_vpc" {
  count = var.enable_config ? 1 : 0
  name  = "instances-in-vpc"

  source {
    owner             = "AWS"
    source_identifier = "INSTANCES_IN_VPC"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_iam_role" "ssm_role" {
  count = var.enable_config ? 1 : 0
  name  = "${var.project_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ssm.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, { Name = "${var.project_name}-ssm-role" })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  count      = var.enable_config ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
  role       = aws_iam_role.ssm_role[0].name
}

resource "aws_config_remediation_configuration" "instances_in_vpc" {
  count            = var.enable_config ? 1 : 0
  config_rule_name = aws_config_config_rule.instances_in_vpc[0].name
  target_type      = "SSM_DOCUMENT"
  target_id        = "AWS-StopEC2Instance"

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.ssm_role[0].arn
  }

  parameter {
    name           = "InstanceId"
    resource_value = "RESOURCE_ID"
  }

  automatic                  = true
  maximum_automatic_attempts = 5
  retry_attempt_seconds      = 60
}

# Add a new IAM policy for ALB Ingress Controller
resource "aws_iam_policy" "alb_ingress" {
  name        = "${var.project_name}-alb-ingress-policy"
  path        = "/"
  description = "IAM policy for ALB Ingress Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:GetCertificate",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeTags",
          "ec2:DescribeVpcs",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:RevokeSecurityGroupIngress",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:RemoveTags",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:SetWebAcl",
          "iam:CreateServiceLinkedRole",
          "iam:GetServerCertificate",
          "iam:ListServerCertificates",
          "waf-regional:GetWebACLForResource",
          "waf-regional:GetWebACL",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "tag:GetResources",
          "tag:TagResources",
          "waf:GetWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:DescribeProtection",
          "shield:GetSubscriptionState",
          "shield:DeleteProtection",
          "shield:CreateProtection",
          "shield:DescribeSubscription",
          "shield:ListProtections"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach ALB Ingress policy to EKS nodes role
resource "aws_iam_role_policy_attachment" "alb_ingress" {
  policy_arn = aws_iam_policy.alb_ingress.arn
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch_role.arn

  tags = var.tags
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "${var.project_name}-cloudtrail-logs"
  force_destroy = true

  tags = var.tags
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project_name}"
  retention_in_days = 30

  tags = var.tags
}

resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name = "${var.project_name}-cloudtrail-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_policy" {
  name = "${var.project_name}-cloudtrail-cloudwatch-policy"
  role = aws_iam_role.cloudtrail_cloudwatch_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# Add CloudWatch logs for security groups
resource "aws_cloudwatch_log_group" "security_groups" {
  name              = "/aws/security-groups/${var.project_name}"
  retention_in_days = 30

  tags = var.tags
}

# Update IAM roles to include more detailed logging
resource "aws_iam_role_policy_attachment" "cloudwatch_logs_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  role       = aws_iam_role.eks_cluster.name
}
