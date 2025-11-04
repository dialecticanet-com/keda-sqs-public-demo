#!/bin/bash

set -e

echo "========================================"
echo "KEDA SQS Demo - Message Producer"
echo "========================================"
echo ""

CLUSTER_NAME="keda-demo"
QUEUE_URL="http://localhost:4566/000000000000/demo-queue"
MESSAGES_PER_SECOND=20
ENDPOINT_URL="http://localhost:4566"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ Error: AWS CLI is not installed. Please install it first:"
    echo "   brew install awscli"
    exit 1
fi

# Check if fortune is installed (optional)
if ! command -v fortune &> /dev/null; then
    echo "⚠️  Warning: fortune is not installed. Using fallback messages."
    echo "   To install fortune: brew install fortune"
    echo ""
    USE_FORTUNE=false
else
    USE_FORTUNE=true
fi

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "❌ Error: Cluster '${CLUSTER_NAME}' does not exist."
    echo "   Please run ./scripts/01-setup-kind.sh first."
    exit 1
fi

echo "🔌 Setting up port-forward to LocalStack..."
echo "   (This will run in the background)"
echo ""

# Kill any existing port-forward on 4566
pkill -f "port-forward.*localstack.*4566" 2>/dev/null || true
sleep 1

# Start port-forward in background
kubectl port-forward svc/localstack 4566:4566 > /dev/null 2>&1 &
PORT_FORWARD_PID=$!

# Wait for port-forward to be ready
echo "⏳ Waiting for port-forward to be ready..."
sleep 3

# Function to cleanup on exit
cleanup() {
    echo ""
    echo ""
    echo "🛑 Stopping message producer..."
    if [ ! -z "$PORT_FORWARD_PID" ]; then
        kill $PORT_FORWARD_PID 2>/dev/null || true
    fi
    echo "✅ Cleanup complete"
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# Verify connection to LocalStack
echo "🔍 Verifying connection to LocalStack..."
if ! aws --endpoint-url="${ENDPOINT_URL}" sqs list-queues > /dev/null 2>&1; then
    echo "❌ Error: Cannot connect to LocalStack. Make sure it's running."
    exit 1
fi

echo "✅ Connected to LocalStack successfully!"
echo ""
echo "📬 Queue URL: ${QUEUE_URL}"
echo "⚡ Rate: ${MESSAGES_PER_SECOND} messages/second"
echo ""
echo "🚀 Starting message production... (Press Ctrl+C to stop)"
echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

# Calculate sleep time between messages
SLEEP_TIME=$(echo "scale=4; 1 / ${MESSAGES_PER_SECOND}" | bc)

MESSAGE_COUNT=0
START_TIME=$(date +%s)

# Fallback messages if fortune is not available
FALLBACK_MESSAGES=(
    "The best way to predict the future is to invent it."
    "Do or do not. There is no try."
    "In the middle of difficulty lies opportunity."
    "The only way to do great work is to love what you do."
    "Innovation distinguishes between a leader and a follower."
    "Stay hungry, stay foolish."
    "The future belongs to those who believe in the beauty of their dreams."
    "Success is not final, failure is not fatal: it is the courage to continue that counts."
    "Believe you can and you're halfway there."
    "It does not matter how slowly you go as long as you do not stop."
)

# Produce messages continuously
while true; do
    # Get fortune message or use fallback
    if [ "$USE_FORTUNE" = true ]; then
        FORTUNE_TEXT=$(fortune -s 2>/dev/null || echo "${FALLBACK_MESSAGES[$((RANDOM % ${#FALLBACK_MESSAGES[@]}))]}")
    else
        FORTUNE_TEXT="${FALLBACK_MESSAGES[$((RANDOM % ${#FALLBACK_MESSAGES[@]}))]}"
    fi

    # Create JSON payload
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    MESSAGE_BODY=$(jq -n \
        --arg msg "$FORTUNE_TEXT" \
        --arg ts "$TIMESTAMP" \
        '{message: $msg, timestamp: $ts}')

    # Send message to SQS
    aws --endpoint-url="${ENDPOINT_URL}" \
        sqs send-message \
        --queue-url "${QUEUE_URL}" \
        --message-body "${MESSAGE_BODY}" \
        > /dev/null 2>&1

    MESSAGE_COUNT=$((MESSAGE_COUNT + 1))
    ELAPSED=$(($(date +%s) - START_TIME))

    if [ $ELAPSED -gt 0 ]; then
        RATE=$(echo "scale=2; ${MESSAGE_COUNT} / ${ELAPSED}" | bc)
    else
        RATE="0.00"
    fi

    # Print status every 10 messages
    if [ $((MESSAGE_COUNT % 10)) -eq 0 ]; then
        echo "📊 Sent ${MESSAGE_COUNT} messages | Rate: ${RATE} msg/s | Last: ${FORTUNE_TEXT:0:60}..."
    fi

    # Sleep to maintain desired rate
    sleep "${SLEEP_TIME}"
done
