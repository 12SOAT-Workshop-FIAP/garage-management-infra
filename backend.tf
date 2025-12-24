terraform {
  backend "s3" {
    bucket         = "garagemanagement-terraform-backend-1" 
    key            = "garage-management-infra/terraform.tfstate"
    region         = "us-east-1"

    dynamodb_table = "garagemanagement-terraform-locks"
    encrypt        = true
  }
}