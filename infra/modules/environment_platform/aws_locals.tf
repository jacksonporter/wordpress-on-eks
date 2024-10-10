locals {
  private_subnet_for_each = {
    for index, az_suffix in var.private_subnet_az_suffix_list : "${index}-${az_suffix}" => {
      index     = index,
      az_suffix = az_suffix,
    }
  }

  public_subnet_for_each = {
    for index, az_suffix in var.public_subnet_az_suffix_list : "${index}-${az_suffix}" => {
      index     = index,
      az_suffix = az_suffix,
    }
  }

  public_subnet_key_by_azs = {
    for az_suffix in distinct([
      for _, k in local.public_subnet_for_each : k.az_suffix
      ]) : az_suffix => [
      for l, m in local.public_subnet_for_each : l
      if az_suffix == m.az_suffix
    ]
  }

  cluster_name           = "${var.environment}-${data.aws_region.current.name}"
  irsa_sub_condition_key = "${replace(aws_iam_openid_connect_provider.irsa.url, "https://", "")}:sub"
  cluster_log_group_name = "/aws/eks/${local.cluster_name}/cluster"
}
