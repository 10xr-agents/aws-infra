# environments/qa/providers.tf

provider "aws" {
  region = var.region
}

# Kubernetes provider configuration (for EKS)
# This will be used after the EKS cluster is created
provider "kubernetes" {
  host                   = var.enable_eks ? module.eks[0].cluster_endpoint : ""
  cluster_ca_certificate = var.enable_eks ? base64decode(module.eks[0].cluster_certificate_authority_data) : null

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.enable_eks ? module.eks[0].cluster_name : ""]
  }

  # Only configure if EKS is enabled
  dynamic "ignore_annotations" {
    for_each = var.enable_eks ? [1] : []
    content {
      "*" = true
    }
  }
}

# Helm provider configuration (for EKS)
# This will be used to deploy Helm charts to EKS
provider "helm" {
  kubernetes {
    host                   = var.enable_eks ? module.eks[0].cluster_endpoint : ""
    cluster_ca_certificate = var.enable_eks ? base64decode(module.eks[0].cluster_certificate_authority_data) : null

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.enable_eks ? module.eks[0].cluster_name : ""]
    }
  }
}

# Kubectl provider for applying Kubernetes manifests directly
provider "kubectl" {
  host                   = var.enable_eks ? module.eks[0].cluster_endpoint : ""
  cluster_ca_certificate = var.enable_eks ? base64decode(module.eks[0].cluster_certificate_authority_data) : null
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.enable_eks ? module.eks[0].cluster_name : ""]
  }
}