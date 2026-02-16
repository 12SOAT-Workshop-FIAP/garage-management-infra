variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "garagemanagement"
}

variable "cluster_availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "app_node_port" {
  description = "Porta do NodePort usada pelo serviço K8s."
  type        = number
  default     = 31000
}

variable "os_node_port" {
  description = "NodePort do os-service."
  type        = number
  default     = 31001
}

variable "billing_node_port" {
  description = "NodePort do billing-service."
  type        = number
  default     = 31002
}

variable "execution_node_port" {
  description = "NodePort do execution-service."
  type        = number
  default     = 31003
}

variable "lambda_auth_arn" {
  description = "ARN da função Lambda de auth."
  type        = string
}
