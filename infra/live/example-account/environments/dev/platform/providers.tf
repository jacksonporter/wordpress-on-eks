provider "aws" {
  region = var.primary_region

  default_tags {
    tags = merge(
      local.account_tags,
      local.environment_tags,
      {
        region = var.primary_region,
      }
    )
  }
}
