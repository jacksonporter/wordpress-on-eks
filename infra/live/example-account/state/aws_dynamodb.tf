resource "aws_dynamodb_table" "state" {
  name         = "${aws_s3_bucket.state.bucket}-lock"
  billing_mode = "PAY_PER_REQUEST" # can change to PROVISIONED IF SPENDING TOO MUCH
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "${aws_s3_bucket.state.bucket}-lock"
    Environment = "production"
  }
}
