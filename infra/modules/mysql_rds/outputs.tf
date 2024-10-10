output "master_username" {
  value = aws_db_instance.this.username
}

output "master_password_secret_arn" {
  value     = aws_db_instance.this.master_user_secret.0.secret_arn
  sensitive = true
}

output "port" {
  value = aws_db_instance.this.port
}

output "host" {
  value = split(":", aws_db_instance.this.endpoint)[0]
}
