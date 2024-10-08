variable "account_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_ipv4_cidr_block" {
  type    = string
  default = "10.0.0.0/20"
}

variable "public_subnet_az_suffix_list" {
  type    = list(string)
  default = ["a", "c"]
}

variable "public_subnet_ipv4_newbits" {
  type    = number
  default = 4
}

variable "public_subnet_ipv6_newbits" {
  type    = number
  default = 8
}

variable "private_subnet_az_suffix_list" {
  type    = list(string)
  default = ["a", "c"]
}

variable "private_subnet_ipv4_newbits" {
  type    = number
  default = 4
}

variable "private_subnet_ipv6_newbits" {
  type    = number
  default = 8
}
