resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-eks-nodes-sg"
  description = "Permite comunicacao para os worker nodes do EKS."
  vpc_id      = var.vpc_id

  # Regra de saída: permite que os nodes acessem a internet (Mantida aqui pois não causa ciclo)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-eks-nodes-sg"
  }
}

resource "aws_security_group" "alb_internal" {
  name        = "${var.project_name}-alb-internal-sg"
  description = "SG para o ALB Interno"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-internal-sg"
  }
}

# Regra de Ingress do EKS: Aceita tráfego vindo do ALB
resource "aws_security_group_rule" "eks_nodes_ingress_alb" {
  type                     = "ingress"
  from_port                = var.app_node_port
  to_port                  = var.app_node_port_max
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_internal.id
  security_group_id        = aws_security_group.eks_nodes.id
}

# Regra de Egress do ALB: Envia tráfego para o EKS
resource "aws_security_group_rule" "alb_internal_egress_eks" {
  type                     = "egress"
  from_port                = var.app_node_port
  to_port                  = var.app_node_port_max
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes.id
  security_group_id        = aws_security_group.alb_internal.id
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Permite acesso ao banco de dados RDS."
  vpc_id      = var.vpc_id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    # cidr_blocks = var.private_subnet_cidrs --- enable this on production for safety
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}
