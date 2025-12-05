variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "milodev"
}

variable "project_name" {
  description = "Project identifier"
  type        = string
  default     = "podinfo-demo"
}

variable "environment" {
  description = "Environment (dev or prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod"
  }
}

variable "image_uri" {
  description = "ECR image URI with digest (immutable)"
  type        = string
}

variable "lambda_memory" {
  description = "Lambda memory in MB"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "provisioned_concurrency" {
  description = "Provisioned concurrency for pre-warming (0 = disabled)"
  type        = number
  default     = 0
}