# Multi-Target Deployment Architecture for Podinfo

This repository contains the infrastructure-as-code (Terraform) and CI/CD pipelines (GitHub Actions) required to deploy the Podinfo application to AWS. The system implements a dual-target strategy, deploying the same container artifact simultaneously to AWS Lambda and an EC2 Auto Scaling Group.

## Architecture Overview

The architecture ensures high availability and zero-downtime deployments using Blue/Green strategies across two distinct compute runtimes.

**1. Lambda Target**
- Hosted via API Gateway (HTTP API).
- Runs the containerized application using the AWS Lambda Web Adapter.
- Uses CodeDeploy for canary deployments (shifting traffic linearly).

**2. EC2 Target**
- Hosted on an Auto Scaling Group behind an Application Load Balancer (ALB).
- Runs the Docker container directly on Amazon Linux 2023 instances.
- Uses CodeDeploy for blue/green replacements with automatic rollback capabilities.

### System Capabilities

- **Supply Chain Security:** Enforces OIDC authentication for pipeline operations, Cosign image signing, and SBOM generation.
- **Immutable Artifacts:** Deployments utilize specific image digests rather than mutable tags.
- **Automated Rollback:** Health checks and CloudWatch alarms trigger immediate rollback upon failure.
- **Secret Management:** Runtime secret retrieval via AWS Secrets Manager.
- **Observability:** Centralized CloudWatch dashboards, structured logging, and metric alarms.
- **Environment Isolation:** Complete network isolation between Development and Production environments using separate VPCs.

## Repository Structure

```text
.
├── .github/workflows/       # CI/CD definitions (Build, Deploy, Promote)
├── infra/
│   ├── global/              # Shared resources (ECR, OIDC, KMS, Dashboards)
│   ├── environments/
│   │   ├── dev/             # Development stack (Lambda + EC2)
│   │   └── prod/            # Production stack (Lambda + EC2)
├── docs/                    # Architecture diagrams
├── ENVIRONMENT.md           # Configuration reference
├── SCALABILITY.md           # scaling strategy and roadmap
├── PROD_PROMOTION_CHECKLIST.md # Manual gate validation steps
└── README.md
```

## Setup and Installation

### Prerequisites

- AWS Account and CLI configured (Profile: `default` recommended).
- Terraform v1.5.0+.
- Docker Desktop or Engine.
- GitHub CLI (optional, for workflow dispatch).

### 1. AWS Configuration

Ensure your local AWS profile is active:

```bash
aws configure --profile default
aws sts get-caller-identity --profile default
```

### 2. Infrastructure Deployment

Deploy the stacks in the following order to resolve dependencies correctly.

**Phase 1: Shared Resources**
Initialize the global stack to create the ECR registry and IAM roles.

```bash
cd infra/global
terraform init -backend-config=backend.tfvars
terraform apply
```

*Note the ECR Repository URL and IAM Role ARN from the outputs.*

**Phase 2: Development Environment**

```bash
# Lambda Stack
cd ../environments/dev/lambda
terraform init -backend-config=backend.tfvars
terraform apply

# EC2 Stack
cd ../ec2
terraform init -backend-config=backend.tfvars
terraform apply
```

**Phase 3: Production Environment**

```bash
# Lambda Stack
cd ../../prod/lambda
terraform init -backend-config=backend.tfvars
terraform apply

# EC2 Stack
cd ../ec2
terraform init -backend-config=backend.tfvars
terraform apply
```

### 3. Repository Configuration

Set the following Secret in your GitHub repository settings:

`AWS_ROLE_ARN`: The ARN output from the `infra/global` stack.

## CI/CD Workflow

### Development Deployment
Commits to the `main` branch trigger the automated pipeline:
1.  **Build:** Compiles the Go binary and builds the Docker image.
2.  **Sign:** Signs the image using Cosign (Keyless).
3.  **Publish:** Pushes the artifact to ECR with a unique digest.
4.  **Deploy:** Updates the Dev Lambda (Canary) and Dev EC2 (Blue/Green) environments.
5.  **Verify:** Executes smoke tests against the new deployment.

### Production Promotion
Production deployment is a manual process that promotes a validated digest from Development.

1.  Locate the digest from a successful Dev deployment.
2.  Trigger the **Promote to Production** workflow.
3.  Confirm the validation checklist.

Refer to `PROD_PROMOTION_CHECKLIST.md` for the mandatory verification steps.

## Operational Procedures

### Monitoring and Logs
Access the unified CloudWatch dashboard via the URL provided in the `infra/global` terraform outputs.

**Log Access:**
- Lambda: `/aws/lambda/podinfo-demo-podinfo-{env}`
- EC2: Accessed via SSM Session Manager or CloudWatch Logs (if agent configured).

### Secret Rotation
To rotate the application secret:

```bash
aws secretsmanager update-secret \
  --secret-id /dockyard/SUPER_SECRET_TOKEN \
  --secret-string "$(openssl rand -base64 32)"
```

*Note: Applications fetch secrets at runtime; a restart may be required depending on caching strategies, though new containers will pick up the new value immediately.*

### Infrastructure Teardown
To destroy all resources, execute the destruction commands in reverse order (Prod -> Dev -> Global).

**Important:** S3 buckets containing access logs and deployment artifacts must be emptied before destruction.

```bash
# Example bucket cleanup
aws s3 rm s3://bucket-name --recursive

# Destroy stacks
cd infra/environments/prod/ec2 && terraform destroy
# ... repeat for other stacks ...
```

## Design Rationale

**Environment Isolation**
We utilize separate VPCs (10.0.0.0/16 for Dev, 10.1.0.0/16 for Prod) to ensure network-level isolation. This prevents accidental cross-environment connectivity and aligns with security best practices.

**Provisioned Concurrency**
Production Lambda functions are configured with Provisioned Concurrency. This eliminates cold-start latency (reducing P99 from ~3s to <100ms) at the cost of a small monthly fee.

**Digest-Based Promotion**
To guarantee that the exact code tested in Development reaches Production, we rely exclusively on container image digests (`sha256:...`). Mutable tags (e.g., `latest`) are strictly avoided in deployment logic.

## Security Compliance

- **Authentication:** All CI/CD operations use OIDC federation; no static IAM access keys are stored.
- **Encryption:** Data at rest is encrypted via KMS; data in transit uses TLS.
- **Least Privilege:** IAM policies are scoped strictly to the resources required for each service.
- **Log Sanitation:** CloudWatch Logs are configured to mask sensitive data patterns.

## Documentation References

- [Environment Configuration (ENVIRONMENT.md)](ENVIRONMENT.md)
- [Scalability Roadmap (SCALABILITY.md)](SCALABILITY.md)
- [Promotion Checklist (PROD_PROMOTION_CHECKLIST.md)](PROD_PROMOTION_CHECKLIST.md)