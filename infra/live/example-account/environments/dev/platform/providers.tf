provider "aws" {
  region = var.primary_region

  default_tags {
    tags = local.default_aws_tags
  }
}

data "aws_eks_cluster_auth" "current" {
  name = module.environment_platform.cluster_name
}

provider "kubernetes" {
  host                   = module.environment_platform.cluster_endpoint
  cluster_ca_certificate = module.environment_platform.base64_decoded_cluster_ca_certificate
  token                  = data.aws_eks_cluster_auth.current.token
}

provider "helm" {
  kubernetes {
    host                   = module.environment_platform.cluster_endpoint
    cluster_ca_certificate = module.environment_platform.base64_decoded_cluster_ca_certificate
    token                  = data.aws_eks_cluster_auth.current.token
  }
}
