# modules/eks/variables.tf

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "node_groups" {
  description = "Map of EKS node group configurations"
  type = map(object({
    desired_size   = number
    max_size       = number
    min_size       = number
    instance_types = list(string)
    capacity_type  = string
    labels         = map(string)
  }))
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket to grant access to"
  type        = string
}

variable "eks_cluster_role_arn" {
  type = string
}

variable "eks_node_role_arn" {
  type = string
}

variable "eks_cluster_sg_id" {
  type = string
}

variable "default_instance_type" {
  type = string
}

variable "alb_controller_version" {
  description = "Version of the AWS Load Balancer Controller Helm chart"
  type        = string
  default     = "1.4.1"
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will be created"
  type        = string
}

variable "map_additional_iam_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap"
  type        = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "map_additional_iam_users" {
  description = "Additional IAM users to add to the aws-auth configmap"
  type        = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
