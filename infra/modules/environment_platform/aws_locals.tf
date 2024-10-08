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
}
