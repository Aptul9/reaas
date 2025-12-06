# Read outputs from global stack
data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket  = "podinfo-demo-terraform-state-996549485948"
    key     = "global/terraform.tfstate"
    region  = var.aws_region
    profile = var.aws_profile
  }
}

# Current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Availability zones
data "aws_availability_zones" "available" {
  state = "available"
}