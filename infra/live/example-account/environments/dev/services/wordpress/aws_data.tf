data "aws_region" "current" {}

data "aws_eks_cluster" "environment_region" {
  name = "${local.environment}-${data.aws_region.current.name}"
}

data "aws_secretsmanager_secret_version" "master_db_password" {
  secret_id = module.mysql_rds.master_password_secret_arn
}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["${local.environment}-${data.aws_region.current.name}-vpc"]
  }
}

data "aws_subnets" "private_selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:public"
    values = ["yes"]
  }
}

data "aws_route53_zone" "this" {
  name = "${data.aws_region.current.name}.${local.environment}.${var.base_domain_zone_name}"
}
