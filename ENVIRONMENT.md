# Environment Configuration

This document describes the environment configuration, versions, variables, and resource identifiers used in the Podinfo deployment system.

## AWS Configuration

### Regions

| Environment | Primary Region | Account ID |
|-------------|----------------|------------|
| dev         | eu-central-1   | 996549485948 |
| prod        | eu-central-1   | 996549485948 |

**Note:** Future multi-region expansion planned (see `docs/SCALABILITY.md`)

### AWS Profile

**Local Development:**
- Profile Name: `default`
- Configured via: `aws configure --profile default`

**CI/CD (GitHub Actions):**
- Authentication: OIDC (no static credentials)
- IAM Role: `arn:aws:iam::996549485948:role/github-actions-role`

## Tool Versions

### Required Tools

| Tool       | Minimum Version | Tested Version | Notes |
|------------|-----------------|----------------|-------|
| Terraform  | 1.5.0           | 1.6.3          | Infrastructure as Code |
| AWS CLI    | 2.13.0          | 2.13.25        | AWS resource management |
| Docker     | 20.10.0         | 24.0.6         | Container builds |
| cosign     | 2.0.0           | 2.2.0          | Image signing |
| syft       | 0.90.0          | 0.92.0         | SBOM generation |
| Go         | 1.21.0          | 1.21.3         | Podinfo build (if from source) |

### Terraform Providers

```hcl
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.20"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
```

## Container Images

### ECR Repository

**Repository Name:** `podinfo-demo/podinfo`

**Full URI:** `996549485948.dkr.ecr.eu-central-1.amazonaws.com/podinfo-demo/podinfo`

### Image Variants

| Variant | Tag Pattern | Description |
|---------|-------------|-------------|
| Lambda  | `6.5.4-{git-sha}-lambda` | Lambda Web Adapter included |
| EC2     | `6.5.4-{git-sha}-ec2` | Standard Podinfo with Alpine |

### Base Images

| Target | Base Image | Version |
|--------|------------|---------|
| Lambda | `public.ecr.aws/awsguru/aws-lambda-adapter` | 0.8.4 |
| Lambda | `stefanprodan/podinfo` | 6.5.4 |
| EC2    | `alpine` | 3.18 |
| EC2    | Podinfo binary | 6.5.4 |

### Image Retention

- **Policy:** Keep last 10 images per variant
- **Lifecycle:** Automatic cleanup via ECR lifecycle policy
- **Signed Images:** Retained indefinitely (tag: `signed`)

## Secrets and Credentials

### AWS Secrets Manager

| Secret Name | Description | Rotation | Used By |
|-------------|-------------|----------|---------|
| `/dockyard/SUPER_SECRET_TOKEN` | Application secret token | Manual | Lambda, EC2 |
| `podinfo-demo-datadog-api-key` | Datadog API key (if enabled) | Manual | Lambda, EC2 |

**Note:** Secret values are NEVER stored in version control. Retrieve via:
```bash
aws secretsmanager get-secret-value --secret-id /dockyard/SUPER_SECRET_TOKEN --profile default
```

### KMS Keys

| Key Alias | Purpose | Used By |
|-----------|---------|---------|
| `alias/podinfo-demo-dev` | Encrypt CloudWatch logs, S3, Secrets | All services |
| `alias/podinfo-demo-prod` | Encrypt CloudWatch logs, S3, Secrets | All services |

## Resource Identifiers

### Lambda Resources (dev)

| Resource Type | Name/ID | ARN/URL |
|---------------|---------|---------|
| Function | `podinfo-demo-podinfo-dev` | `arn:aws:lambda:eu-central-1:996549485948:function:podinfo-demo-podinfo-dev` |
| Alias | `live` | `arn:aws:lambda:eu-central-1:996549485948:function:podinfo-demo-podinfo-dev:live` |
| API Gateway | `niwxqj74o4` | `https://niwxqj74o4.execute-api.eu-central-1.amazonaws.com/` |
| Log Group | `/aws/lambda/podinfo-demo-podinfo-dev` | - |
| CodeDeploy App | `podinfo-demo-lambda-dev` | - |
| CodeDeploy DG | `podinfo-demo-lambda-dg-dev` | - |

### EC2 Resources (dev)

| Resource Type | Name/ID | ARN/DNS |
|---------------|---------|---------|
| VPC | `vpc-05c013a9e271c161d` | - |
| ALB | `podinfo-demo-alb-dev` | `podinfo-demo-alb-dev-479277029.eu-central-1.elb.amazonaws.com` |
| Target Group (Blue) | `podinfo-demo-blue-dev` | `arn:aws:elasticloadbalancing:eu-central-1:996549485948:targetgroup/podinfo-demo-blue-dev/...` |
| Target Group (Green) | `podinfo-demo-green-dev` | `arn:aws:elasticloadbalancing:eu-central-1:996549485948:targetgroup/podinfo-demo-green-dev/...` |
| ASG | `podinfo-demo-asg-dev` | - |
| Launch Template | `lt-03266c38e353c25e1` | - |
| CodeDeploy App | `podinfo-demo-ec2-dev` | - |
| CodeDeploy DG | `podinfo-demo-ec2-dg-dev` | - |
| S3 Bucket (ALB Logs) | `podinfo-demo-alb-logs-dev-996549485948` | - |
| S3 Bucket (Deployments) | `podinfo-demo-deployments-dev-996549485948` | - |

