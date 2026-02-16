resource "aws_lb" "internal_alb" {
  name               = "${var.project_name}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.private_subnet_ids
}

# --- Target Groups ---

resource "aws_lb_target_group" "eks_app_tg" {
  name        = "${var.project_name}-eks-tg"
  port        = var.app_node_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-299"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "os_service_tg" {
  name        = "${var.project_name}-os-tg"
  port        = var.os_node_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-299"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "billing_service_tg" {
  name        = "${var.project_name}-billing-tg"
  port        = var.billing_node_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-299"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "execution_service_tg" {
  name        = "${var.project_name}-exec-tg"
  port        = var.execution_node_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-299"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# --- ASG Attachments (register EKS nodes with all target groups) ---

data "aws_autoscaling_groups" "eks_groups" {
  filter {
    name   = "key"
    values = ["eks:cluster-name"]
  }
  filter {
    name   = "value"
    values = [var.eks_cluster_name]
  }
}

resource "aws_autoscaling_attachment" "eks_asg_attachment" {
  count                  = length(data.aws_autoscaling_groups.eks_groups.names)
  autoscaling_group_name = data.aws_autoscaling_groups.eks_groups.names[count.index]
  lb_target_group_arn    = aws_lb_target_group.eks_app_tg.arn
}

resource "aws_autoscaling_attachment" "eks_asg_os" {
  count                  = length(data.aws_autoscaling_groups.eks_groups.names)
  autoscaling_group_name = data.aws_autoscaling_groups.eks_groups.names[count.index]
  lb_target_group_arn    = aws_lb_target_group.os_service_tg.arn
}

resource "aws_autoscaling_attachment" "eks_asg_billing" {
  count                  = length(data.aws_autoscaling_groups.eks_groups.names)
  autoscaling_group_name = data.aws_autoscaling_groups.eks_groups.names[count.index]
  lb_target_group_arn    = aws_lb_target_group.billing_service_tg.arn
}

resource "aws_autoscaling_attachment" "eks_asg_execution" {
  count                  = length(data.aws_autoscaling_groups.eks_groups.names)
  autoscaling_group_name = data.aws_autoscaling_groups.eks_groups.names[count.index]
  lb_target_group_arn    = aws_lb_target_group.execution_service_tg.arn
}

# --- ALB Listener with path-based routing ---

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.internal_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks_app_tg.arn
  }
}

resource "aws_lb_listener_rule" "os_service_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.os_service_tg.arn
  }

  condition {
    path_pattern {
      values = ["/os/*"]
    }
  }
}

resource "aws_lb_listener_rule" "billing_service_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.billing_service_tg.arn
  }

  condition {
    path_pattern {
      values = ["/billing/*"]
    }
  }
}

resource "aws_lb_listener_rule" "execution_service_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = 102

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.execution_service_tg.arn
  }

  condition {
    path_pattern {
      values = ["/execution/*"]
    }
  }
}

# --- VPC Link & API Gateway ---

resource "aws_apigatewayv2_vpc_link" "eks_vpc_link" {
  name               = "${var.project_name}-vpc-link"
  security_group_ids = [var.alb_security_group_id]
  subnet_ids         = var.private_subnet_ids
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
  connection_id   = aws_apigatewayv2_vpc_link.eks_vpc_link.id

  integration_uri = aws_lb_listener.alb_listener.arn
}

resource "aws_lambda_permission" "api_gw_auth" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_auth_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# --- Rotas do API Gateway ---

# Autenticação via Lambda
resource "aws_apigatewayv2_route" "auth_proxy" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /auth/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_auth.id}"
}

# Rota padrão — ALB listener rules fazem o routing por path (/os/*, /billing/*, /execution/*)
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

