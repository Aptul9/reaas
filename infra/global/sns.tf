# SNS Topic for Deployment Status
resource "aws_sns_topic" "deployments" {
  name              = "${var.project_name}-deployments"
  display_name      = "Podinfo Deployments"
  kms_master_key_id = aws_kms_key.main.id

  tags = {
    Name = "${var.project_name}-deployments-topic"
  }
}

# SNS Topic for CloudWatch Alarms
resource "aws_sns_topic" "alarms" {
  name              = "${var.project_name}-alarms"
  display_name      = "Podinfo ALERTS"
  kms_master_key_id = aws_kms_key.main.id

  tags = {
    Name = "${var.project_name}-alarms-topic"
  }
}

# Email Subscription: Deployments
resource "aws_sns_topic_subscription" "deployments_email" {
  topic_arn = aws_sns_topic.deployments.arn
  protocol  = "email"
  endpoint  = var.deployment_email
}

# Email Subscription: Alarms
resource "aws_sns_topic_subscription" "alarms_email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}