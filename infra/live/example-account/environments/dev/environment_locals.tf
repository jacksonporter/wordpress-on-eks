locals {
  environment = "dev"

  environment_tags = {
    environment = local.environment
  }
}
