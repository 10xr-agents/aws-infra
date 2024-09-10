# eks cluster for livekit
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids         = aws_subnet.public[*].id
    security_group_ids = [aws_security_group.eks_cluster.id]
  }

  access_config {
    authentication_mode                         = "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSVPCResourceController,
  ]
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_pod_identity_webhook" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_PodIdentityWebHook"
  role       = aws_iam_role.eks_cluster.name
}

# EKS Node Groups
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 2
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEC2ContainerRegistryReadOnly,
  ]
}

# EKS Node IAM Role
resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# IAM Role for LiveKit Pods
resource "aws_iam_role" "livekit_pods_role" {
  name = "${var.project_name}-livekit-pods-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity",
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        },
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:${kubernetes_namespace.livekit.metadata[0].name}:livekit-service-account"
          }
        }
      }
    ]
  })
}

# IAM Policy for LiveKit Pods
resource "aws_iam_policy" "livekit_pods_policy" {
  name        = "${var.project_name}-livekit-pods-policy"
  description = "IAM policy for LiveKit pods to access AWS services"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "elasticache:DescribeReplicationGroups",
          "elasticache:DescribeCacheClusters",
          "elasticache:ListTagsForResource",
          "sts:AssumeRole",
          "sts:AssumeRoleWithWebIdentity",
          "sts:GetCallerIdentity",
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "livekit_pods_policy_attachment" {
  policy_arn = aws_iam_policy.livekit_pods_policy.arn
  role       = aws_iam_role.livekit_pods_role.name
}

# Kubernetes Service Account for LiveKit
resource "kubernetes_service_account" "livekit_service_account" {
  metadata {
    name      = "livekit-service-account"
    namespace = kubernetes_namespace.livekit.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.livekit_pods_role.arn
    }
  }
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-gw-${count.index + 1}"
  }
}

resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  }
}

# Network Load Balancer
resource "aws_lb" "nlb" {
  name               = "${var.project_name}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-nlb"
  }
}

# NLB Target Group for LiveKit
resource "aws_lb_target_group" "livekit" {
  name        = "${var.project_name}-livekit-tg"
  port        = 7880
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    protocol = "HTTP"
    path     = "/health"
    port     = "traffic-port"
  }
}

# NLB Listener for LiveKit
resource "aws_lb_listener" "livekit" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 7880
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.livekit.arn
  }
}

# NLB Listener for HTTP traffic
resource "aws_lb_listener" "nlb_http" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.livekit_http.arn
  }
}

resource "aws_lb_listener" "nlb_https" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 443
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.nlb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.livekit_https.arn
  }
}

# NLB Listener for WebRTC traffic
resource "aws_lb_listener" "nlb_webrtc" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 7882
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.livekit_webrtc.arn
  }
}

resource "aws_lb_listener" "livekit_rtmp" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 1935
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.livekit_rtmp.arn
  }
}

resource "aws_lb_listener" "livekit_whip" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 8080
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.livekit_whip.arn
  }
}

# NLB Target Group for HTTP traffic
resource "aws_lb_target_group" "livekit_http" {
  name        = "${var.project_name}-livekit-http"
  port        = 7880
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/health"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
}

# NLB Target Group for HTTPS traffic
resource "aws_lb_target_group" "livekit_https" {
  name        = "${var.project_name}-livekit-https"
  port        = 7880
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "HTTPS"
    path                = "/health"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
}

# NLB Target Group for WebRTC traffic
resource "aws_lb_target_group" "livekit_webrtc" {
  name        = "${var.project_name}-livekit-webrtc"
  port        = 7882
  protocol    = "UDP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = 7880
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
}

resource "aws_lb_target_group" "livekit_rtmp" {
  name        = "${var.project_name}-livekit-rtmp"
  port        = 1935
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
}

resource "aws_lb_target_group" "livekit_whip" {
  name        = "${var.project_name}-livekit-whip"
  port        = 8080
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/health"
    port                = "7888"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
}

