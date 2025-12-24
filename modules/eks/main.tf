# Role pré-configurada do AWS Academy.
data "aws_iam_role" "eks_lab_role" {
  name = "LabRole"
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.eks_lab_role.arn

  vpc_config {
    subnet_ids         = concat(var.public_subnet_ids, var.private_subnet_ids)
    security_group_ids = [var.eks_nodes_sg_id]
  }
}

resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "${var.cluster_name}-nodes-lt-"
  instance_type = "t3.medium"

  vpc_security_group_ids = [
    var.eks_nodes_sg_id,
    aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  ]

  image_id = ""

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-node"
    }
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = data.aws_iam_role.eks_lab_role.arn
  subnet_ids      = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  depends_on = [aws_eks_cluster.main]
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.1"
  
  set = [
    {
      name  = "metrics.enabled"
      value = "true"
    }
  ]

  depends_on = [aws_eks_node_group.main]
}