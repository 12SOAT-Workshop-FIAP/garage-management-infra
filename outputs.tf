output "eks_cluster_endpoint" {
  description = "Endpoint do servidor da API do Kubernetes para conexão via kubectl"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "Nome do cluster EKS criado"
  value       = module.eks.cluster_name
}

output "ecr_repository_url" {
  description = "URL do repositorio ECR principal."
  value       = module.ecr.repository_url
}

output "ecr_microservice_urls" {
  description = "URLs dos repositórios ECR dos microserviços."
  value       = module.ecr.microservice_repository_urls
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas para o RDS."
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas (necessário para acesso externo ao RDS)."
  value       = module.vpc.public_subnet_ids
}

output "rds_security_group_id" {
  description = "ID do Security Group do RDS (criado pelo módulo security)."
  value       = module.security.rds_sg_id
}