### CloudWatch Resources

| Resource Type | Name | Description |
|---------------|------|-------------|
| Dashboard | `podinfo-demo-dev` | Unified metrics dashboard |
| Alarm | `podinfo-demo-lambda-errors-dev` | Lambda error rate |
| Alarm | `podinfo-demo-lambda-throttles-dev` | Lambda throttle rate |
| Alarm | `podinfo-demo-lambda-duration-p99-dev` | Lambda P99 latency |
| Alarm | `podinfo-demo-apigw-5xx-dev` | API Gateway 5xx rate |
| Alarm | `podinfo-demo-ec2-target-5xx-dev` | ALB target 5xx rate |
| Alarm | `podinfo-demo-ec2-unhealthy-targets-dev` | Unhealthy target count |

### SNS Topics

| Topic Name | ARN | Purpose |
|------------|-----|---------|
| `podinfo-demo-alarms-dev` | `arn:aws:sns:eu-central-1:996549485948:podinfo-demo-alarms-dev` | CloudWatch alarm notifications |

## Environment Variables

### Lambda Environment Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `ENVIRONMENT` | `dev` / `prod` | Current environment |
| `PODINFO_PORT` | `8080` | HTTP port (Lambda Web Adapter) |
| `LOG_LEVEL` | `info` | Log verbosity |
| `SECRET_NAME` | `/dockyard/SUPER_SECRET_TOKEN` | Secrets Manager secret ID |
| `AWS_REGION_SECRETS` | `eu-central-1` | Region for Secrets Manager |

### EC2 Environment Variables (UserData)

| Variable | Value | Description |
|----------|-------|-------------|
| `AWS_REGION` | `eu-central-1` | AWS region |
| `ENVIRONMENT` | `dev` / `prod` | Current environment |
| `ECR_REGISTRY` | `996549485948.dkr.ecr.eu-central-1.amazonaws.com` | ECR registry |
| `IMAGE_URI` | `{ECR_REGISTRY}/podinfo-demo/podinfo@sha256:...` | Container image digest |
| `PODINFO_PORT` | `9898` | HTTP port |
| `LOG_LEVEL` | `info` | Log verbosity |

## Terraform Variables

### Global Stack Variables

```hcl
variable "aws_region" {
  default = "eu-central-1"
}

variable "aws_profile" {
  default = "default"
}

variable "project_name" {
  default = "podinfo-demo"
}

variable "environment" {
  default = "dev"
}

variable "github_org" {
  # Set in terraform.tfvars
}

variable "github_repo" {
  # Set in terraform.tfvars
}

variable "ecr_retention_count" {
  default = 10
}
```

### Lambda Stack Variables

```hcl
variable "image_uri" {
  description = "Lambda container image URI"
  # Example: "996549485948.dkr.ecr.eu-central-1.amazonaws.com/podinfo-demo/podinfo@sha256:..."
}

variable "lambda_memory" {
  default = 512  # MB
}

variable "lambda_timeout" {
  default = 30  # seconds
}

variable "provisioned_concurrency" {
  default = 2  # Pre-warmed Lambda executions
}
```

### EC2 Stack Variables

```hcl
variable "image_uri" {
  description = "EC2 container image URI"
  # Example: "996549485948.dkr.ecr.eu-central-1.amazonaws.com/podinfo-demo/podinfo@sha256:..."
}

variable "instance_type" {
  default = "t3.small"
}

variable "asg_desired_capacity" {
  default = 2
}

variable "asg_min_size" {
  default = 2
}

variable "asg_max_size" {
  default = 4
}

variable "podinfo_port" {
  default = 9898
}
```

## Network Configuration

### VPC CIDR Blocks

| Environment | VPC CIDR | Public Subnets | Private Subnets |
|-------------|----------|----------------|-----------------|
| dev | 10.0.0.0/16 | 10.0.1.0/24, 10.0.2.0/24 | 10.0.11.0/24, 10.0.12.0/24 |
| prod | 10.1.0.0/16 | 10.1.1.0/24, 10.1.2.0/24 | 10.1.11.0/24, 10.1.12.0/24 |

### Availability Zones

**eu-central-1:**
- AZ1: `eu-central-1a`
- AZ2: `eu-central-1b`

### Security Groups

