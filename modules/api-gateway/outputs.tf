output "api_gateway_endpoint" {
  description = "URL pública do API Gateway."
  value       = aws_apigatewayv2_stage.default.invoke_url
}
