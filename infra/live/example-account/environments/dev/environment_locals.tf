locals {
  environment = "dev"

  environment_tags = {
    environment = local.environment
  }

  default_region_ipv4_cidr_block = "10.0.0.0/20"
}
