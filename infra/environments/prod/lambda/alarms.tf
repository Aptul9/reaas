# Lambda error rate alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "Lambda-Error-Rate-High-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.podinfo.function_name
    Resource     = "${aws_lambda_function.podinfo.function_name}:${aws_lambda_alias.live.name}"
  }

  alarm_description = "CRITICAL: Lambda function execution errors exceeded threshold."
  alarm_actions     = [data.terraform_remote_state.global.outputs.sns_alarms_topic_arn]

  tags = {
    Type = "Availability"
  }
}

# Lambda throttle alarm
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "Lambda-Throttling-Detected-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 3
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.podinfo.function_name
    Resource     = "${aws_lambda_function.podinfo.function_name}:${aws_lambda_alias.live.name}"
  }

  alarm_description = "WARNING: Concurrency limit reached. Requests are being rejected."
  alarm_actions     = [data.terraform_remote_state.global.outputs.sns_alarms_topic_arn]

  tags = {
    Type = "Performance"
  }
}

# Lambda duration (P99 latency)
resource "aws_cloudwatch_metric_alarm" "lambda_duration_p99" {
  alarm_name          = "Lambda-Latency-P99-High-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 5000 # 5 seconds

  metric_query {
    id          = "q1"
    return_data = true
    metric {
      metric_name = "Duration"
      namespace   = "AWS/Lambda"
      period      = 60
      stat        = "p99"
      dimensions = {
        FunctionName = aws_lambda_function.podinfo.function_name
        Resource     = "${aws_lambda_function.podinfo.function_name}:${aws_lambda_alias.live.name}"
      }
    }
  }

  alarm_description = "PERFORMANCE: Lambda execution time P99 > 5 seconds."
  alarm_actions     = [data.terraform_remote_state.global.outputs.sns_alarms_topic_arn]
  treat_missing_data = "notBreaching"

  tags = {
    Type = "Performance"
  }
}

# API Gateway 5xx errors
resource "aws_cloudwatch_metric_alarm" "apigw_5xx" {
  alarm_name          = "APIGW-5xx-Error-Spike-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = aws_apigatewayv2_api.main.id
    Stage = aws_apigatewayv2_stage.main.name
  }

  alarm_description = "CRITICAL: API Gateway returning 5xx errors to clients."
  alarm_actions     = [data.terraform_remote_state.global.outputs.sns_alarms_topic_arn]

  tags = {
    Type = "Availability"
  }
}

# API Gateway latency (P99)
resource "aws_cloudwatch_metric_alarm" "apigw_latency_p99" {
  alarm_name          = "APIGW-Latency-P99-High-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 3000 # 3 seconds

  metric_query {
    id          = "q1"
    return_data = true
    metric {
      metric_name = "Latency"
      namespace   = "AWS/ApiGateway"
      period      = 60
      stat        = "p99"
      dimensions = {
        ApiId = aws_apigatewayv2_api.main.id
        Stage = aws_apigatewayv2_stage.main.name
      }
    }
  }

  alarm_description  = "PERFORMANCE: API Gateway overhead P99 > 3 seconds."
  alarm_actions      = [data.terraform_remote_state.global.outputs.sns_alarms_topic_arn]
  treat_missing_data = "notBreaching"

  tags = {
    Type = "Performance"
  }
}