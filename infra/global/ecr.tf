# ECR Repository for Podinfo container images
resource "aws_ecr_repository" "podinfo" {
  name                 = "${var.project_name}/podinfo"
  image_tag_mutability = "IMMUTABLE" # Required for signed, digest-based deploys

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-podinfo"
  }
}

# Lifecycle policy - retain only last N images
resource "aws_ecr_lifecycle_policy" "podinfo" {
  repository = aws_ecr_repository.podinfo.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last ${var.ecr_retention_count} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.ecr_retention_count
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# ECR Repository policy - allow OIDC role and Lambda to pull
resource "aws_ecr_repository_policy" "podinfo" {
  repository = aws_ecr_repository.podinfo.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowOIDCPush"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.github_actions.arn
        }
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
      },
      {
        Sid    = "AllowLambdaPull"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Condition = {
          StringLike = {
            "aws:sourceArn" = "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:podinfo-demo-*"
          }
        }
      }
    ]
  })
}