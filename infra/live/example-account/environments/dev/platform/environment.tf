module "environment_platform" {
  source = "../../../../../modules/environment_platform"

  account_name = local.account_name
  environment  = local.environment

  vpc_ipv4_cidr_block = local.default_region_ipv4_cidr_block

  public_subnet_az_suffix_list  = ["a", "c", "a", "c"]
  private_subnet_az_suffix_list = ["a", "c", "a", "c"]
}
