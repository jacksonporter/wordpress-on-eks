data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_db_subnet_group" "selected" {
  name = "${var.environment}-private"
}

data "aws_subnet" "selected" {
  for_each = toset(data.aws_db_subnet_group.selected.subnet_ids)
  id       = each.value
}
