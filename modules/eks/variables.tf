variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "eks_nodes_sg_id" {
  description = "ID do Security Group para os nós do EKS."
  type        = string
}
