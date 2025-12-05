terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "podinfo-demo-terraform-state"
    key    = "global/terraform.tfstate"
    region = "eu-central-1"
    use_lockfile = true
    encrypt = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = "podinfo-demo"
      ManagedBy   = "Terraform"
      Environment = "global"
    }
  }
}