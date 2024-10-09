module "environment_platform" {
  source = "../../../../../modules/environment_platform"

  account_name = local.account_name
  environment  = local.environment

  vpc_ipv4_cidr_block   = local.default_region_ipv4_cidr_block
  lb_base_tags          = local.default_aws_tags
  base_domain_zone_name = var.base_domain_zone_name
}
