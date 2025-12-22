# modules/ecs/listeners.tf - Dynamic Listener Rules Based on Services

################################################################################
# Local Variables for Listener Rules
################################################################################

locals {
  # Filter services that have load balancer enabled and host headers defined
  services_with_host_headers = {
    for name, config in var.services : name => config
    if try(config.enable_load_balancer, true) && length(coalesce(try(config.alb_host_headers, []), [])) > 0
  }

  # Generate priority map for services (starting at 101 to leave room for defaults)
  service_priorities = {
    for idx, name in keys(local.services_with_host_headers) : name => 101 + idx
  }
}

################################################################################
# Dynamic HTTP Host-based Listener Rules
################################################################################

resource "aws_lb_listener_rule" "service_http_host_rule" {
  for_each = var.create_alb ? local.services_with_host_headers : {}

  listener_arn = aws_lb_listener.http[0].arn
  priority     = local.service_priorities[each.key]

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  condition {
    host_header {
      values = each.value.alb_host_headers
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-${each.key}-http-host-rule"
    Service   = each.key
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.http,
    aws_lb_target_group.service
  ]
}

################################################################################
# Dynamic HTTPS Host-based Listener Rules
################################################################################

resource "aws_lb_listener_rule" "service_https_host_rule" {
  for_each = var.create_alb && var.enable_https ? local.services_with_host_headers : {}

  listener_arn = aws_lb_listener.https[0].arn
  priority     = local.service_priorities[each.key]

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  condition {
    host_header {
      values = each.value.alb_host_headers
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-${each.key}-https-host-rule"
    Service   = each.key
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.https,
    aws_lb_target_group.service
  ]
}

################################################################################
# Dynamic Path-based Listener Rules (Optional)
################################################################################

locals {
  # Filter services that have path patterns defined
  services_with_path_patterns = {
    for name, config in var.services : name => config
    if try(config.enable_load_balancer, true) && length(coalesce(try(config.alb_path_patterns, []), [])) > 0
  }

  # Generate priority map for path-based rules (starting at 201)
  path_service_priorities = {
    for idx, name in keys(local.services_with_path_patterns) : name => 201 + idx
  }
}

resource "aws_lb_listener_rule" "service_http_path_rule" {
  for_each = var.create_alb ? local.services_with_path_patterns : {}

  listener_arn = aws_lb_listener.http[0].arn
  priority     = local.path_service_priorities[each.key]

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value.alb_path_patterns
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-${each.key}-http-path-rule"
    Service   = each.key
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.http,
    aws_lb_target_group.service
  ]
}

resource "aws_lb_listener_rule" "service_https_path_rule" {
  for_each = var.create_alb && var.enable_https ? local.services_with_path_patterns : {}

  listener_arn = aws_lb_listener.https[0].arn
  priority     = local.path_service_priorities[each.key]

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value.alb_path_patterns
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-${each.key}-https-path-rule"
    Service   = each.key
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.https,
    aws_lb_target_group.service
  ]
}
