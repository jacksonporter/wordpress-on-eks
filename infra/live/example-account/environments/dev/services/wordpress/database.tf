module "mysql_rds" {
  source = "../../../../../../modules/mysql_rds"

  name                  = "${local.environment}-${local.service_name}"
  az_suffixes           = local.default_az_suffixes
  default_database_name = "main"
  environment           = local.environment
  incoming_security_group_ids = [
    data.aws_eks_cluster.environment_region.vpc_config.0.cluster_security_group_id # allows control plane (and importantly, fargate nodes) to access this DB
  ]
}
