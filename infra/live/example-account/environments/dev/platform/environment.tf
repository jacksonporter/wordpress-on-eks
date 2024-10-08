module "environment_platform" {
  source = "../../../../../modules/environment_platform"

  account_name = local.account_name
  environment  = local.environment

  vpc_ipv4_cidr_block = local.default_region_ipv4_cidr_block
}
