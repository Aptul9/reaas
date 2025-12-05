resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name          = "High-5xx-Error-Rate-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.blue.arn_suffix
  }

  alarm_description = "CRITICAL: Elevated 5xx error rate detected on ALB targets."
  alarm_actions     = [data.terraform_remote_state.global.outputs.sns_alarms_topic_arn]

  tags = {
    Type = "Availability"
  }
}

resource "aws_cloudwatch_metric_alarm" "target_unhealthy" {
  alarm_name          = "Unhealthy-Host-Count-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.blue.arn_suffix
  }

  alarm_description = "CRITICAL: One or more targets have failed health checks."
  alarm_actions     = [data.terraform_remote_state.global.outputs.sns_alarms_topic_arn]

  tags = {
    Type = "Availability"
  }
}

resource "aws_cloudwatch_metric_alarm" "target_response_time" {
  alarm_name          = "High-Latency-P99-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 2000

  metric_query {
    id          = "q1"
    return_data = true
    metric {
      metric_name = "TargetResponseTime"
      namespace   = "AWS/ApplicationELB"
      period      = 60
      stat        = "p99"
      dimensions = {
        LoadBalancer = aws_lb.main.arn_suffix
        TargetGroup  = aws_lb_target_group.blue.arn_suffix
      }
    }
  }

  alarm_description  = "PERFORMANCE: P99 latency exceeded 2 seconds."
  alarm_actions      = [data.terraform_remote_state.global.outputs.sns_alarms_topic_arn]
  treat_missing_data = "notBreaching"

  tags = {
    Type = "Performance"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "High-CPU-Utilization-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  alarm_description = "WARNING: Fleet CPU utilization > 80%."
  alarm_actions     = [data.terraform_remote_state.global.outputs.sns_alarms_topic_arn]

  tags = {
    Type = "Infrastructure"
  }
}

resource "aws_cloudwatch_metric_alarm" "asg_instances" {
  alarm_name          = "Low-Instance-Count-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 60
  statistic           = "Average"
  threshold           = 2
  treat_missing_data  = "breaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  alarm_description = "CRITICAL: Active instance count dropped below minimum (2)."
  alarm_actions     = [data.terraform_remote_state.global.outputs.sns_alarms_topic_arn]

  tags = {
    Type = "Availability"
  }
}