terraform {
  backend "s3" {
    bucket = "garagemanagement-terraform-backend-2"
    key    = "garage-management-infra/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "garagemanagement-terraform-locks"
    encrypt        = true
  }
}