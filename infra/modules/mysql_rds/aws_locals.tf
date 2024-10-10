locals {
  vpc_ids = distinct([
    for subnet in data.aws_subnet.selected : subnet.vpc_id
  ])
}
