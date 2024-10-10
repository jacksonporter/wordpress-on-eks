resource "aws_security_group" "default" {
  name   = "${var.name}-db-sg"
  vpc_id = local.vpc_ids[0]
}

resource "aws_vpc_security_group_ingress_rule" "default_incoming_security_group_ids" {
  for_each = toset(var.incoming_security_group_ids)

  security_group_id = aws_security_group.default.id

  referenced_security_group_id = each.value
  from_port                    = var.port
  ip_protocol                  = "tcp"
  to_port                      = var.port
}

resource "aws_vpc_security_group_egress_rule" "default_all_ipv4" {
  security_group_id = aws_security_group.default.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = -1
  ip_protocol = "-1"
  to_port     = -1
}

resource "aws_vpc_security_group_egress_rule" "default_all_ipv6" {
  security_group_id = aws_security_group.default.id

  cidr_ipv6   = "::/0"
  from_port   = -1
  ip_protocol = "-1"
  to_port     = -1
}
