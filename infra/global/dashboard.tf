# CloudWatch Dashboard - Centralized Observability
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      # Header
      {
        type = "text"
        properties = {
          markdown = "# System Status: ${upper(var.environment)}\n\n**Service:** Podinfo | **Region:** ${var.aws_region} | **Stack:** Lambda + EC2"
        }
        x      = 0
        y      = 0
        width  = 24
        height = 1
      },

      # Row 1: Lambda Performance
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Execution Count", color = "#1f77b4" }]
          ]
          period = 60
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda Traffic Volume"
          yAxis = { left = { min = 0 } }
        }
        x      = 0
        y      = 1
        width  = 8
        height = 6
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", { stat = "Sum", label = "Failed Executions", color = "#d62728" }],
            [".", "Throttles", { stat = "Sum", label = "Throttled Requests", color = "#ff7f0e" }]
          ]
          period = 60
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda Error Rates"
          yAxis = { left = { min = 0 } }
        }
        x      = 8
        y      = 1
        width  = 8
        height = 6
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", { stat = "p50", label = "P50 Latency", color = "#2ca02c" }],
            ["...", { stat = "p99", label = "P99 Latency", color = "#9467bd" }]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "Lambda Duration (ms)"
          yAxis = { left = { min = 0 } }
        }
        x      = 16
        y      = 1
        width  = 8
        height = 6
      },

      # Row 2: API Gateway
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", { stat = "Sum", label = "Incoming Requests", color = "#1f77b4" }]
          ]
          period = 60
          stat   = "Sum"
          region = var.aws_region
          title  = "API Gateway Traffic"
          yAxis = { left = { min = 0 } }
        }
        x      = 0
        y      = 7
        width  = 8
        height = 6
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApiGateway", "4XXError", { stat = "Sum", label = "Client Errors (4xx)", color = "#ff7f0e" }],
            [".", "5XXError", { stat = "Sum", label = "Server Errors (5xx)", color = "#d62728" }]
          ]
          period = 60
          stat   = "Sum"
          region = var.aws_region
          title  = "API Gateway HTTP Codes"
          yAxis = { left = { min = 0 } }
        }
        x      = 8
        y      = 7
        width  = 8
        height = 6
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Latency", { stat = "p50", label = "P50", color = "#2ca02c" }],
            ["...", { stat = "p99", label = "P99", color = "#9467bd" }]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "Integration Latency (ms)"
          yAxis = { left = { min = 0 } }
        }
        x      = 16
        y      = 7
        width  = 8
        height = 6
      },

      # Row 3: EC2 / ALB
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", { stat = "Sum", label = "ALB Requests", color = "#1f77b4" }]
          ]
          period = 60
          stat   = "Sum"
          region = var.aws_region
          title  = "Load Balancer Throughput"
          yAxis = { left = { min = 0 } }
        }
        x      = 0
        y      = 13
        width  = 8
        height = 6
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "p50", label = "P50", color = "#2ca02c" }],
            ["...", { stat = "p99", label = "P99", color = "#9467bd" }]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "Upstream Response Time"
          yAxis = { left = { min = 0 } }
        }
        x      = 8
        y      = 13
        width  = 8
        height = 6
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", { stat = "Sum", label = "Target 5xx", color = "#d62728" }],
            [".", "HTTPCode_ELB_5XX_Count", { stat = "Sum", label = "LB 5xx", color = "#8c564b" }]
          ]
          period = 60
          stat   = "Sum"
          region = var.aws_region
          title  = "Load Balancer Errors"
          yAxis = { left = { min = 0 } }
        }
        x      = 16
        y      = 13
        width  = 8
        height = 6
      },

      # Row 4: Fleet Health
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", { stat = "Average", label = "Healthy Nodes", color = "#2ca02c" }],
            [".", "UnHealthyHostCount", { stat = "Average", label = "Unhealthy Nodes", color = "#d62728" }]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "Target Group Health"
          yAxis = { left = { min = 0 } }
        }
        x      = 0
        y      = 19
        width  = 8
        height = 6
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", { stat = "Average", label = "Active Instances", color = "#2ca02c" }],
            [".", "GroupPendingInstances", { stat = "Average", label = "Pending", color = "#ff7f0e" }]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "ASG Capacity"
          yAxis = { left = { min = 0 } }
        }
        x      = 8
        y      = 19
        width  = 8
        height = 6
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["CWAgent", "cpu_usage_idle", { stat = "Average", label = "Idle %", color = "#2ca02c" }],
            [".", "cpu_usage_iowait", { stat = "Average", label = "IO Wait %", color = "#ff7f0e" }]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 Fleet Metrics (Agent)"
          yAxis = { left = { min = 0, max = 100 } }
        }
        x      = 16
        y      = 19
        width  = 8
        height = 6
      },

      # Row 5: Logs & Deployment
      {
        type = "log"
        properties = {
          query   = "SOURCE '/aws/lambda/${var.project_name}-podinfo-${var.environment}'\n| fields @timestamp, @message\n| sort @timestamp desc\n| limit 20"
          region  = var.aws_region
          title   = "Live Lambda Logs"
          stacked = false
        }
        x      = 0
        y      = 25
        width  = 24
        height = 6
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/CodeDeploy", "SucceededDeployments", { stat = "Sum", label = "Success", color = "#2ca02c" }],
            [".", "FailedDeployments", { stat = "Sum", label = "Failed", color = "#d62728" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Deployment History"
          yAxis = { left = { min = 0 } }
        }
        x      = 0
        y      = 31
        width  = 12
        height = 6
      },
      {
        type = "alarm"
        properties = {
          title  = "Active Alerts"
          alarms = [
            "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:Lambda-Error-Rate-High-${var.environment}",
            "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:Lambda-Throttling-Detected-${var.environment}",
            "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:High-5xx-Error-Rate-${var.environment}",
            "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:Unhealthy-Host-Count-${var.environment}"
          ]
        }
        x      = 12
        y      = 31
        width  = 12
        height = 6
      }
    ]
  })
}