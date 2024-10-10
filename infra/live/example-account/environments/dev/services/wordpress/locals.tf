locals {
  default_aws_tags = merge(
    local.account_tags,
    local.environment_tags,
    {
      region = var.primary_region,
    }
  )

  service_name = basename(abspath(path.module))
}
