#!/bin/bash

# Don't exit on error immediately - we want to handle errors gracefully
set +e

echo "========================================"
echo "KEDA SQS Demo - Message Producer"
echo "(Running inside cluster)"
echo "========================================"
echo ""

QUEUE_NAME="demo-queue"
QUEUE_URL="http://localhost:4566/000000000000/demo-queue"
MESSAGES_COUNT=${1:-100}

echo "📬 Queue: ${QUEUE_NAME}"
echo "📊 Messages to send: ${MESSAGES_COUNT}"
echo ""

# Fallback messages
MESSAGES=(
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

echo "🚀 Sending messages..."
echo ""

for i in $(seq 1 $MESSAGES_COUNT); do
    # Pick a random message
    MSG_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    MESSAGE="${MESSAGES[$MSG_INDEX]}"

    # Create JSON payload
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    MESSAGE_BODY="{\"message\": \"$MESSAGE\", \"timestamp\": \"$TIMESTAMP\", \"id\": $i}"

    # Send message using kubectl exec
    RESULT=$(kubectl exec -n default deploy/localstack -- \
        awslocal sqs send-message \
        --queue-url "$QUEUE_URL" \
        --message-body "$MESSAGE_BODY" 2>&1)

    if [ $? -eq 0 ]; then
        echo "✅ Message $i/$MESSAGES_COUNT sent: ${MESSAGE:0:60}..."
    else
        echo "❌ Failed to send message $i"
        echo "   Error: $RESULT"
        exit 1
    fi

    # Small delay to avoid overwhelming the queue
    sleep 0.1
done

echo ""
echo "✅ Sent $MESSAGES_COUNT messages to the queue!"
echo ""

# Show queue stats
echo "📊 Queue statistics:"
kubectl exec -n default deploy/localstack -- \
    awslocal sqs get-queue-attributes \
    --queue-url "$QUEUE_URL" \
    --attribute-names ApproximateNumberOfMessages \
    --query 'Attributes.ApproximateNumberOfMessages' \
    --output text 2>/dev/null | \
    xargs -I {} echo "   Messages in queue: {}"

echo ""
echo "💡 Tip: Watch the jobs being created with:"
echo "   kubectl get jobs -n default -w"
