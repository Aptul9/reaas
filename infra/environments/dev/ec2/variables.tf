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

variable "vpc_cidr" {
  description = "Network CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs for subnet distribution"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "instance_type" {
  description = "EC2 instance class size"
  type        = string
  default     = "t3.small"
}

variable "desired_capacity" {
  description = "Target ASG size (Fixed at 2 for Blue/Green logic)"
  type        = number
  default     = 2
}

variable "image_uri" {
  description = "Full ECR URI including digest (sha256:...)"
  type        = string
}

variable "podinfo_port" {
  description = "Container exposure port"
  type        = number
  default     = 9898
}