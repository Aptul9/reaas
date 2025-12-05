# GitHub OIDC Provider
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = {
    Name = "${var.project_name}-github-oidc"
  }
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json

  tags = {
    Name = "${var.project_name}-github-actions-role"
  }
}

# Trust policy - only specific repo/branch can assume
data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

# Permissions for GitHub Actions role
resource "aws_iam_role_policy" "github_actions" {
  name   = "${var.project_name}-github-actions-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}

data "aws_iam_policy_document" "github_actions_permissions" {
  # ECR permissions (push images)
  statement {
    sid    = "ECRAuth"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [aws_ecr_repository.podinfo.arn]
  }

  # API Gateway permissions (for smoke tests)
  statement {
    sid    = "APIGateway"
    effect = "Allow"
    actions = [
      "apigateway:GET",
      "apigatewayv2:GetApis",
      "apigatewayv2:GetApi"
    ]
    resources = ["*"]
  }

  # CodeDeploy permissions (trigger deployments)
  statement {
    sid    = "CodeDeploy"
    effect = "Allow"
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:GetApplicationRevision",
      "codedeploy:RegisterApplicationRevision",
      "codedeploy:ListDeployments",
      "codedeploy:ListDeploymentInstances",
      "codedeploy:GetDeploymentGroup",
      "codedeploy:UpdateDeploymentGroup"
    ]
    resources = ["*"]
  }

  # Lambda permissions (update function, create alias)
  statement {
    sid    = "Lambda"
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:PublishVersion",
      "lambda:UpdateAlias",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:GetAlias",
      "lambda:ListVersionsByFunction"
    ]
    resources = ["*"]
  }

  # S3 permissions (for CodeDeploy bundles)
  statement {
    sid    = "S3Deployments"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.project_name}-deployments-*",
      "arn:aws:s3:::${var.project_name}-deployments-*/*"
    ]
  }

  # Secrets Manager (read secrets for verification)
  statement {
    sid    = "SecretsRead"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["arn:aws:secretsmanager:${var.aws_region}:*:secret:/dockyard/*"]
  }

  # EC2 permissions (for updating Launch Template / ASG)
  statement {
    sid    = "EC2LaunchTemplate"
    effect = "Allow"
    actions = [
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:CreateLaunchTemplateVersion",
      "ec2:ModifyLaunchTemplate"
    ]
    resources = ["*"]
  }

  # Auto Scaling permissions (for updating ASG with new Launch Template)
  statement {
    sid    = "AutoScalingUpdate"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations"
    ]
    resources = ["*"]
  }

  # ALB permissions (for smoke test and validation)
  statement {
    sid    = "ALBDescribe"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetHealth"
    ]
    resources = ["*"]
  }

  # EC2 RunInstances permission (required for ASG to use Launch Template)
  statement {
    sid    = "EC2RunInstances"
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:GetLaunchTemplateData"
    ]
    resources = ["*"]
  }

  # Additional EC2 read permissions required for ASG Launch Template validation
  statement {
    sid    = "EC2ReadForASGValidation"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:GetLaunchTemplateData"
    ]
    resources = ["*"]
  }


  # Allow using specific Launch Template for Auto Scaling
  statement {
    sid    = "EC2LaunchTemplateUse"
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateLaunchTemplateVersion",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeLaunchTemplateVersions"
    ]
    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:launch-template/lt-*"
    ]
  }

  # Allow referencing Launch Template in Auto Scaling Group
  statement {
    sid    = "ASGLaunchTemplateUse"
    effect = "Allow"
    actions = [
      "autoscaling:UpdateAutoScalingGroup"
    ]
    resources = [
      "arn:aws:autoscaling:${var.aws_region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/*"
    ]
  }

  # Allow passing EC2 instance role used in Launch Template
  statement {
    sid    = "IAMPassRoleForEC2LaunchTemplate"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-ec2-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.project_name}-ec2-*"
    ]
  }

  # Allow using specific Launch Template in Auto Scaling Group update
  statement {
    sid    = "AllowLaunchTemplateUse"
    effect = "Allow"
    actions = [
      "autoscaling:UpdateAutoScalingGroup"
    ]
    resources = [
      "arn:aws:autoscaling:${var.aws_region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "autoscaling:LaunchTemplate"
      values   = [
        "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:launch-template/lt-*"
      ]
    }
  }

# Allow EC2 CreateTags in ASG update
  statement {
    sid    = "EC2CreateTagsForLaunchTemplate"
    effect = "Allow"
    actions = [
      "ec2:CreateTags"
    ]
    resources = ["*"]
  }
}
