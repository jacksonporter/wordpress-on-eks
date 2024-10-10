resource "kubernetes_persistent_volume_claim_v1" "efs_wordpress" {
  metadata {
    name = "${local.environment}-efs-wordpress-pvc"
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "efs"
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    selector {
      match_labels = merge(
        kubernetes_persistent_volume_v1.efs_wordpress.metadata.0.labels
      )
    }
  }

  depends_on = [
    kubernetes_persistent_volume_v1.efs_wordpress
  ]
}
