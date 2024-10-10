locals {
  aws_lb_controller_service_account_name = "aws-load-balancer-controller"
  aws_lb_controller_chart_version        = "1.9.0"
  aws_lb_controller_app_version          = "2.9.0"
  aws_lb_controller_namespace            = data.kubernetes_namespace.kube_system.metadata.0.name
  aws_lb_controller_fargate_labels = {
    computeType = "fargate",
  }
  aws_lb_controller_ingress_class_name = "alb"
}

data "http" "aws_lb_controller_iam_policy_json" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v${local.aws_lb_controller_app_version}/docs/install/iam_policy.json"

  request_headers = {
    Accept = "application/json"
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Status code invalid"
    }
  }
}

resource "helm_release" "aws_lb_controller" {
  name      = "aws-lb-controller"
  namespace = local.aws_lb_controller_namespace
  version   = local.aws_lb_controller_chart_version

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  set {
    name  = "image.tag"
    value = "v${local.aws_lb_controller_app_version}"
  }

  set {
    name  = "clusterName"
    value = aws_eks_cluster.this.name
  }

  set {
    name  = "region"
    value = data.aws_region.current.name
  }

  set {
    name  = "vpcId"
    value = aws_vpc.this.id
  }

  set {
    name  = "ingressClass"
    value = local.aws_lb_controller_ingress_class_name
  }

  values = [
    yamlencode({
      serviceAccount = {
        create = "true",
        name   = local.aws_lb_controller_service_account_name,
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.aws_lb_controller.arn
        }
      },
      podLabels = merge(
        local.aws_lb_controller_fargate_labels,
      ),
      tolerations = [
        {
          key      = "eks.amazonaws.com/compute-type",
          operator = "Equal",
          value    = "fargate",
          effect   = "NoSchedule",
        },
      ],
    })
  ]

  depends_on = [
    aws_eks_fargate_profile.aws_lb_controller
  ]
}
