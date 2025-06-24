# modules/nlb/variables.tf

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the NLB"
  type        = list(string)
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection on the NLB"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "Whether to enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "create_turn_nlb" {
  description = "Whether to create NLB for TURN traffic"
  type        = bool
  default     = false
}

variable "turn_ports" {
  description = "Port configuration for TURN traffic"
  type = map(object({
    port                   = number
    protocol               = string
    health_check_port      = optional(number)
    health_check_protocol  = optional(string)
  }))
  default = {
    udp = {
      port     = 3478
      protocol = "UDP"
    }
    tcp = {
      port     = 3480
      protocol = "TCP"
    }
  }
}

variable "create_sip_nlb" {
  description = "Whether to create NLB for SIP traffic"
  type        = bool
  default     = false
}

variable "sip_ports" {
  description = "Port configuration for SIP traffic"
  type = object({
    signaling = object({
      port     = number
      protocol = string
    })
    rtp_start = object({
      port     = number
      protocol = string
    })
    rtp_end = object({
      port     = number
      protocol = string
    })
  })
  default = {
    signaling = {
      port     = 5060
      protocol = "UDP"
    }
    rtp_start = {
      port     = 10000
      protocol = "UDP"
    }
    rtp_end = {
      port     = 20000
      protocol = "UDP"
    }
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

