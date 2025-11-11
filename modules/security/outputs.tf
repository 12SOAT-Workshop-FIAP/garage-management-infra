output "eks_nodes_sg_id" {
  description = "ID do Security Group dos nodes do EKS."
  value       = aws_security_group.eks_nodes.id
}

output "rds_sg_id" {
  description = "ID do Security Group do RDS."
  value       = aws_security_group.rds.id
}