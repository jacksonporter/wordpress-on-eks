variable "name" {
  type = string
}

variable "az_suffixes" {
  type = list(string)
}

variable "default_database_name" {
  type = string
}

variable "instance_class" {
  type    = string
  default = "db.t4g.small"
}

variable "environment" {
  type = string
}

variable "port" {
  type    = number
  default = 3306
}

variable "incoming_security_group_ids" {
  type    = list(string)
  default = []
}
