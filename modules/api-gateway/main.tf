data "aws_instances" "eks_nodes" {
  filter {
    name   = "tag:eks:cluster-name"
    values = [var.eks_cluster_name]
  }
}

resource "aws_lb" "internal_alb" {
  name               = "${var.project_name}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.private_subnet_ids
}

resource "aws_lb_target_group" "eks_app_tg" {
  name        = "${var.project_name}-eks-tg"
  port        = var.app_node_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
}

resource "aws_lb_target_group_attachment" "eks_nodes_attach" {
  count            = length(data.aws_instances.eks_nodes.ids)
  target_group_arn = aws_lb_target_group.eks_app_tg.arn
  target_id        = data.aws_instances.eks_nodes.ids[count.index]
  port             = var.app_node_port
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.internal_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks_app_tg.arn
  }
}

resource "aws_api_gateway_vpc_link" "eks_vpc_link" {
  name        = "${var.project_name}-vpc-link"
  target_arns = [aws_lb.internal_alb.arn]
}

resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-http-api"
  protocol_type = "HTTP"
}

# --- Integrações ---

resource "aws_apigatewayv2_integration" "lambda_auth" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_auth_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "eks_app" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"

  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.eks_vpc_link.id

  integration_uri = aws_lb_listener.alb_listener.arn
}

# --- Criar as Rotas ---

# Rotas de /auth/* vão para a Lambda
resource "aws_apigatewayv2_route" "auth_wildcard" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /auth/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_auth.id}"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.eks_app.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}
