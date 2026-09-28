terraform {
  backend "s3" {
    bucket         = "binaitech-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "binaitech-terraform-locks"
    encrypt        = true
  }
}
