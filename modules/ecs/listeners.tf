# modules/ecs/voice-agent-listener-rules.tf

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
      values = ["agents.qa.10xr.co"]
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

# HTTPS Host-based routing rule for voice-agent (if SSL certificate provided)
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
      values = ["agents.qa.10xr.co"]
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

# modules/ecs/livekit-proxy-listener-rules.tf

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
      values = ["proxy.qa.10xr.co"]
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

# HTTPS Host-based routing rule for livekit-proxy (if SSL certificate provided)
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
      values = ["proxy.qa.10xr.co"]
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

# modules/ecs/agent-analytics-listener-rules.tf

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
      values = ["analytics.qa.10xr.co"]
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

# HTTPS Host-based routing rule for agent-analytics (if SSL certificate provided)
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
      values = ["analytics.qa.10xr.co"]
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

# modules/ecs/agentic-services-listener-rules.tf

# HTTP Host-based routing rule for agentic-services
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
      values = ["api.qa.10xr.co"]
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

# HTTPS Host-based routing rule for agentic-services (if SSL certificate provided)
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
      values = ["api.qa.10xr.co"]
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

# modules/ecs/ui-console-listener-rules.tf

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
      values = ["qa.10xr.co", "ui.qa.10xr.co"]
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

# HTTPS Host-based routing rule for ui-console (if SSL certificate provided)
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
      values = ["qa.10xr.co", "ui.qa.10xr.co"]
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