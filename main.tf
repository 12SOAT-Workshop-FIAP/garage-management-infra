module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  availability_zones = var.cluster_availability_zones
}

module "security" {
  source = "./modules/security"

  vpc_id               = module.vpc.vpc_id
  project_name         = var.project_name
  private_subnet_cidrs = module.vpc.private_subnet_cidrs
  app_node_port        = var.app_node_port
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

module "api_gateway" {
  source = "./modules/api-gateway"

  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  eks_cluster_name      = module.eks.cluster_name
  alb_security_group_id = module.security.alb_sg_id

  lambda_auth_arn = var.lambda_auth_arn

  app_node_port = var.app_node_port
}
