#!/bin/bash
# SecDO Automated Deployment Script
# Executed on Application EC2 instance during CI/CD execution.

set -e

ECR_REPO_URI="${1}"
IMAGE_TAG="${2}"
AWS_REGION="${3:-us-east-1}"
DEPLOY_DIR="$HOME/secdo-deploy"

if [ -z "$ECR_REPO_URI" ] || [ -z "$IMAGE_TAG" ]; then
    echo "Usage: ./deploy.sh <ECR_REPO_URI> <IMAGE_TAG> [AWS_REGION]"
    exit 1
fi

echo "================================================="
echo "SecDO Production Deployment Execution"
echo "ECR URI: ${ECR_REPO_URI}"
echo "Image Tag: ${IMAGE_TAG}"
echo "================================================="

# 1. Login to AWS ECR using IAM Role STS token
echo "1. Authenticating to ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REPO_URI%%/*}"

# 2. Pull Target Container Image
echo "2. Pulling Docker image: ${ECR_REPO_URI}:${IMAGE_TAG}..."
docker pull "${ECR_REPO_URI}:${IMAGE_TAG}"

# 3. Prepare Deployment Directory
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

# 4. Deploy via Docker Compose
export ECR_REPO_URI="${ECR_REPO_URI}"
export IMAGE_TAG="${IMAGE_TAG}"

echo "3. Updating production stack..."
docker compose up -d --remove-orphans

# 5. Run Application Health probe
echo "4. Running readiness probe..."
chmod +x ../scripts/health-check.sh 2>/dev/null || true
if ! ../scripts/health-check.sh "http://localhost/health.php"; then
    echo "CRITICAL: Health Probe Failed! Triggering Rollback..."
    ../scripts/rollback.sh "$DEPLOY_DIR"
    exit 1
fi

echo "SUCCESS: Production Deployment Completed Successfully!"
