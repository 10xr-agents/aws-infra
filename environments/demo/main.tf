# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.64.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.5"
    }
  }
}

terraform {
  cloud {
    organization = "10xR"
    workspaces {
      name = "default-aws-infra-demo-us-east-1"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}


module "vpc" {
  source = "../../modules/vpc"

  region               = var.region
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = slice(var.availability_zones, 0, 2)  # Use only first 2 AZs
  public_subnet_cidrs  = slice(var.public_subnet_cidrs, 0, 2)  # Use only first 2 public subnets
  private_subnet_cidrs = slice(var.private_subnet_cidrs, 0, 2)  # Use only first 2 private subnets
  single_nat_gateway   = var.single_nat_gateway
  sns_topic_arn        = aws_sns_topic.alerts.arn

  tags = var.tags
}

module "security" {
  source = "../../modules/security"

  project_name        = var.project_name
  vpc_id              = module.vpc.vpc_id
  aws_region          = var.region
  s3_bucket_arn       = aws_s3_bucket.main.arn
  sns_topic_arn       = aws_sns_topic.alerts.arn
  tags                = var.tags
  enable_cloudtrail   = false
  enable_security_hub = false
  enable_guardduty    = true
  enable_config       = false

  # Add rules for ICE/UDP, ICE/TCP, TURN/TLS, TURN/UDP
#   additional_security_group_rules = [
#     {
#       type        = "ingress"
#       from_port   = 3478
#       to_port     = 3478
#       protocol    = "udp"
#       cidr_blocks = ["0.0.0.0/0"]
#       description = "TURN/UDP"
#     },
#     {
#       type        = "ingress"
#       from_port   = 3478
#       to_port     = 3478
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#       description = "TURN/TLS"
#     },
#     {
#       type        = "ingress"
#       from_port   = 49152
#       to_port     = 65535
#       protocol    = "udp"
#       cidr_blocks = ["0.0.0.0/0"]
#       description = "ICE/UDP port range"
#     },
#     {
#       type        = "ingress"
#       from_port   = 443
#       to_port     = 443
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#       description = "ICE/TCP"
#     }
#   ]
}

module "s3" {
  source = "../../modules/s3"

  bucket_name = "${var.project_name}-bucket"
  tags        = var.tags
}


module "networking" {
  source = "../../modules/networking"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  nlb_security_group_id = module.security.nlb_security_group_id
  acm_certificate_arn   = var.acm_certificate_arn
  sns_topic_arn         = aws_sns_topic.alerts.arn
  vpc_flow_log_role_id = module.vpc.vpc_flow_log_id
  vpc_flow_log_role_arn = module.vpc.vpc_flow_log_arn
  tags                  = var.tags

  # Add NLB configuration
#   create_nlb            = true
#   nlb_internal          = false
#   nlb_subnet_ids        = module.vpc.public_subnet_ids
#   nlb_target_groups     = [
#     {
#       name        = "ice-udp-tg"
#       port        = 3478
#       protocol    = "UDP"
#       target_type = "ip"
#     },
#     {
#       name        = "turn-tls-tg"
#       port        = 3478
#       protocol    = "TCP"
#       target_type = "ip"
#     }
#   ]
  eks_cluster_sg_id = module.eks.cluster_security_group_id
}

module "eks" {
  source = "../../modules/eks"

  project_name    = var.project_name
  cluster_version = var.eks_cluster_version
  subnet_ids      = module.vpc.private_subnet_ids
  node_groups     = var.eks_node_groups
  public_access_cidrs = var.eks_public_access_cidrs
  s3_bucket_arn       = aws_s3_bucket.main.arn

  eks_cluster_role_arn  = module.security.eks_cluster_role_arn
  eks_node_role_arn     = module.security.eks_nodes_role_arn
  eks_cluster_sg_id     = module.security.eks_nodes_security_group_id
  default_instance_type = "t3.medium"

  tags   = var.tags
  vpc_id = module.vpc.vpc_id
}


resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_s3_bucket" "main" {
  bucket = var.project_name

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "main_logs" {
  bucket = "${var.project_name}-logs"

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "main_logs" {
  bucket = aws_s3_bucket.main_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "main_logs" {
  bucket = aws_s3_bucket.main_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "kubernetes_secret" "mongodb_secret" {
  metadata {
    name = "mongodb-secret"
  }

  data = {
    connection_string = var.mongodb_connection_string
  }

  type = "Opaque"

  depends_on = [module.eks]
}

# Add CloudWatch dashboard for overall monitoring
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EKS", "cluster_failed_node_count", "ClusterName", module.eks.cluster_name],
            [".", "cluster_node_count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "EKS Node Count"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Usage", "ResourceCount", "Type", "Resource", "Resource", "OnDemand", "Service", "EC2"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "EC2 Instance Count"
        }
      }
    ]
  })
}

# Add CloudWatch alarms for critical components
resource "aws_cloudwatch_metric_alarm" "eks_node_count" {
  alarm_name          = "${var.project_name}-eks-node-count"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "cluster_node_count"
  namespace           = "AWS/EKS"
  period              = "300"
  statistic           = "Average"
  threshold           = "2"
  alarm_description   = "This metric monitors the number of EKS nodes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = module.eks.cluster_name
  }
}

resource "aws_cloudwatch_metric_alarm" "eks_failed_node_count" {
  alarm_name          = "${var.project_name}-eks-failed-node-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "cluster_failed_node_count"
  namespace           = "AWS/EKS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors the number of failed EKS nodes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = module.eks.cluster_name
  }
}