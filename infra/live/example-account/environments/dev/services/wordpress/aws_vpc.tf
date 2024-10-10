resource "aws_security_group" "efs" {
  name   = "${local.service_name}-efs-sg"
  vpc_id = data.aws_vpc.selected.id
}

resource "aws_vpc_security_group_ingress_rule" "efs_incoming_security_group_ids" {
  for_each = toset([
    data.aws_eks_cluster.environment_region.vpc_config.0.cluster_security_group_id
  ])

  security_group_id = aws_security_group.efs.id

  referenced_security_group_id = each.value
  from_port                    = -1
  ip_protocol                  = "-1"
  to_port                      = -1
}

resource "aws_vpc_security_group_egress_rule" "efs_all_ipv4" {
  security_group_id = aws_security_group.efs.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = -1
  ip_protocol = "-1"
  to_port     = -1
}

resource "aws_vpc_security_group_egress_rule" "efs_all_ipv6" {
  security_group_id = aws_security_group.efs.id

  cidr_ipv6   = "::/0"
  from_port   = -1
  ip_protocol = "-1"
  to_port     = -1
}
