resource "aws_db_subnet_group" "environment_private" {
  name       = "${var.environment}-private"
  subnet_ids = [for subnet in aws_subnet.private : subnet.id]

  tags = {
    Name = "${var.environment}-private"
  }
}
