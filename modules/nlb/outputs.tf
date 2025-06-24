# modules/nlb/outputs.tf

output "turn_nlb_id" {
  description = "The ID of the TURN NLB"
  value       = var.create_turn_nlb ? aws_lb.turn[0].id : null
}

output "turn_nlb_arn" {
  description = "The ARN of the TURN NLB"
  value       = var.create_turn_nlb ? aws_lb.turn[0].arn : null
}

output "turn_nlb_dns_name" {
  description = "The DNS name of the TURN NLB"
  value       = var.create_turn_nlb ? aws_lb.turn[0].dns_name : null
}

output "turn_nlb_zone_id" {
  description = "The canonical hosted zone ID of the TURN NLB"
  value       = var.create_turn_nlb ? aws_lb.turn[0].zone_id : null
}

output "turn_target_group_arns" {
  description = "Map of TURN target group ARNs"
  value       = { for k, v in aws_lb_target_group.turn : k => v.arn }
}

output "sip_nlb_id" {
  description = "The ID of the SIP NLB"
  value       = var.create_sip_nlb ? aws_lb.sip[0].id : null
}

output "sip_nlb_arn" {
  description = "The ARN of the SIP NLB"
  value       = var.create_sip_nlb ? aws_lb.sip[0].arn : null
}

output "sip_nlb_dns_name" {
  description = "The DNS name of the SIP NLB"
  value       = var.create_sip_nlb ? aws_lb.sip[0].dns_name : null
}

output "sip_nlb_zone_id" {
  description = "The canonical hosted zone ID of the SIP NLB"
  value       = var.create_sip_nlb ? aws_lb.sip[0].zone_id : null
}

output "sip_signaling_target_group_arn" {
  description = "The ARN of the SIP signaling target group"
  value       = var.create_sip_nlb ? aws_lb_target_group.sip_signaling[0].arn : null
}

output "nlb_security_group_id" {
  description = "The ID of the NLB security group"
  value       = aws_security_group.nlb.id
}