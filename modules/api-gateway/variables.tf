variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Subnets privadas onde o ALB Interno será criado."
}

variable "lambda_auth_arn" {
  type        = string
  description = "ARN da função Lambda de autenticação."
}

variable "eks_cluster_name" {
  type        = string
  description = "Nome do cluster EKS para encontrar os nodes."
}

variable "alb_security_group_id" {
  type        = string
  description = "ID do Security Group que será usado pelo ALB Interno."
}

variable "app_node_port" {
  type        = number
  description = "Porta do NodePort definida no serviço K8s principal (ex: 31000)."
}

variable "os_node_port" {
  type        = number
  description = "Porta do NodePort do os-service (ex: 31001)."
}

variable "billing_node_port" {
  type        = number
  description = "Porta do NodePort do billing-service (ex: 31002)."
}

variable "execution_node_port" {
  type        = number
  description = "Porta do NodePort do execution-service (ex: 31003)."
}

