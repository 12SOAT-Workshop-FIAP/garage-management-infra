provider "aws" {
  region = var.aws_region
}

variable "s3_bucket_name" {
  description = "Nome do bucket S3 para o estado do Terraform"
  type        = string
  default     = "garagemanagement-terraform-backend"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.s3_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "garagemanagement-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"               
  hash_key     = "LockID"                         

  attribute {
    name = "LockID"
    type = "S"
  }
}