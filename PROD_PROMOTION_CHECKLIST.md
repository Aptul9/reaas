# Production Promotion Checklist

Complete these checks before promoting artifacts from dev to prod.

## 1. Pre-Deployment Validation

Artifact Checks
- [ ] Image digest signature verified (cosign)
- [ ] SBOM confirmed in ECR
- [ ] ECR image scan shows 0 critical vulnerabilities
- [ ] Dev build pipeline passed successfully

Dev Environment Status
- [ ] Smoke tests passed (Lambda & EC2)
- [ ] CloudWatch alarms are clear
- [ ] /healthz endpoints returning 200 OK on both targets
- [ ] Secrets rotation verified
- [ ] No application errors in logs (last 1 hour)

Readiness
- [ ] Prod is stable (no active incidents)
- [ ] No other deployments in progress
- [ ] Approval granted
- [ ] Rollback digest identified
- [ ] On-call notified

## 2. Deployment Steps

Monitoring
- [ ] Open CloudWatch Dashboard
- [ ] Check Lambda provisioned concurrency metrics
- [ ] Watch ALB target health status

Canary Phase (10% Traffic)
- [ ] P99 Latency within limits (<500ms Lambda, <1s ALB)
- [ ] Zero 5xx errors
- [ ] No alarms triggered
- [ ] Logs are clean

Full Rollout
- [ ] All ALB targets healthy
- [ ] Lambda 'live' alias updated
- [ ] Error rates remain flat

## 3. Post-Deployment

Immediate (5 mins)
- [ ] Manual curl/smoke test Lambda endpoint
- [ ] Manual curl/smoke test ALB endpoint
- [ ] Confirm correlation IDs in logs
- [ ] Grep logs for secret leakage (SUPER_SECRET_TOKEN)

Stability (30 mins)
- [ ] No alarms
- [ ] Latency stable
- [ ] Blue fleet terminated successfully
- [ ] ASG cleanup finished

Finalize
- [ ] Update ENVIRONMENT.md
- [ ] Tag git commit
- [ ] Notify team of success

## Rollback Triggers

Rollback immediately if:
- 5xx errors > 1% (2 mins)
- P99 latency > 2x baseline (3 mins)
- Any critical Alarm fires
- Container crash loops
- Lambda throttling > 0.5%

Command:
aws deploy stop-deployment --deployment-id <ID> --auto-rollback-enabled --profile milodev

## Success Criteria

- [ ] All checks passed
- [ ] 30 mins silence (no alarms)
- [ ] Error rate < 0.1%
- [ ] Latency within 10% of baseline

Approved by: ___________________________
Date: ___________________________
Digest: ___________________________