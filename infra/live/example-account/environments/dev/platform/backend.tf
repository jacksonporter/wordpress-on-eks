terraform {
  backend "s3" {
    bucket         = "example-account.terraform.tfstate"                                                           # change this to the appropriate S3 bucket name
    key            = "github/jacksonporter/wordpress-on-eks/infra/live/example-account/platform/terraform.tfstate" # change this to use your GitHub (or other) repository path and account name
    region         = "us-west-1"                                                                                   # change this to the bucket's region
    dynamodb_table = "example-account.terraform.tfstate-lock"                                                      # change this to the appropriate DynamoDB table name
  }
}
