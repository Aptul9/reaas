# CodeDeploy application
resource "aws_codedeploy_app" "lambda" {
  name             = "${var.project_name}-lambda-${var.environment}"
  compute_platform = "Lambda"

  tags = {
    Name = "${var.project_name}-codedeploy-lambda-${var.environment}"
  }
}

# CodeDeploy deployment group
resource "aws_codedeploy_deployment_group" "lambda" {
  app_name               = aws_codedeploy_app.lambda.name
  deployment_group_name  = "${var.project_name}-lambda-dg-${var.environment}"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.LambdaLinear10PercentEvery1Minute"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  alarm_configuration {
    enabled = true
    alarms  = [
      aws_cloudwatch_metric_alarm.lambda_errors.alarm_name,
      aws_cloudwatch_metric_alarm.lambda_throttles.alarm_name
    ]
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  tags = {
    Name = "${var.project_name}-codedeploy-dg-${var.environment}"
  }
}