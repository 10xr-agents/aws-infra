# modules/storage-ecs/main.tf (Updated for ECS + EKS)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.97.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }
  }
}

/**
 * # Unified Storage Module for ECS + EKS
 *
 * This module creates storage resources that can be used by both ECS and EKS:
 * - EFS for shared persistent storage (accessible by both platforms)
 * - S3 bucket for recordings and assets
 * - Kubernetes storage classes (for EKS)
 * - IAM roles and policies for both platforms
 */

# Get current AWS region
data "aws_region" "current" {}

#---------------------------------
# EFS File System (Shared by ECS and EKS)
#---------------------------------
resource "aws_efs_file_system" "main" {
  creation_token   = "${var.cluster_name}-efs"
  performance_mode = var.efs_performance_mode
  throughput_mode  = var.efs_throughput_mode
  
  # Set provisioned throughput if using provisioned mode
  provisioned_throughput_in_mibps = var.efs_throughput_mode == "provisioned" ? var.efs_provisioned_throughput : null
  
  dynamic "lifecycle_policy" {
    for_each = var.enable_efs_lifecycle_policy ? [1] : []
    content {
      transition_to_ia = "AFTER_30_DAYS"
    }
  }

  encrypted = true

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-efs"
      SharedBy = "ECS-EKS"
    }
  )
}

# EFS Mount Targets (accessible by both ECS and EKS)
resource "aws_efs_mount_target" "main" {
  count = length(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Security Group for EFS (allows access from both ECS and EKS)
resource "aws_security_group" "efs" {
  name        = "${var.cluster_name}-efs-sg"
  description = "Security group for EFS mount targets - shared by ECS and EKS"
  vpc_id      = var.vpc_id

  # Allow access from ECS tasks
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
    description     = "NFS from ECS tasks"
  }

  # Allow access from EKS nodes (if EKS is enabled)
  dynamic "ingress" {
    for_each = var.enable_eks ? [1] : []
    content {
      from_port       = 2049
      to_port         = 2049
      protocol        = "tcp"
      security_groups = [var.eks_cluster_security_group_id, var.eks_node_security_group_id]
      description     = "NFS from EKS nodes"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-efs-sg"
      SharedBy = "ECS-EKS"
    }
  )
}

# EFS Access Point for LiveKit (used by both platforms)
resource "aws_efs_access_point" "livekit" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/livekit"
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

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-livekit-ap"
      SharedBy = "ECS-EKS"
    }
  )
}

#---------------------------------
# Kubernetes Storage Classes (for EKS only)
#---------------------------------
# EFS Storage Class for EKS
resource "kubectl_manifest" "storage_class_efs" {
  count = var.enable_eks && var.create_kubernetes_resources ? 1 : 0

  yaml_body = <<YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: ${aws_efs_file_system.main.id}
  directoryPerms: "700"
reclaimPolicy: Retain
volumeBindingMode: Immediate
mountOptions:
  - tls
YAML

  depends_on = [aws_efs_mount_target.main]
}

# GP3 Storage Class for EKS
resource "kubectl_manifest" "storage_class_gp3" {
  count = var.enable_eks && var.create_kubernetes_resources ? 1 : 0

  yaml_body = <<YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "${var.gp3_iops}"
  throughput: "${var.gp3_throughput}"
  encrypted: "true"
  fsType: ext4
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
YAML
}

#---------------------------------
# S3 Bucket for Recordings (Shared by ECS and EKS)
#---------------------------------
resource "aws_s3_bucket" "recordings" {
  count = var.create_recordings_bucket ? 1 : 0

  bucket = var.recordings_bucket_name

  tags = merge(
    var.tags,
    {
      Name = var.recordings_bucket_name
      SharedBy = "ECS-EKS"
    }
  )
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "recordings" {
  count = var.create_recordings_bucket ? 1 : 0

  bucket = aws_s3_bucket.recordings[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "recordings" {
  count = var.create_recordings_bucket ? 1 : 0

  bucket = aws_s3_bucket.recordings[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "recordings" {
  count = var.create_recordings_bucket ? 1 : 0

  bucket = aws_s3_bucket.recordings[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle Policy
resource "aws_s3_bucket_lifecycle_configuration" "recordings" {
  count = var.create_recordings_bucket && var.recordings_expiration_days > 0 ? 1 : 0

  bucket = aws_s3_bucket.recordings[0].id

  rule {
    id     = "expire-old-recordings"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.recordings_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

#---------------------------------
# IAM Roles and Policies
#---------------------------------
# IAM Role for ECS Tasks to access storage
resource "aws_iam_role" "ecs_task" {
  name = "${var.cluster_name}-ecs-task-storage-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for S3 access (used by both ECS and EKS)
resource "aws_iam_policy" "s3_access" {
  count = var.create_recordings_bucket ? 1 : 0

  name        = "${var.cluster_name}-s3-recordings-policy"
  description = "Policy for accessing S3 recordings bucket from ECS and EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.recordings[0].arn,
          "${aws_s3_bucket.recordings[0].arn}/*"
        ]
      }
    ]
  })
}

# Attach S3 policy to ECS task role
resource "aws_iam_role_policy_attachment" "ecs_s3_access" {
  count = var.create_recordings_bucket ? 1 : 0

  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.s3_access[0].arn
}

# IRSA for EKS services to access S3 (if EKS is enabled)
module "eks_s3_irsa" {
  count = var.enable_eks && var.create_recordings_bucket ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-eks-s3-access"

  role_policy_arns = {
    s3_access = aws_iam_policy.s3_access[0].arn
  }

  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["${var.livekit_namespace}:livekit-s3-sa"]
    }
  }

  tags = var.tags
}

# Kubernetes Service Account for S3 access (if EKS is enabled)
resource "kubectl_manifest" "s3_service_account" {
  count = var.enable_eks && var.create_recordings_bucket && var.create_kubernetes_resources ? 1 : 0

  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: livekit-s3-sa
  namespace: ${var.livekit_namespace}
  annotations:
    eks.amazonaws.com/role-arn: ${module.eks_s3_irsa[0].iam_role_arn}
automountServiceAccountToken: true
YAML

  depends_on = [module.eks_s3_irsa]
}

# ConfigMap for storage configuration (if EKS is enabled)
resource "kubectl_manifest" "storage_config" {
  count = var.enable_eks && var.create_kubernetes_resources ? 1 : 0

  yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: livekit-storage-config
  namespace: ${var.livekit_namespace}
data:
  EFS_FILE_SYSTEM_ID: "${aws_efs_file_system.main.id}"
  EFS_ACCESS_POINT_ID: "${aws_efs_access_point.livekit.id}"
  S3_BUCKET: "${var.create_recordings_bucket ? aws_s3_bucket.recordings[0].id : ""}"
  S3_REGION: "${data.aws_region.current.name}"
  STORAGE_CLASS_EFS: "efs"
  STORAGE_CLASS_GP3: "gp3"
YAML

  depends_on = [aws_efs_file_system.main, aws_efs_access_point.livekit]
}