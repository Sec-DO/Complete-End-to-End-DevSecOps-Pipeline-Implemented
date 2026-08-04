#!/bin/bash
# SecDO Automated Rollback Script
# Executed automatically or manually when a deployment or health probe fails.

set -e

SWARM_DIR="/home/ubuntu/secdo-swarm"
STABLE_TAG="latest"

echo "================================================="
echo "ALERT: Health Check / Deployment Failure Detected!"
echo "Initiating Automated Zero-Downtime Rollback..."
echo "================================================="

if [ -d "$SWARM_DIR" ]; then
    cd "$SWARM_DIR"
    
    echo "1. Falling back to stable container tag: ${STABLE_TAG}..."
    export IMAGE_TAG="${STABLE_TAG}"
    
    echo "2. Re-deploying Docker Compose/Swarm stack with stable image..."
    if command -v docker-compose &>/dev/null || docker compose version &>/dev/null; then
        docker compose -f docker-swarm.yml up -d --remove-orphans
    else
        docker stack deploy -c docker-swarm.yml secdo_app --with-registry-auth
    fi
    
    echo "3. Polling rollback health status..."
    sleep 5
    ROLLBACK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health.php || echo "000")
    
    if [ "$ROLLBACK_STATUS" -eq 200 ]; then
        echo "SUCCESS: Rollback complete. Application restored to stable version (HTTP 200 OK)."
        exit 0
    else
        echo "EMERGENCY: Rollback failed! Checking container logs..."
        docker compose -f docker-swarm.yml logs --tail=50 2>/dev/null || docker service logs secdo_app_app --tail=50 2>/dev/null || true
        exit 2
    fi
else
    echo "ERROR: Swarm deployment directory $SWARM_DIR does not exist."
    exit 1
fi
