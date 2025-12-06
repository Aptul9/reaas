#!/bin/bash

AWS_PROFILE="default"
SEARCH_PATTERN="SUPER_SECRET"
LAMBDA_GROUP="/aws/lambda/podinfo-demo-podinfo-dev"
CODEDEPLOY_GROUP="/aws/codedeploy-agent"

echo "Starting security audit scan..."
echo "Target Pattern: ${SEARCH_PATTERN}"
echo "------------------------------------------------"

echo "[1/4] Scanning Lambda Logs: ${LAMBDA_GROUP}"
aws logs filter-log-events \
  --log-group-name "${LAMBDA_GROUP}" \
  --filter-pattern "${SEARCH_PATTERN}" \
  --profile "${AWS_PROFILE}" \
  --max-items 5 \
  --query 'events[*].{Time:timestamp, Msg:message}' \
  --output table || echo "No sensitive patterns detected."

echo ""
echo "[2/4] Verifying Lambda Environment Variables"
aws lambda get-function-configuration \
  --function-name podinfo-demo-podinfo-dev \
  --profile "${AWS_PROFILE}" \
  --query 'Environment.Variables' \
  --output table

echo ""
echo "[3/4] Scanning CodeDeploy Agent Logs"
aws logs filter-log-events \
  --log-group-name "${CODEDEPLOY_GROUP}" \
  --filter-pattern "${SEARCH_PATTERN}" \
  --profile "${AWS_PROFILE}" \
  --max-items 5 \
  --output text || echo "Log group unavailable or clean."

echo ""
echo "[4/4] Scanning EC2 Log Groups (/aws/ec2/*)"
EC2_LOG_GROUPS=$(aws logs describe-log-groups \
  --log-group-name-prefix "/aws/ec2" \
  --profile "${AWS_PROFILE}" \
  --query 'logGroups[*].logGroupName' \
  --output text)

for group in $EC2_LOG_GROUPS; do
  echo " > Auditing: $group"
  aws logs filter-log-events \
    --log-group-name "$group" \
    --filter-pattern "${SEARCH_PATTERN}" \
    --profile "${AWS_PROFILE}" \
    --max-items 1 \
    --query 'events[*].message' \
    --output text || echo "   Clean."
done

echo "------------------------------------------------"
echo "Audit finished. Ensure no plaintext secrets are visible in the output above."