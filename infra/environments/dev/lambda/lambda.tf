# Lambda function from container image
resource "aws_lambda_function" "podinfo" {
  function_name = "${var.project_name}-podinfo-${var.environment}"
  role          = aws_iam_role.lambda.arn
  package_type  = "Image"
  image_uri     = var.image_uri

  memory_size = var.lambda_memory
  timeout     = var.lambda_timeout

  environment {
    variables = {
      ENVIRONMENT           = var.environment
      PODINFO_PORT         = "8080"
      LOG_LEVEL            = "info"
      SECRET_NAME          = "/dockyard/SUPER_SECRET_TOKEN"
      AWS_REGION_SECRETS   = var.aws_region
    }
  }

  # Enable CloudWatch Logs encryption
  logging_config {
    log_format = "JSON"
    log_group  = aws_cloudwatch_log_group.lambda.name
  }

  tags = {
    Name = "${var.project_name}-podinfo-${var.environment}"
  }

  # Prevent replacement on image updates (we use publish_version + alias)
  lifecycle {
    ignore_changes = [image_uri]
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-podinfo-${var.environment}"
  retention_in_days = 7
  kms_key_id        = data.terraform_remote_state.global.outputs.kms_key_arn

  tags = {
    Name = "${var.project_name}-lambda-logs-${var.environment}"
  }
}

# Lambda alias for traffic shifting
resource "aws_lambda_alias" "live" {
  name             = "live"
  function_name    = aws_lambda_function.podinfo.function_name
  function_version = aws_lambda_function.podinfo.version

  # Provisioned concurrency for pre-warming (scalability improvement)
  dynamic "routing_config" {
    for_each = var.provisioned_concurrency > 0 ? [1] : []
    content {
      additional_version_weights = {}
    }
  }

  lifecycle {
    ignore_changes = [function_version]
  }
}

# Provisioned concurrency (if enabled)
resource "aws_lambda_provisioned_concurrency_config" "live" {
  count                             = var.provisioned_concurrency > 0 ? 1 : 0
  function_name                     = aws_lambda_function.podinfo.function_name
  qualifier                         = aws_lambda_alias.live.name
  provisioned_concurrent_executions = var.provisioned_concurrency
}

# Allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.podinfo.function_name
  principal     = "apigateway.amazonaws.com"
  qualifier     = aws_lambda_alias.live.name
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}