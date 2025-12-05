# VPC using official AWS module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc-${var.environment}"
  cidr = var.vpc_cidr

  azs = var.availability_zones
  
  # Dynamic subnet CIDRs based on VPC CIDR
  # For dev (10.0.0.0/16): 10.0.1.0/24, 10.0.2.0/24
  # For prod (10.1.0.0/16): 10.1.1.0/24, 10.1.2.0/24
  private_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 1),  # X.X.1.0/24
    cidrsubnet(var.vpc_cidr, 8, 2)   # X.X.2.0/24
  ]
  
  # For dev (10.0.0.0/16): 10.0.101.0/24, 10.0.102.0/24
  # For prod (10.1.0.0/16): 10.1.101.0/24, 10.1.102.0/24
  public_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 101), # X.X.101.0/24
    cidrsubnet(var.vpc_cidr, 8, 102)  # X.X.102.0/24
  ]

  enable_nat_gateway   = true
  single_nat_gateway   = true # Cost optimization
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs to CloudWatch
  enable_flow_log                                 = true
  create_flow_log_cloudwatch_iam_role             = true
  create_flow_log_cloudwatch_log_group            = true
  flow_log_cloudwatch_log_group_kms_key_id        = data.terraform_remote_state.global.outputs.kms_key_arn
  flow_log_cloudwatch_log_group_retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-vpc-${var.environment}"
    Environment = var.environment
  }

  public_subnet_tags = {
    "Type"                   = "public"
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "Type" = "private"
  }
}
