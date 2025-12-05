#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Initializing system configuration..."

# 1. System Updates & Prerequisites
dnf update -y
dnf install -y docker ruby wget

# 2. Docker Daemon Configuration
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# 3. CodeDeploy Agent Installation
cd /tmp
log "Installing CodeDeploy Agent..."
wget "https://aws-codedeploy-${AWS_REGION}.s3.${AWS_REGION}.amazonaws.com/latest/codedeploy-agent.noarch.rpm"
dnf install -y ./codedeploy-agent.noarch.rpm

systemctl enable codedeploy-agent
systemctl start codedeploy-agent

# Wait loop for agent readiness
MAX_RETRIES=6
for ((i=1; i<=MAX_RETRIES; i++)); do
    if systemctl is-active --quiet codedeploy-agent; then
        log "CodeDeploy agent is active."
        break
    fi
    log "Waiting for agent startup ($i/$MAX_RETRIES)..."
    sleep 10
done

# 4. Container Launch
log "Authenticating with ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

log "Retrieving runtime secrets..."
set +x # Supress output for security
SECRET_PAYLOAD=$(aws secretsmanager get-secret-value \
  --secret-id /dockyard/SUPER_SECRET_TOKEN \
  --region "${AWS_REGION}" \
  --query SecretString \
  --output text 2>/dev/null) || SECRET_PAYLOAD="error-fetching-secret"

log "Starting Podinfo container..."
docker run -d \
  --name podinfo \
  --restart unless-stopped \
  -p "${PODINFO_PORT}:9898" \
  -e PORT=9898 \
  -e LOG_LEVEL=info \
  -e SUPER_SECRET_TOKEN="$SECRET_PAYLOAD" \
  "${IMAGE_URI}"

# Cleanup secret from memory variable
unset SECRET_PAYLOAD
set -x

# 5. Validation
sleep 15
if curl -s "http://localhost:${PODINFO_PORT}/healthz" > /dev/null; then
    log "Health check passed. System ready."
else
    log "CRITICAL: Health check failed. Inspect docker logs."
fi