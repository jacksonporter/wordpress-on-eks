locals {
  ingress_nginx_additional_labels = {
    computeType = "Fargate"
  }
}


resource "helm_release" "ingress_nginx" {
  name      = "ingress-nginx"
  namespace = kubernetes_namespace.ingress.metadata.0.name

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  values = [
    yamlencode({
      commonLabels = merge( # applied to all resources
        local.ingress_nginx_additional_labels,
      ),
      controller = {
        service = {
          type = "NodePort"
          ipFamilies = [
            "IPv6"
          ]
        }
      }
    })
  ]

  depends_on = [
    aws_eks_fargate_profile.ingress_nginx
  ]
}

locals {
  ingress_nginx_alb_ingress_annotations = {
    "kubernetes.io/ingress.class"                  = local.aws_lb_controller_ingress_class_name, # this creates an ALB
    "alb.ingress.kubernetes.io/scheme"             = "internet-facing",
    "alb.ingress.kubernetes.io/ip-address-type"    = "dualstack",
    "alb.ingress.kubernetes.io/target-type"        = "ip" # required for Fargate & IPv6
    "alb.ingress.kubernetes.io/load-balancer-name" = "${aws_eks_cluster.this.name}-ingress-nginx-alb",
    "alb.ingress.kubernetes.io/security-groups" = join(" ,", [
      aws_security_group.public_lb_sg.id
    ]),
    "alb.ingress.kubernetes.io/listen-ports" = jsonencode([
      { HTTP = 80 },
      { HTTPS = 443 },
    ]),
    "alb.ingress.kubernetes.io/certificate-arn" = aws_acm_certificate.environment_region.arn,
    "alb.ingress.kubernetes.io/ssl-redirect"    = "443",
    "alb.ingress.kubernetes.io/tags" = join(",", [for k, v in merge(
      var.lb_base_tags,
    ) : "${k}=${v}"]),
  }
}

resource "kubernetes_ingress_v1" "ingress_nginx_alb_ingress" {
  metadata {
    name        = "ingress-nginx-alb"
    namespace   = helm_release.ingress_nginx.namespace
    annotations = local.ingress_nginx_alb_ingress_annotations
    labels = merge(
      local.ingress_nginx_additional_labels,
      {
        app = "ingress-nginx"
      },
    )
  }

  spec {
    ingress_class_name = local.aws_lb_controller_ingress_class_name # this creates an ALB
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "${helm_release.ingress_nginx.name}-controller" # see chart logic for specifics
              port {
                number = 80 # we do HTTP from ALB --> nginx controller service
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    aws_acm_certificate_validation.environment_region
  ]
}

resource "time_sleep" "wait_after_ingress_alb_creation" {
  triggers = merge(
    local.ingress_nginx_alb_ingress_annotations,
  )

  create_duration = "60s"

  depends_on = [kubernetes_ingress_v1.ingress_nginx_alb_ingress]
}

data "aws_lb" "ingress_nginx_alb_ingress" {
  name = kubernetes_ingress_v1.ingress_nginx_alb_ingress.metadata.0.annotations["alb.ingress.kubernetes.io/load-balancer-name"]

  depends_on = [
    time_sleep.wait_after_ingress_alb_creation
  ]
}
