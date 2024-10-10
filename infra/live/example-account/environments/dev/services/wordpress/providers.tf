provider "aws" {
  region = var.primary_region

  default_tags {
    tags = local.default_aws_tags
  }
}

data "aws_eks_cluster_auth" "current" {
  name = data.aws_eks_cluster.environment_region.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.environment_region.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.environment_region.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.current.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.environment_region.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.environment_region.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.current.token
  }
}
