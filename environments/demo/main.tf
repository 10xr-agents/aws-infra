# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.64.0" # Use the latest version
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


module "vpc" {
  source = "../../modules/vpc"

  region               = var.region
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
  sns_topic_arn        = aws_sns_topic.alerts.arn

  tags = var.tags
}

module "security" {
  source = "../../modules/security"

  project_name  = var.project_name
  vpc_id        = module.vpc.vpc_id
  aws_region    = var.region
  s3_bucket_arn = aws_s3_bucket.main.arn
  tags          = var.tags
}

module "networking" {
  source = "../../modules/networking"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  acm_certificate_arn   = var.acm_certificate_arn
  sns_topic_arn         = aws_sns_topic.alerts.arn
  tags                  = var.tags
}

module "s3" {
  source = "../../modules/s3"

  bucket_name = "${var.project_name}-bucket"
  tags        = var.tags
}

module "eks" {
  source = "../../modules/eks"

  project_name    = var.project_name
  cluster_version = var.eks_cluster_version
  subnet_ids      = module.vpc.private_subnet_ids # Use only private subnets for worker nodes
  node_groups = {
    general = {
      name           = "general"
      desired_size   = 2
      max_size       = 4
      min_size       = 2
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      subnet_ids     = module.vpc.private_subnet_ids # Explicitly set subnet IDs for this node group
      labels = {
        "node-group" = "general"
      }
    },
    cpu_optimized = {
      name           = "cpu-optimized"
      desired_size   = 2
      max_size       = 4
      min_size       = 2
      instance_types = ["c5.large"]
      capacity_type  = "ON_DEMAND"
      subnet_ids     = module.vpc.private_subnet_ids # Explicitly set subnet IDs for this node group
      labels = {
        "node-group" = "cpu-optimized"
      }
    },
    spot = {
      name           = "spot"
      desired_size   = 1
      max_size       = 3
      min_size       = 0
      instance_types = ["t3.small", "t3.medium"]
      capacity_type  = "SPOT"
      subnet_ids     = module.vpc.private_subnet_ids # Explicitly set subnet IDs for this node group
      labels = {
        "node-group" = "spot"
      }
    }
  }
  public_access_cidrs = var.eks_public_access_cidrs
  s3_bucket_arn       = aws_s3_bucket.main.arn

  eks_cluster_role_arn = module.security.eks_cluster_role_arn
  eks_node_role_arn    = module.security.eks_nodes_role_arn
  eks_cluster_sg_id    = module.security.eks_nodes_security_group_id

  tags = var.tags
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