variable "project_name" {
  description = "Nome do projeto para as tags dos recursos"
  type        = string
}

variable "vpc_cidr_block" {
  description = "Bloco CIDR para a VPC principal."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Bloco CIDR para a subnet pública."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Bloco CIDR para a subnet privada."
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  type = list(string)
}
