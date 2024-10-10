resource "kubernetes_storage_class_v1" "efs" {
  metadata {
    name = "efs"
  }
  storage_provisioner = kubernetes_csi_driver_v1.efs.metadata.0.name
}
