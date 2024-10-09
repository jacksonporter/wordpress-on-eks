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

provider "kubernetes" {
  host                   = module.environment_platform.cluster_endpoint
  cluster_ca_certificate = module.environment_platform.base64_decoded_cluster_ca_certificate
  token                  = module.environment_platform._cluster_auth_token
}

provider "helm" {
  kubernetes {
    host                   = module.environment_platform.cluster_endpoint
    cluster_ca_certificate = module.environment_platform.base64_decoded_cluster_ca_certificate
    token                  = module.environment_platform._cluster_auth_token
  }
}
