resource "aws_efs_file_system" "wordpress" {
  creation_token = "${local.environment}-wordpress"
}

resource "aws_efs_mount_target" "wordpress" {
  for_each = toset(data.aws_subnets.private_selected.ids)

  file_system_id = aws_efs_file_system.wordpress.id
  subnet_id      = each.value
  security_groups = [
    aws_security_group.efs.id
  ]
}

resource "aws_efs_access_point" "wordpress" {
  file_system_id = aws_efs_file_system.wordpress.id

  posix_user {
    uid = 1001
    gid = 1001
  }
}
