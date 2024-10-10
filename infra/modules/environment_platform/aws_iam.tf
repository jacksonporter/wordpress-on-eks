/*
Cluster Role
*/

data "aws_iam_policy_document" "cluster_role_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster_role" {
  name = "${var.environment}-cluster-role"
  path = "/eks/cluster/"

  assume_role_policy = data.aws_iam_policy_document.cluster_role_assume_role.json
}

resource "aws_iam_role_policy_attachment" "cluster_role_cluster_policy" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_role_vpc_resource_controller" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

/*
IRSA (IAM Roles for Service Accounts)
*/

data "tls_certificate" "irsa" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "irsa" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [for cert in data.tls_certificate.irsa.certificates : cert.sha1_fingerprint]
  url             = data.tls_certificate.irsa.url
}

/*
Shared Fargate Profile
*/

data "aws_iam_policy_document" "shared_fargate_profile_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "shared_fargate_profile" {
  name = "${local.cluster_name}-shared-fargate-profile"
  path = "/eks/cluster/workers/fargate/"

  assume_role_policy = data.aws_iam_policy_document.shared_fargate_profile_assume_role.json
}

resource "aws_iam_role_policy_attachment" "shared_fargate_profile-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.shared_fargate_profile.name
}

/*
VPC CNI
*/
data "aws_iam_policy_document" "vpc_cni_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = local.irsa_sub_condition_key
      values   = ["system:serviceaccount:kube-system:aws-node"] # Default Deployment Namespace/Service Account name for VPC CNI
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.irsa.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "vpc_cni" {
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_assume_role_policy.json
  name               = "${local.cluster_name}-vpc_cni"
  path               = "/eks/cluster/irsa/"
}

resource "aws_iam_role_policy_attachment" "vpc_cni_ipv4" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

data "aws_iam_policy_document" "vpc_cni_ipv6_policy" {
  statement {
    actions = [
      "ec2:AssignIpv6Addresses",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeInstanceTypes"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "ec2:CreateTags"
    ]
    resources = [
      "arn:aws:ec2:*:*:network-interface/*"
    ]
  }
}

resource "aws_iam_role_policy" "vpc_cni_ipv6_policy" {
  name = "ipv6-vpc-cni"
  role = aws_iam_role.vpc_cni.id

  policy = data.aws_iam_policy_document.vpc_cni_ipv6_policy.json
}

/*
AWS LB Controller
*/

data "aws_iam_policy_document" "aws_lb_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = local.irsa_sub_condition_key
      values   = ["system:serviceaccount:${local.aws_lb_controller_namespace}:${local.aws_lb_controller_service_account_name}"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.irsa.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "aws_lb_controller" {
  assume_role_policy = data.aws_iam_policy_document.aws_lb_controller_assume_role_policy.json
  name               = "${local.cluster_name}-aws-lb-controller"
  path               = "/eks/cluster/irsa/"
}

resource "aws_iam_role_policy" "github_provided_policy" {
  name = "github-provided-policy"
  role = aws_iam_role.aws_lb_controller.id

  policy = data.http.aws_lb_controller_iam_policy_json.response_body
}
