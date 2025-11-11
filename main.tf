module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  availability_zones = var.cluster_availability_zones
}

module "security" {
  source = "./modules/security"

  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
  private_subnet_cidrs = module.vpc.private_subnet_cidrs
}

module "eks" {
  source = "./modules/eks"

  cluster_name = var.project_name

  # As saídas da VPC viram entradas para o módulo EKS.
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  eks_nodes_sg_id    = module.security.eks_nodes_sg_id
}

module "ecr" {
  source = "./modules/ecr"

  repository_name = var.project_name
}
