variable "repository_name" {
  description = "Nome do repositório ECR principal"
  type        = string
}

variable "microservice_names" {
  description = "Nomes dos repositórios ECR dos microserviços"
  type        = list(string)
  default     = []
}
