data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}
data "aws_route53_zone" "base" {
  name = var.base_domain_zone_name
}