| Name | Ingress | Egress | Purpose |
|------|---------|--------|---------|
| `podinfo-demo-alb-sg-dev` | 80/tcp from 0.0.0.0/0 | All | ALB public access |
| `podinfo-demo-ec2-sg-dev` | 9898/tcp from ALB SG | All | EC2 instances |

## CodeDeploy Configuration

### Lambda Deployment

- **Type:** Blue/Green
- **Traffic Shifting:** Canary10Percent5Minutes
- **Rollback:** Automatic on CloudWatch alarms
- **Alarm:** `podinfo-demo-lambda-errors-dev`

### EC2 Deployment

- **Type:** Blue/Green
- **Traffic Shifting:** CodeDeployDefault.AllAtOnce
- **Green Fleet Provisioning:** Copy Auto Scaling Group
- **Termination:** 5 minutes after successful deployment
- **Rollback:** Automatic on CloudWatch alarms
- **Alarms:** 
  - `podinfo-demo-ec2-target-5xx-dev`
  - `podinfo-demo-ec2-unhealthy-targets-dev`

## Monitoring Configuration

### CloudWatch Log Retention

| Log Group | Retention |
|-----------|-----------|
| `/aws/lambda/podinfo-demo-podinfo-dev` | 7 days |
| `/aws/ec2/dev/docker` | 7 days |

### Metric Namespaces

- `AWS/Lambda` - Lambda metrics
- `AWS/ApiGateway` - API Gateway metrics
- `AWS/ApplicationELB` - ALB metrics
- `AWS/AutoScaling` - ASG metrics
- `AWS/CodeDeploy` - Deployment metrics
- `CWAgent` - EC2 custom metrics (if CloudWatch Agent enabled)

### Alarm Thresholds

| Alarm | Metric | Threshold | Period |
|-------|--------|-----------|--------|
| Lambda Errors | Errors (Sum) | > 5 | 1 minute |
| Lambda Throttles | Throttles (Sum) | > 3 | 1 minute |
| Lambda Duration P99 | Duration (P99) | > 5000ms | 1 minute |
| API Gateway 5xx | 5XXError (Sum) | > 5 | 1 minute |
| ALB Target 5xx | HTTPCode_Target_5XX_Count | > 10 | 2 minutes |
| Unhealthy Targets | UnHealthyHostCount (Avg) | > 0 | 2 minutes |

## GitHub Actions Configuration

### Repository Secrets

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AWS_ROLE_ARN` | OIDC role for GitHub Actions | `arn:aws:iam::996549485948:role/github-actions-role` |

### Workflow Triggers

**build.yml:**
- Push to `main` branch
- Changes in `app/podinfo/**`, `Dockerfile`, `.github/workflows/build.yml`
- Manual dispatch

**deploy.yml:**
- Workflow run completion (build.yml success)
- Manual dispatch with parameters:
  - `image_digest`: Image digest to deploy
  - `environment`: Target environment (dev/prod)

## Cost Estimates

### Monthly Cost Breakdown (dev environment)

| Service | Configuration | Estimated Cost |
|---------|---------------|----------------|
| Lambda | 512MB, 2 provisioned concurrency | ~$20 |
| API Gateway | HTTP API, low traffic | ~$1 |
| EC2 | 2x t3.small instances | ~$30 |
| ALB | Basic usage | ~$20 |
| NAT Gateway | 2 AZs | ~$60 |
| ECR | 10 images, ~1GB total | ~$0.10 |
| CloudWatch | Logs, metrics, alarms | ~$10 |
| Secrets Manager | 1 secret | ~$0.40 |
| S3 | Logs, artifacts | ~$1 |
| **Total** | | **~$142/month** |

**Note:** Costs vary based on traffic. NAT Gateway is the largest cost component. Consider VPC endpoints to reduce NAT costs.

## Compliance and Security

### Encryption

- **At Rest:** All data encrypted with KMS CMK
  - CloudWatch Logs
  - S3 buckets
  - Secrets Manager
  - EBS volumes
  
- **In Transit:** TLS 1.2+ for all external communication
  - API Gateway: HTTPS only
  - ALB: HTTP (can upgrade to HTTPS with ACM certificate)

### IAM Policies

- **Least Privilege:** Each service has minimal required permissions
- **No Long-lived Credentials:** OIDC for GitHub Actions
- **Session Tokens:** Temporary credentials via STS

### Audit Logging

- **CloudTrail:** All API calls logged (enabled globally)
- **VPC Flow Logs:** Network traffic logged (optional, disabled for cost)
- **ALB Access Logs:** All HTTP requests logged to S3

## References

- [Podinfo GitHub Repository](https://github.com/stefanprodan/podinfo)
- [AWS Lambda Web Adapter](https://github.com/awslabs/aws-lambda-web-adapter)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS CodeDeploy Documentation](https://docs.aws.amazon.com/codedeploy/)
- [Cosign Documentation](https://docs.sigstore.dev/cosign/overview/)