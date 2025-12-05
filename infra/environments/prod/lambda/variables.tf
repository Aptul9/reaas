variable "aws_region" {
  description = "Target AWS Region for resource provisioning"
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "Local CLI profile for authentication"
  type        = string
  default     = "milodev"
}

variable "project_name" {
  description = "Global project namespace identifier"
  type        = string
  default     = "podinfo-demo"
}

variable "environment" {
  description = "Deployment stage (dev/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Value must be strictly 'dev' or 'prod'."
  }
}

variable "image_uri" {
  description = "Full ECR URI including digest (sha256:...)"
  type        = string
}

variable "lambda_memory" {
  description = "Memory allocation for Lambda (MB)"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Execution timeout for Lambda (seconds)"
  type        = number
  default     = 30
}

variable "provisioned_concurrency" {
  description = "Number of pre-warmed execution environments"
  type        = number
  default     = 0
}