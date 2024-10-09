resource "aws_eks_cluster" "this" {
  name                          = local.cluster_name
  role_arn                      = aws_iam_role.cluster_role.arn
  version                       = "1.31"
  enabled_cluster_log_types     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  bootstrap_self_managed_addons = false

  access_config {
    authentication_mode                         = "API" # newest, easiest to work with
    bootstrap_cluster_creator_admin_permissions = true
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.cluster_resource_encryption.arn
    }
    resources = [
      "secrets"
    ]
  }

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs = [
      "0.0.0.0/0"
    ]
    subnet_ids = [
      for subnet in aws_subnet.private : subnet.id
    ]
  }

  kubernetes_network_config {
    ip_family = "ipv6" # newest standard! ;)
  }

  upgrade_policy {
    support_type = "STANDARD"
  }

  depends_on = [
    aws_cloudwatch_log_group.cluster,
    aws_iam_role_policy_attachment.cluster_role_cluster_policy,
    aws_iam_role_policy_attachment.cluster_role_vpc_resource_controller,
  ]
}

/*
Fargate Profiles
*/

resource "aws_eks_fargate_profile" "coredns" {
  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "core-dns"
  pod_execution_role_arn = aws_iam_role.shared_fargate_profile.arn
  subnet_ids = [
    for subnet in aws_subnet.private : subnet.id
  ]

  selector {
    namespace = "kube-system"
    labels = {
      k8s-app = "kube-dns"
    }
  }
}

resource "aws_eks_fargate_profile" "amazon_cloudwatch_observability" {
  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "amazon-cloudwatch-observability"
  pod_execution_role_arn = aws_iam_role.shared_fargate_profile.arn
  subnet_ids = [
    for subnet in aws_subnet.private : subnet.id
  ]

  selector {
    namespace = "amazon-cloudwatch"
    labels = {
      "app.kubernetes.io/name" = "amazon-cloudwatch-observability"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.shared_fargate_profile-AmazonEKSFargatePodExecutionRolePolicy
  ]
}

resource "aws_eks_fargate_profile" "aws_lb_controller" {
  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "aws-lb-controller"
  pod_execution_role_arn = aws_iam_role.shared_fargate_profile.arn
  subnet_ids = [
    for subnet in aws_subnet.private : subnet.id
  ]

  selector {
    namespace = local.aws_lb_controller_namespace
    labels = merge(
      local.aws_lb_controller_fargate_labels,
    )
  }

  depends_on = [
    aws_iam_role_policy_attachment.shared_fargate_profile-AmazonEKSFargatePodExecutionRolePolicy
  ]
}

resource "aws_eks_fargate_profile" "ingress_nginx" {
  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "ingress-nginx"
  pod_execution_role_arn = aws_iam_role.shared_fargate_profile.arn
  subnet_ids = [
    for subnet in aws_subnet.private : subnet.id
  ]

  selector {
    namespace = kubernetes_namespace.ingress.metadata.0.name
    labels = merge(
      local.ingress_nginx_additional_labels,
    )
  }

  depends_on = [
    aws_iam_role_policy_attachment.shared_fargate_profile-AmazonEKSFargatePodExecutionRolePolicy
  ]
}

/*
Addons
*/

resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "vpc-cni"
  service_account_role_arn = aws_iam_role.vpc_cni.arn

  depends_on = [
    aws_iam_role_policy_attachment.vpc_cni_ipv4,
    aws_iam_role_policy.vpc_cni_ipv6_policy
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"
  configuration_values = jsonencode({
    computeType = "Fargate"
  })

  depends_on = [
    aws_eks_fargate_profile.coredns
  ]
}

resource "aws_eks_addon" "eks_pod_identity_agent" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "eks-pod-identity-agent"
}

resource "aws_eks_addon" "amazon_cloudwatch_observability" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "amazon-cloudwatch-observability"

  depends_on = [
    aws_eks_fargate_profile.amazon_cloudwatch_observability
  ]
}
