# modules/ecs/listeners.tf - Dynamic Environment-Aware Version

locals {
  # Define environment-specific domains
  environment_domains = {
    qa = {
      voice_agent        = "agents.qa.10xr.co"
      livekit_proxy     = "proxy.qa.10xr.co"
      agent_analytics   = "analytics.qa.10xr.co"
      agentic_services  = "api.qa.10xr.co"
      ui_console        = ["qa.10xr.co", "ui.qa.10xr.co"]
      automation_service = "automation.qa.10xr.co"
    }
    prod = {
      voice_agent        = "agents.prod.10xr.co"
      livekit_proxy     = "proxy.prod.10xr.co"
      agent_analytics   = "analytics.prod.10xr.co"
      agentic_services  = "api.prod.10xr.co"
      ui_console        = ["prod.10xr.co", "ui.prod.10xr.co", "app.10xr.co"]
      automation_service = "automation.prod.10xr.co"
    }
  }

  # Get current environment domains
  current_domains = local.environment_domains[var.environment]
}

# HTTP Host-based routing rule for voice-agent
resource "aws_lb_listener_rule" "voice_agent_http_host_rule" {
  count = var.create_alb ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["voice-agent"].arn
  }

  condition {
    host_header {
      values = [local.current_domains.voice_agent]
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-voice-agent-http-host-rule"
    Service   = "voice-agent"
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.http,
    aws_lb_target_group.service
  ]
}

# HTTPS Host-based routing rule for voice-agent
resource "aws_lb_listener_rule" "voice_agent_https_host_rule" {
  count = var.create_alb ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["voice-agent"].arn
  }

  condition {
    host_header {
      values = [local.current_domains.voice_agent]
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-voice-agent-https-host-rule"
    Service   = "voice-agent"
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.https,
    aws_lb_target_group.service
  ]
}

# HTTP Host-based routing rule for livekit-proxy
resource "aws_lb_listener_rule" "livekit_proxy_http_host_rule" {
  count = var.create_alb ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 102

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["livekit-proxy"].arn
  }

  condition {
    host_header {
      values = [local.current_domains.livekit_proxy]
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-livekit-proxy-http-host-rule"
    Service   = "livekit-proxy"
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.http,
    aws_lb_target_group.service
  ]
}

# HTTPS Host-based routing rule for livekit-proxy
resource "aws_lb_listener_rule" "livekit_proxy_https_host_rule" {
  count = var.create_alb ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 102

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["livekit-proxy"].arn
  }

  condition {
    host_header {
      values = [local.current_domains.livekit_proxy]
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-livekit-proxy-https-host-rule"
    Service   = "livekit-proxy"
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.https,
    aws_lb_target_group.service
  ]
}

# HTTP Host-based routing rule for agent-analytics
resource "aws_lb_listener_rule" "agent_analytics_http_host_rule" {
  count = var.create_alb ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 103

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["agent-analytics"].arn
  }

  condition {
    host_header {
      values = [local.current_domains.agent_analytics]
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-agent-analytics-http-host-rule"
    Service   = "agent-analytics"
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.http,
    aws_lb_target_group.service
  ]
}

# HTTPS Host-based routing rule for agent-analytics
resource "aws_lb_listener_rule" "agent_analytics_https_host_rule" {
  count = var.create_alb ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 103

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["agent-analytics"].arn
  }

  condition {
    host_header {
      values = [local.current_domains.agent_analytics]
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-agent-analytics-https-host-rule"
    Service   = "agent-analytics"
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.https,
    aws_lb_target_group.service
  ]
}

# HTTP Host-based routing rule for agentic-services (THE IMPORTANT ONE)
resource "aws_lb_listener_rule" "agentic_services_http_host_rule" {
  count = var.create_alb ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 104

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["agentic-services"].arn
  }

  condition {
    host_header {
      values = [local.current_domains.agentic_services]
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-agentic-services-http-host-rule"
    Service   = "agentic-services"
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.http,
    aws_lb_target_group.service
  ]
}

# HTTPS Host-based routing rule for agentic-services (THE IMPORTANT ONE)
resource "aws_lb_listener_rule" "agentic_services_https_host_rule" {
  count = var.create_alb ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 104

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["agentic-services"].arn
  }

  condition {
    host_header {
      values = [local.current_domains.agentic_services]
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-agentic-services-https-host-rule"
    Service   = "agentic-services"
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.https,
    aws_lb_target_group.service
  ]
}

# HTTP Host-based routing rule for ui-console
resource "aws_lb_listener_rule" "ui_console_http_host_rule" {
  count = var.create_alb ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 105

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["ui-console"].arn
  }

  condition {
    host_header {
      values = local.current_domains.ui_console
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-ui-console-http-host-rule"
    Service   = "ui-console"
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.http,
    aws_lb_target_group.service
  ]
}

# HTTPS Host-based routing rule for ui-console
resource "aws_lb_listener_rule" "ui_console_https_host_rule" {
  count = var.create_alb ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 105

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["ui-console"].arn
  }

  condition {
    host_header {
      values = local.current_domains.ui_console
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-ui-console-https-host-rule"
    Service   = "ui-console"
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.https,
    aws_lb_target_group.service
  ]
}

# HTTP Host-based routing rule for automation-service-mcp
resource "aws_lb_listener_rule" "automation_service_mcp_http_host_rule" {
  count = var.create_alb ? 1 : 0

  listener_arn = aws_lb_listener.http[0].arn
  priority     = 106

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["automation-service-mcp"].arn
  }

  condition {
    host_header {
      values = [local.current_domains.automation_service]
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-automation-service-mcp-http-host-rule"
    Service   = "automation-service-mcp"
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.http,
    aws_lb_target_group.service
  ]
}

# HTTPS Host-based routing rule for automation-service-mcp
resource "aws_lb_listener_rule" "automation_service_mcp_https_host_rule" {
  count = var.create_alb ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 106

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["automation-service-mcp"].arn
  }

  condition {
    host_header {
      values = [local.current_domains.automation_service]
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-automation-service-mcp-https-host-rule"
    Service   = "automation-service-mcp"
    Component = "ListenerRule"
  })

  depends_on = [
    aws_lb_listener.https,
    aws_lb_target_group.service
  ]
}