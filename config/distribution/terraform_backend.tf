terraform {
  backend "s3" {
    bucket         = "falco-distribution-state-bucket"
    dynamodb_table = "falco-distribution-state-bucket-lock"
    region         = "eu-west-1"
    key            = "terraform.tfstate"
  }
}
