output "repository_url" {
  value = aws_ecr_repository.main.repository_url
}

output "microservice_repository_urls" {
  description = "URLs dos repositórios ECR dos microserviços"
  value = {
    for name, repo in aws_ecr_repository.microservices : name => repo.repository_url
  }
}
