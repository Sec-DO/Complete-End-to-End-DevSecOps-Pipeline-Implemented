#!/bin/bash
# SecDO Automated Rollback Script
# Triggered automatically when post-deployment health check fails.

set -e

DEPLOY_DIR="${1:-$HOME/secdo-deploy}"
STABLE_TAG="latest"

echo "================================================="
echo "ALERT: Health Check Failure Detected!"
echo "Initiating Automated Zero-Downtime Rollback..."
echo "================================================="

if [ -d "$DEPLOY_DIR" ]; then
    cd "$DEPLOY_DIR"
    
    echo "1. Falling back to stable container tag: ${STABLE_TAG}..."
    export IMAGE_TAG="${STABLE_TAG}"
    
    echo "2. Re-deploying Docker Compose stack with stable image..."
    docker compose up -d --remove-orphans
    
    echo "3. Polling rollback health status..."
    sleep 5
    ROLLBACK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health.php || echo "000")
    
    if [ "$ROLLBACK_STATUS" -eq 200 ]; then
        echo "SUCCESS: Rollback complete. Application restored to stable version."
        exit 0
    else
        echo "EMERGENCY: Rollback failed! Application remains degraded. Check container logs."
        docker compose logs --tail=50
        exit 2
    fi
else
    echo "ERROR: Deployment directory $DEPLOY_DIR does not exist."
    exit 1
fi
