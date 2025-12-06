variable "aws_region" {
  description = "Target AWS Region for global resources"
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "Local AWS CLI profile for authentication"
  type        = string
  default     = "default"
}

variable "project_name" {
  description = "Namespace identifier for resource tagging"
  type        = string
  default     = "podinfo-demo"
}

variable "ecr_retention_count" {
  description = "Maximum number of immutable images to retain in ECR"
  type        = number
  default     = 10
}

variable "github_org" {
  description = "GitHub Organization or Username for OIDC trust"
  type        = string
}

variable "github_repo" {
  description = "GitHub Repository name for OIDC trust"
  type        = string
}

variable "environment" {
  description = "Target environment label (dev/prod)"
  type        = string
  default     = "dev"
}

variable "domain_name" {
  description = "Root domain for ACM certificate validation"
  type        = string
  default     = "kalezic.net"
}

variable "alarm_email" {
  description = "Recipient address for CloudWatch Alarm notifications"
  type        = string
  default     = "milo.kalezic@gmail.com"
}

variable "deployment_email" {
  description = "Recipient address for CodeDeploy status notifications"
  type        = string
  default     = "milo.kalezic@gmail.com"
}