output "s3_bucket_name" {
  description = "Nome do bucket S3 criado para o backend."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB criada para o lock."
  value       = aws_dynamodb_table.terraform_locks.name
}