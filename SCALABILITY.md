# Scalability and Performance Strategy

## 1. Multi-Region Active/Active Architecture

### Overview
This design outlines the path to scale from the current single-region setup to a dual-region active/active configuration (eu-central-1 + us-east-1) to enhance availability and reduce global latency.

### Core Components

**1. Global Traffic Routing (Route 53)**
- **Strategy:** Latency-Based Routing (LBR).
- **Configuration:** Route 53 directs user traffic to the region providing the lowest network latency.
- **Failover:** Health checks on ALB and API Gateway endpoints trigger DNS failover if a region becomes unresponsive.

**2. Artifact Replication (ECR)**
- **Primary:** eu-central-1 (Build Region).
- **Secondary:** us-east-1 (Replication Target).
- **Mechanism:** AWS ECR Cross-Region Replication rules ensure images are immediately available in the secondary region for deployment.

**3. Account Segmentation**
- **Shared Services:** Hosts ECR and CI/CD runners.
- **Dev:** Sandbox environment for testing.
- **Prod:** Hosting production workloads across both regions.
- **Goal:** Strict isolation of production data and blast radius containment.

**4. Data Synchronization**
- **Secrets:** AWS Secrets Manager replication.
- **Artifacts:** S3 Cross-Region Replication for deployment bundles.

### Trade-off Analysis

| Component | Cost Impact | Operational Risk | Mitigation |
|-----------|-------------|------------------|------------|
| Compute | 2x cost (Dual region) | Capacity fragmentation | Reserved Instances |
| Data | Transfer fees | Replication lag | Monitoring replication metrics |
| Operations | High overhead | Config drift | Strict IaC (Terraform) enforcement |

### Implementation Plan
- **Phase 1:** Terraform stack replication to secondary region (3 days).
- **Phase 2:** Network routing and health check configuration (1 day).
- **Phase 3:** Failure simulation and cutover testing (1 day).

---

## 2. Implemented Optimization: Lambda Provisioned Concurrency

### Problem
Analysis showed Lambda cold starts causing latency spikes (500-1000ms) during traffic bursts, negatively impacting the P99 metric.

### Solution
Enabled Provisioned Concurrency on the production alias. This maintains a pool of initialized execution environments ready to accept traffic immediately.

### Terraform Configuration

```hcl
resource "aws_lambda_provisioned_concurrency_config" "main" {
  function_name                     = aws_lambda_function.main.function_name
  # Production targets 2 instances, Development targets 1
  provisioned_concurrent_executions = var.environment == "prod" ? 2 : 1
  qualifier                         = aws_lambda_alias.live.name

  depends_on = [aws_lambda_alias.live]
}