# Security Group for EKS
# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow inbound traffic from NLB"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Allow inbound HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound LiveKit traffic"
    from_port   = 7880
    to_port     = 7882
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound LiveKit RTC traffic"
    from_port   = 40000
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound LiveKit TURN traffic"
    from_port   = 3478
    to_port     = 3478
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound LiveKit TURN TLS traffic"
    from_port   = 5349
    to_port     = 5349
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound LiveKit RTMP traffic"
    from_port   = 1935
    to_port     = 1935
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound LiveKit WHIP traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-eks-cluster-sg"
  }
}

# Helm provider
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
      command     = "aws"
    }
  }
}

# Kubernetes provider
provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
    command     = "aws"
  }
}

provider "kubectl" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
    command     = "aws"
  }
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(
      [
        {
          rolearn  = aws_iam_role.eks_nodes.arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups   = ["system:bootstrappers", "system:nodes"]
        },
      ]
    )
    mapUsers = yamlencode(
      [
        {
          userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          username = "root"
          groups   = ["system:masters"]
        },
        {
          userarn  = data.aws_caller_identity.current.arn
          username = "creator"
          groups   = ["system:masters"]
        }
      ]
    )
  }

  depends_on = [aws_iam_role.eks_nodes]
}

# Helm LiveKit provider

# Create a namespace for LiveKit
resource "kubernetes_namespace" "livekit" {
  metadata {
    name = "livekit"
  }
}

resource "random_password" "livekit_api_secret" {
  length  = 256
  special = false
}

# Add CoreDNS add-on
resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "coredns"
  addon_version = "v1.11.3-eksbuild.1"

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSVPCResourceController
  ]
}

# Add kube-proxy add-on
resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "kube-proxy"
  addon_version = "v1.30.3-eksbuild.2"

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSVPCResourceController
  ]
}

# Add vpc-cni add-on
resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "vpc-cni"
  addon_version = "v1.18.3-eksbuild.2"

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSVPCResourceController
  ]
}


# LiveKit Helm Chart
# LiveKit Server Helm Chart
# resource "kubernetes_service" "livekit_udp_range" {
#   metadata {
#     name      = "livekit-udp-range"
#     namespace = kubernetes_namespace.livekit.metadata[0].name
#   }
#
#   spec {
#     selector = {
#       app = "livekit-server"
#     }
#
#     // Dynamic block to iterate over a range of ports
#     dynamic "port" {
#       for_each = range(40000, 65535) # Loop from 40000 to 65535 (60001 is exclusive)
#
#       content {
#         name        = "udp-${port.value}"
#         port        = port.value
#         target_port = port.value
#         protocol    = "UDP"
#       }
#     }
#
#     type                    = "NodePort"
#     external_traffic_policy = "Local"
#   }
# }

resource "helm_release" "livekit_server" {
  name       = "livekit-server"
  repository = "https://helm.livekit.io"
  chart      = "livekit-server"
  namespace  = kubernetes_namespace.livekit.metadata[0].name

  values = [
    templatefile("${path.module}/templates/livekit-server-values.yaml", {
      livekit_api_key          = var.livekit_api_key
      livekit_api_secret       = random_password.livekit_api_secret.result
      livekit_turn_domain_name = var.livekit_turn_domain_name
      aws_redis_cluster        = "${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"
      livekit_redis_username   = "default"
      livekit_redis_password   = random_password.redis_auth_token.result
      livekit_secret_name      = kubernetes_secret.tls_cert.metadata[0].name
      acm_certificate_arn      = aws_acm_certificate.nlb.arn
      livekit_pods_role        = aws_iam_role.livekit_pods_role.arn
    })
  ]

  depends_on = [aws_eks_node_group.main, helm_release.aws_load_balancer_controller]
}

