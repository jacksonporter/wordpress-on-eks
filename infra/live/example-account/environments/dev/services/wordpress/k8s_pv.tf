resource "kubernetes_persistent_volume_v1" "efs_wordpress" {
  metadata {
    name = "${local.environment}-efs-wordpress-pv"
    labels = {
      environment = local.environment,
      name        = "${local.environment}-efs-wordpress-pv"
    }
  }
  spec {
    volume_mode = "Filesystem"
    capacity = {
      storage = "5Gi"
    }
    access_modes                     = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = "${aws_efs_file_system.wordpress.id}::${aws_efs_access_point.wordpress.id}"
      }
    }
    storage_class_name = "efs"
  }

  depends_on = [
    aws_efs_mount_target.wordpress,
  ]
}
