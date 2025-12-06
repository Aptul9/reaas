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