# LiveKit Ingress Helm Chart
resource "helm_release" "livekit_ingress" {
  name       = "livekit-ingress"
  repository = "https://helm.livekit.io"
  chart      = "ingress"
  namespace  = kubernetes_namespace.livekit.metadata[0].name

  values = [
    templatefile("${path.module}/templates/livekit-ingress-values.yaml", {
      livekit_api_key        = var.livekit_api_key
      livekit_api_secret     = random_password.livekit_api_secret.result
      livekit_domain_name    = var.livekit_domain_name
      aws_redis_cluster      = "${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"
      livekit_redis_username = "default"
      livekit_redis_password = random_password.redis_auth_token.result
      livekit_secret_name    = kubernetes_secret.tls_cert.metadata[0].name
      livekit_pods_role      = aws_iam_role.livekit_pods_role.arn
    })
  ]

  depends_on = [helm_release.livekit_server]
}

# LiveKit Egress Helm Chart
resource "helm_release" "livekit_egress" {
  name       = "livekit-egress"
  repository = "https://helm.livekit.io"
  chart      = "egress"
  namespace  = kubernetes_namespace.livekit.metadata[0].name

  values = [
    templatefile("${path.module}/templates/livekit-egress-values.yaml", {
      livekit_api_key        = var.livekit_api_key
      livekit_api_secret     = random_password.livekit_api_secret.result
      livekit_domain_name    = var.livekit_domain_name
      aws_redis_cluster      = "${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"
      livekit_redis_username = "default"
      livekit_redis_password = random_password.redis_auth_token.result
      livekit_secret_name    = kubernetes_secret.tls_cert.metadata[0].name
      livekit_pods_role      = aws_iam_role.livekit_pods_role.arn
    })
  ]

  depends_on = [helm_release.livekit_server]
}

# ALB Ingress Controller
# Helm release for AWS Load Balancer Controller
# AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  namespace        = "kube-system"
  create_namespace = true
  version          = "1.8.2"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.eks_nodes.arn
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = aws_vpc.main.id
  }

  set {
    name  = "enableShield"
    value = "false"
  }

  set {
    name  = "enableWaf"
    value = "false"
  }

  set {
    name  = "enableWafv2"
    value = "false"
  }

  timeout = 900 # 15 minutes

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main,
    kubernetes_config_map.aws_auth
  ]
}

resource "null_resource" "wait_for_alb_controller" {
  triggers = {
    helm_release = helm_release.aws_load_balancer_controller.id
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
    KUBECONFIG_FILE=$(mktemp)
    aws eks get-token --cluster-name ${aws_eks_cluster.main.name} | kubectl config view --raw -o yaml | sed 's/''/''/g' > $KUBECONFIG_FILE
    kubectl --kubeconfig $KUBECONFIG_FILE wait --for=condition=available --timeout=900s deployment/aws-load-balancer-controller -n kube-system
    rm $KUBECONFIG_FILE
  EOT
  }

  depends_on = [helm_release.aws_load_balancer_controller]
}

# Install Metrics Server using Helm
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.11.0" # Ensure this version is compatible with your Kubernetes version

  set {
    name  = "args[0]"
    value = "--kubelet-preferred-address-types=InternalIP"
  }

  set {
    name  = "args[1]"
    value = "--kubelet-insecure-tls"
  }

  depends_on = [aws_eks_cluster.main]
}

