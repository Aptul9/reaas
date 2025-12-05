# CodeDeploy Application
resource "aws_codedeploy_app" "main" {
  name             = "${var.project_name}-ec2-${var.environment}"
  compute_platform = "Server"

  tags = {
    Name = "${var.project_name}-codedeploy-ec2-${var.environment}"
  }
}

# CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "main" {
  app_name               = aws_codedeploy_app.main.name
  deployment_group_name  = "${var.project_name}-ec2-dg-${var.environment}"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  alarm_configuration {
    enabled = true
    alarms = [
      aws_cloudwatch_metric_alarm.target_5xx.alarm_name,
    ]
  }

  # KRITIČNO: deployment_type MORA biti BLUE_GREEN
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 10  # Povećano na 10min za sigurniju rotaciju
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
  }

  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.blue.name
    }
  }

  # KRITIČNO: Koristi SAMO autoscaling_groups, NE ec2_tag_set!
  # ec2_tag_set trigeruje lifecycle hook i pravi paralelni in-place deployment
  autoscaling_groups = [aws_autoscaling_group.main.name]

  # UKLONI ovaj blok potpuno (uzrokuje race condition):
  # ec2_tag_set { ... }  ← NE KORISTI!

  tags = {
    Name = "${var.project_name}-codedeploy-dg-${var.environment}"
  }
}

# S3 bucket for CodeDeploy artifacts
resource "aws_s3_bucket" "codedeploy" {
  bucket = "${var.project_name}-deployments-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-codedeploy-artifacts-${var.environment}"
  }
}

resource "aws_s3_bucket_versioning" "codedeploy" {
  bucket = aws_s3_bucket.codedeploy.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "codedeploy" {
  bucket = aws_s3_bucket.codedeploy.id

  rule {
    id     = "delete-old-artifacts"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codedeploy" {
  bucket = aws_s3_bucket.codedeploy.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}