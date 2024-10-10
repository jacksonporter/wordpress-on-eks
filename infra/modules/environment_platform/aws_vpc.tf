/*
Base VPC
*/

resource "aws_vpc" "this" {
  cidr_block                       = var.vpc_ipv4_cidr_block
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames             = true

  tags = {
    Name = "${var.environment}-${data.aws_region.current.name}-vpc"
  }
}

/*
VPC Gateway Endpoints
*/

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  tags = {
    Name = "${var.environment}-${data.aws_region.current.name}-vpc-s3-gateway-endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"

  tags = {
    Name = "${var.environment}-${data.aws_region.current.name}-vpc-dynamodb-gateway-endpoint"
  }
}

/*
Internet Gateways
*/

resource "aws_internet_gateway" "ipv4" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.environment}-${data.aws_region.current.name}-internet-gateway-ipv4",
  }
}

resource "aws_egress_only_internet_gateway" "ipv6" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.environment}-${data.aws_region.current.name}-egress-only-internet-gateway-ipv6",
  }
}


/*
Default Route Table
*/

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ipv4.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.ipv6.id
  }

  tags = {
    Name = "${var.environment}-${data.aws_region.current.name}-default",
  }
}

/*
Public Subnets
*/

resource "aws_subnet" "public" {
  for_each = local.public_subnet_for_each

  vpc_id                          = aws_vpc.this.id
  availability_zone               = "${data.aws_region.current.name}${each.value.az_suffix}"
  cidr_block                      = cidrsubnet(aws_vpc.this.cidr_block, var.public_subnet_ipv4_newbits, length(var.private_subnet_az_suffix_list) + each.value.index)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.this.ipv6_cidr_block, var.public_subnet_ipv6_newbits, length(var.private_subnet_az_suffix_list) + each.value.index)
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true

  tags = {
    Name                     = "${var.environment}-${data.aws_region.current.name}${each.value.az_suffix}-public-${each.value.index}",
    public                   = "yes",
    "kubernetes.io/role/elb" = "1",
  }
}

resource "aws_eip" "nat" {
  for_each = toset(keys(local.public_subnet_key_by_azs))
  domain   = "vpc"
}

resource "aws_nat_gateway" "this" {
  for_each = local.public_subnet_key_by_azs

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.value[0]].id

  tags = {
    Name = "${var.environment}-${data.aws_region.current.name}${each.key}-nat",
  }

  depends_on = [aws_internet_gateway.ipv4]
}

/*
Private Subnets
*/

resource "aws_subnet" "private" {
  for_each = local.private_subnet_for_each

  vpc_id                          = aws_vpc.this.id
  availability_zone               = "${data.aws_region.current.name}${each.value.az_suffix}"
  cidr_block                      = cidrsubnet(aws_vpc.this.cidr_block, var.private_subnet_ipv4_newbits, each.value.index)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.this.ipv6_cidr_block, var.private_subnet_ipv6_newbits, each.value.index)
  assign_ipv6_address_on_creation = true


  tags = {
    Name                              = "${var.environment}-${data.aws_region.current.name}${each.value.az_suffix}-private-${each.value.index}",
    public                            = "no",
    "kubernetes.io/role/internal-elb" = "1",
  }

  depends_on = [
    aws_nat_gateway.this
  ]
}

resource "aws_route_table" "default_private" {
  for_each = toset(keys(local.public_subnet_key_by_azs))

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[each.key].id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.ipv6.id
  }

  tags = {
    Name = "${var.environment}-${data.aws_region.current.name}${each.key}-private",
  }
}

resource "aws_route_table_association" "default_private" {
  for_each = local.private_subnet_for_each

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.default_private[each.value.az_suffix].id
}

/*
Cluster Security Group
*/

resource "aws_vpc_security_group_ingress_rule" "cluster_sg_all_from_public_lb" {
  security_group_id = aws_eks_cluster.this.vpc_config.0.cluster_security_group_id

  referenced_security_group_id = aws_security_group.public_lb_sg.id
  from_port                    = -1
  ip_protocol                  = "-1"
  to_port                      = -1
}

/*
Public LB Security Group
*/

resource "aws_security_group" "public_lb_sg" {
  name   = "${helm_release.ingress_nginx.name}-public-sg"
  vpc_id = aws_vpc.this.id
}

resource "aws_vpc_security_group_ingress_rule" "public_lb_sg_all_ipv4" {
  for_each = toset(["80", "443"])

  security_group_id = aws_security_group.public_lb_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = tonumber(each.value)
  ip_protocol = "tcp"
  to_port     = tonumber(each.value)
}

resource "aws_vpc_security_group_ingress_rule" "public_lb_sg_all_ipv6" {
  for_each = toset(["80", "443"])

  security_group_id = aws_security_group.public_lb_sg.id

  cidr_ipv6   = "::/0"
  from_port   = tonumber(each.value)
  ip_protocol = "tcp"
  to_port     = tonumber(each.value)
}

resource "aws_vpc_security_group_egress_rule" "public_lb_sg_all_ipv4" {
  security_group_id = aws_security_group.public_lb_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = -1
  ip_protocol = "-1"
  to_port     = -1
}

resource "aws_vpc_security_group_egress_rule" "public_lb_sg_all_ipv6" {
  security_group_id = aws_security_group.public_lb_sg.id

  cidr_ipv6   = "::/0"
  from_port   = -1
  ip_protocol = "-1"
  to_port     = -1
}