# IAM Policy for ALB Ingress Controller
resource "aws_iam_policy" "alb_ingress_controller" {
  name        = "${var.project_name}-alb-ingress-controller"
  path        = "/"
  description = "IAM policy for ALB Ingress Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = "arn:aws:ec2:*:*:security-group/*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "CreateSecurityGroup"
          }
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "arn:aws:ec2:*:*:security-group/*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ]
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]
        Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the ALB Ingress Controller policy to the EKS node role
resource "aws_iam_role_policy_attachment" "alb_ingress_controller" {
  policy_arn = aws_iam_policy.alb_ingress_controller.arn
  role       = aws_iam_role.eks_nodes.name
}

# Create an ElastiCache subnet group
resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-${var.project_name}-subnet-group"
  subnet_ids = aws_subnet.public[*].id
}

# If you don't already have a CloudWatch log group, create one
resource "aws_cloudwatch_log_group" "redis_logs" {
  name              = "/aws/elasticache/${var.project_name}-redis"
  retention_in_days = 30 # Adjust retention period as needed
}


# Redis Security Group
resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Security group for Redis cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
    description     = "Allow inbound Redis traffic from EKS cluster"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

# Add this rule to allow EKS to access Redis
resource "aws_security_group_rule" "eks_to_redis" {
  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.redis.id
  security_group_id        = aws_security_group.eks_cluster.id
  description              = "Allow outbound traffic from EKS to Redis"
}

# Create the ElastiCache Redis cluster
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "redis-${var.project_name}"
  description                = "Redis cluster for ${var.project_name}"
  node_type                  = "cache.t3.micro"
  num_cache_clusters         = 2
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  automatic_failover_enabled = true

  engine               = "redis"
  engine_version       = "7.1"
  parameter_group_name = "default.redis7"

  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth_token.result

  # Enable logging
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_logs.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_logs.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  # Important: Apply changes immediately
  apply_immediately = true
}

resource "aws_vpc_endpoint" "elasticache" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.elasticache"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.eks_cluster.id]
  subnet_ids         = aws_subnet.public[*].id

  private_dns_enabled = true
}

# Generate a random auth token for Redis
resource "random_password" "redis_auth_token" {
  length  = 32
  special = false
}

# Create an IAM role for EKS pods to access Redis
resource "aws_iam_role" "eks_redis_access" {
  name = "${var.project_name}-eks-redis-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# Create an IAM policy for Redis access
resource "aws_iam_policy" "redis_access" {
  name        = "${var.project_name}-redis-access-policy"
  description = "IAM policy for Redis access from EKS pods"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticache:DescribeReplicationGroups",
          "elasticache:DescribeCacheClusters",
          "elasticache:ListTagsForResource"
        ]
        Resource = aws_elasticache_replication_group.redis.arn
      }
    ]
  })
}

# Attach the Redis access policy to the EKS Redis access role
resource "aws_iam_role_policy_attachment" "eks_redis_access" {
  policy_arn = aws_iam_policy.redis_access.arn
  role       = aws_iam_role.eks_redis_access.name
}

# Update the EKS node role to allow assuming the Redis access role
resource "aws_iam_role_policy_attachment" "eks_node_redis_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

# Create a Kubernetes secret for Redis credentials
resource "kubernetes_secret" "redis_credentials" {
  metadata {
    name      = "redis-credentials"
    namespace = kubernetes_namespace.livekit.metadata[0].name
  }

  data = {
    host     = aws_elasticache_replication_group.redis.primary_endpoint_address
    port     = "6379"
    password = random_password.redis_auth_token.result
  }
}

# Generate a private key
resource "tls_private_key" "cert_private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create a self-signed certificate
resource "tls_self_signed_cert" "cert" {
  private_key_pem = tls_private_key.cert_private_key.private_key_pem

  subject {
    common_name  = "*.${var.domain_name}"
    organization = var.project_name
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Create a Kubernetes secret for the certificate
resource "kubernetes_secret" "tls_cert" {
  metadata {
    name      = "${var.project_name}-tls-cert"
    namespace = kubernetes_namespace.livekit.metadata[0].name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.cert.cert_pem
    "tls.key" = tls_private_key.cert_private_key.private_key_pem
  }
}

# ELB for ALB & NLB
# Cloudflare DNS record for NLB
resource "cloudflare_record" "nlb_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "livekit.${var.environment}"
  content = aws_lb.nlb.dns_name
  type    = "CNAME"
  proxied = false
}