output "repository_urls" {
  description = "URLs dos repositórios ECR"
  value = {
    for name, repo in aws_ecr_repository.repos : name => repo.repository_url
  }
}
