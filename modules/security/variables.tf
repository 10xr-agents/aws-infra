# modules/security/variables.tf

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "allowed_cidr_blocks" {
  description = "A list of ip blocks/sets"
  type = list(string)
  default     = ["0.0.0.0/0"]
}