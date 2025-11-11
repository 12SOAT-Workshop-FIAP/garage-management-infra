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
