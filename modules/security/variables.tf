variable "vpc_id" {
  type = string
}

variable "project_name" {
  type = string
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets to allow DB access from"
  type        = list(string)
}

variable "app_node_port" {
  description = "Porta NodePort do K8s."
  type        = number
}

variable "app_node_port_max" {
  description = "Porta máxima do range NodePort (para multi-serviço)."
  type        = number
  default     = 31003
}
