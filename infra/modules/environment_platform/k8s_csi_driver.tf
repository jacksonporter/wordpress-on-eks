resource "kubernetes_csi_driver_v1" "efs" { # Adding manually instead of through installation of CSI driver, as we are using fargate (EFS CSI comes built-in on fargate nodes)
  metadata {
    name = "efs.csi.aws.com"
  }
  spec {
    attach_required = false
    volume_lifecycle_modes = [
      "Persistent"
    ]
  }
}
