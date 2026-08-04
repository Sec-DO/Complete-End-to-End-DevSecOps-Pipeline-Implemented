#!/bin/bash
# SecDO Application Health Probe Script
# Polls http://localhost/health.php up to MAX_RETRIES times.

set -e

MAX_RETRIES=10
RETRY_INTERVAL=3
APP_URL="${1:-http://localhost/health.php}"

echo "================================================="
echo "SecDO Health Check Probe Initiated"
echo "Target Endpoint: ${APP_URL}"
echo "================================================="

for ((i=1; i<=MAX_RETRIES; i++)); do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${APP_URL}" || echo "000")
    
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo "SUCCESS: Health probe returned HTTP 200 OK on attempt $i/$MAX_RETRIES."
        exit 0
    else
        echo "WARNING: Attempt $i/$MAX_RETRIES failed with HTTP Status: $HTTP_CODE. Retrying in ${RETRY_INTERVAL}s..."
        sleep "$RETRY_INTERVAL"
    fi
done

echo "CRITICAL: Health Probe Failed after $MAX_RETRIES attempts!"
exit 1
