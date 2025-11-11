#!/bin/bash

echo "========================================"
echo "KEDA SQS Demo - SQS Backlog Monitor"
echo "========================================"
echo ""
echo "Watching SQS queue backlog..."
echo "Press Ctrl+C to exit"
echo ""

CLUSTER_NAME="keda-demo"
QUEUE_NAME="demo-queue"

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "❌ Error: Cluster '${CLUSTER_NAME}' does not exist."
    echo "   Please run ./scripts/01-setup-kind.sh first."
    exit 1
fi

# Ensure we're using the correct context
kubectl config use-context "kind-${CLUSTER_NAME}" > /dev/null 2>&1

# Check if LocalStack pod is running
if ! kubectl get pod -l app=localstack --no-headers 2>/dev/null | grep -q "Running"; then
    echo "❌ Error: LocalStack is not running."
    echo "   Please run ./scripts/02-setup-localstack.sh first."
    exit 1
fi

# Function to get queue metrics
get_queue_metrics() {
    # Get queue attributes from LocalStack
    ATTRS=$(kubectl exec deployment/localstack -- \
        awslocal sqs get-queue-attributes \
        --queue-url "http://localhost:4566/000000000000/${QUEUE_NAME}" \
        --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible \
        --output json 2>/dev/null)

    if [ $? -eq 0 ]; then
        VISIBLE=$(echo "$ATTRS" | grep -o '"ApproximateNumberOfMessages":"[0-9]*"' | grep -o '[0-9]*')
        NOT_VISIBLE=$(echo "$ATTRS" | grep -o '"ApproximateNumberOfMessagesNotVisible":"[0-9]*"' | grep -o '[0-9]*')

        # Default to 0 if empty
        VISIBLE=${VISIBLE:-0}
        NOT_VISIBLE=${NOT_VISIBLE:-0}

        TOTAL=$((VISIBLE + NOT_VISIBLE))

        echo "$VISIBLE|$NOT_VISIBLE|$TOTAL"
    else
        echo "0|0|0"
    fi
}

# Check if watch command is available
if command -v watch &> /dev/null; then
    # Use watch command for auto-refresh
    watch -n 1 'kubectl exec deployment/localstack -- awslocal sqs get-queue-attributes --queue-url "http://localhost:4566/000000000000/demo-queue" --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible --output json 2>/dev/null | grep -E "ApproximateNumberOfMessages" | head -2 && echo "" && echo "Queue: demo-queue" && echo "Last updated: $(date +"%Y-%m-%d %H:%M:%S")"'
else
    # Fallback: manual refresh loop
    echo "⚠️  'watch' command not found. Using manual refresh (every 2 seconds)."
    echo "   To install: brew install watch"
    echo ""

    while true; do
        clear
        echo "========================================"
        echo "KEDA SQS Demo - SQS Backlog Monitor"
        echo "========================================"
        echo ""

        METRICS=$(get_queue_metrics)
        VISIBLE=$(echo "$METRICS" | cut -d'|' -f1)
        NOT_VISIBLE=$(echo "$METRICS" | cut -d'|' -f2)
        TOTAL=$(echo "$METRICS" | cut -d'|' -f3)

        echo "Queue: ${QUEUE_NAME}"
        echo ""
        echo "📊 Message Statistics:"
        echo "  ├─ Available Messages:    ${VISIBLE}"
        echo "  ├─ In-Flight Messages:    ${NOT_VISIBLE}"
        echo "  └─ Total Pending:         ${TOTAL}"
        echo ""
        echo "Last updated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Press Ctrl+C to exit"

        sleep 2
    done
fi
