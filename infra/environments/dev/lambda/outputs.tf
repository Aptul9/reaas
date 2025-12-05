output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.podinfo.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.podinfo.arn
}

output "lambda_alias_name" {
  description = "Lambda alias name"
  value       = aws_lambda_alias.live.name
}

output "lambda_alias_arn" {
  description = "Lambda alias ARN"
  value       = aws_lambda_alias.live.arn
}

output "api_gateway_url" {
  description = "API Gateway HTTP API URL"
  value       = aws_apigatewayv2_stage.main.invoke_url
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.main.id
}

output "codedeploy_app_name" {
  description = "CodeDeploy application name"
  value       = aws_codedeploy_app.lambda.name
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy deployment group name"
  value       = aws_codedeploy_deployment_group.lambda.deployment_group_name
}

output "cloudwatch_log_group" {
  description = "Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "health_check_url" {
  description = "Health check endpoint"
  value       = "${aws_apigatewayv2_stage.main.invoke_url}healthz"
}