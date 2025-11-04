#!/bin/bash

echo "========================================"
echo "KEDA SQS Demo - Job Monitor"
echo "========================================"
echo ""
echo "Watching Kubernetes Jobs created by KEDA..."
echo "Press Ctrl+C to exit"
echo ""

CLUSTER_NAME="keda-demo"

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "❌ Error: Cluster '${CLUSTER_NAME}' does not exist."
    echo "   Please run ./scripts/01-setup-kind.sh first."
    exit 1
fi

# Ensure we're using the correct context
kubectl config use-context "kind-${CLUSTER_NAME}" > /dev/null 2>&1

# Check if watch command is available
if command -v watch &> /dev/null; then
    # Use watch command for auto-refresh
    watch -n 1 "kubectl get jobs -l app=sqs-consumer --sort-by=.metadata.creationTimestamp && echo '' && echo 'ScaledJob Status:' && kubectl get scaledjob sqs-consumer-scaledobject 2>/dev/null && echo '' && echo 'Active Jobs:' && kubectl get jobs -l app=sqs-consumer --field-selector status.successful=0 --no-headers 2>/dev/null | wc -l | xargs echo && echo 'Completed Jobs:' && kubectl get jobs -l app=sqs-consumer --field-selector status.successful=1 --no-headers 2>/dev/null | wc -l | xargs echo"
else
    # Fallback: manual refresh loop
    echo "⚠️  'watch' command not found. Using manual refresh (every 2 seconds)."
    echo "   To install: brew install watch"
    echo ""

    while true; do
        clear
        echo "========================================"
        echo "KEDA SQS Demo - Job Monitor"
        echo "========================================"
        echo ""
        echo "Jobs (sorted by creation time):"
        echo ""
        kubectl get jobs -l app=sqs-consumer --sort-by=.metadata.creationTimestamp

        echo ""
        echo "ScaledJob Status:"
        kubectl get scaledjob sqs-consumer-scaledobject 2>/dev/null || echo "ScaledJob not found"

        echo ""
        echo "Statistics:"
        ACTIVE=$(kubectl get jobs -l app=sqs-consumer --field-selector status.successful=0 --no-headers 2>/dev/null | wc -l | xargs)
        COMPLETED=$(kubectl get jobs -l app=sqs-consumer --field-selector status.successful=1 --no-headers 2>/dev/null | wc -l | xargs)
        echo "  Active Jobs: ${ACTIVE}"
        echo "  Completed Jobs: ${COMPLETED}"

        echo ""
        echo "Last updated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Press Ctrl+C to exit"

        sleep 2
    done
fi
