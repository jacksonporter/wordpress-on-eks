data "aws_rds_engine_version" "mysql" {
  engine             = "mysql"
  preferred_versions = ["8.0.39", "8.0.37"]
}

resource "aws_db_instance" "this" {
  identifier                  = var.name
  allocated_storage           = 10
  max_allocated_storage       = 1000
  db_name                     = "main"
  engine                      = "mysql"
  engine_version              = data.aws_rds_engine_version.mysql.version_actual
  instance_class              = "db.t4g.small"
  username                    = random_pet.master_username.id
  manage_master_user_password = true
  parameter_group_name        = "default.mysql${join(".", slice(split(".", data.aws_rds_engine_version.mysql.version_actual), 0, 2))}"
  skip_final_snapshot         = true
  multi_az                    = true
  db_subnet_group_name        = data.aws_db_subnet_group.selected.name
  storage_encrypted           = true
  network_type                = "DUAL"
  copy_tags_to_snapshot       = true
  deletion_protection         = true
  vpc_security_group_ids = [
    aws_security_group.default.id
  ]
  port = var.port
}
