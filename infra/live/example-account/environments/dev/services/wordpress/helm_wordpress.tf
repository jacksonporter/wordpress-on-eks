resource "helm_release" "wordpress" {
  name      = "wordpress"
  namespace = "default"

  chart = "oci://registry-1.docker.io/bitnamicharts/wordpress"

  values = [
    yamlencode({
      mariadb = {
        enabled = false
      },
      externalDatabase = {
        host = module.mysql_rds.host,
        port = module.mysql_rds.port,
        /*
        TODO: move to a non master username/password (after we figure out to to provision DB inside private network)
        */
        user     = module.mysql_rds.master_username,
        password = jsondecode(data.aws_secretsmanager_secret_version.master_db_password.secret_string)["password"],
        database = "main",
      },
      persistence = {
        enabled       = false # TODO: come back and fix this wth EFS
        existingClaim = kubernetes_persistent_volume_claim_v1.efs_wordpress.metadata.0.name
      },
      tolerations = [
        {
          key      = "eks.amazonaws.com/compute-type",
          operator = "Equal",
          value    = "fargate",
          effect   = "NoSchedule",
        },
      ],
      service = {
        type = "ClusterIP",
      },
      ingress = {
        enabled          = true,
        ingressClassName = "nginx",
        hostname         = "wordpress.us-west-1.dev.jacksonporterjp.com"
      }
    })
  ]
}
