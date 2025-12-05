# IAM Role for EC2 instances
resource "aws_iam_role" "ec2" {
  name               = "${var.project_name}-ec2-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = {
    Name = "${var.project_name}-ec2-role-${var.environment}"
  }
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-${var.environment}"
  role = aws_iam_role.ec2.name

  tags = {
    Name = "${var.project_name}-ec2-profile-${var.environment}"
  }
}

# IAM Policy for EC2 instances
resource "aws_iam_role_policy" "ec2" {
  name   = "${var.project_name}-ec2-policy-${var.environment}"
  role   = aws_iam_role.ec2.id
  policy = data.aws_iam_policy_document.ec2_permissions.json
}

data "aws_iam_policy_document" "ec2_permissions" {
  # ECR - pull images
  statement {
    sid    = "ECRAuth"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = [data.terraform_remote_state.global.outputs.ecr_repository_arn]
  }

  # CloudWatch Logs
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/podinfo/*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/*"
    ]
  }

  # CloudWatch Agent
  statement {
    sid    = "CloudWatchAgent"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }

  # Secrets Manager
  statement {
    sid    = "SecretsManager"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:/dockyard/*"
    ]
  }

  # KMS - decrypt secrets
  statement {
    sid    = "KMSDecrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = [data.terraform_remote_state.global.outputs.kms_key_arn]
  }

  # SSM - for session manager (optional debugging)
  statement {
    sid    = "SSM"
    effect = "Allow"
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }

  # S3 - CodeDeploy artifacts
  statement {
    sid    = "S3CodeDeploy"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::aws-codedeploy-${data.aws_region.current.name}/*",
      "arn:aws:s3:::${var.project_name}-deployments-*",
      "arn:aws:s3:::${var.project_name}-deployments-*/*"
    ]
  }
}

# CodeDeploy service role
resource "aws_iam_role" "codedeploy" {
  name               = "${var.project_name}-codedeploy-ec2-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume.json

  tags = {
    Name = "${var.project_name}-codedeploy-ec2-${var.environment}"
  }
}

data "aws_iam_policy_document" "codedeploy_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Custom CodeDeploy policy (AWS managed policy doesn't exist for EC2/ALB)
resource "aws_iam_role_policy" "codedeploy" {
  name   = "${var.project_name}-codedeploy-ec2-policy-${var.environment}"
  role   = aws_iam_role.codedeploy.id
  policy = data.aws_iam_policy_document.codedeploy_permissions.json
}

data "aws_iam_policy_document" "codedeploy_permissions" {
  statement {
    sid    = "EC2Permissions"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:RunInstances",
      "ec2:TerminateInstances"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IAMPassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [aws_iam_role.ec2.arn]
  }

  statement {
    sid    = "AutoScalingPermissions"
    effect = "Allow"
    actions = [
      "autoscaling:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ELBPermissions"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CloudWatchPermissions"
    effect = "Allow"
    actions = [
      "cloudwatch:DescribeAlarms",
      "cloudwatch:PutMetricAlarm"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SNSPermissions"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [data.terraform_remote_state.global.outputs.sns_deployments_topic_arn]
  }

  # CodeDeploy agent - register and report status
  statement {
    sid    = "CodeDeployAgent"
    effect = "Allow"
    actions = [
      "codedeploy:PollHostCommand",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentInstance",
      "codedeploy:PutLifecycleEventHookExecutionStatus",
      "codedeploy:UpdateDeploymentStatus"
    ]
    resources = ["*"]
  }
}