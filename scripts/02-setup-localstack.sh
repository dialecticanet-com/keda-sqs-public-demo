#!/bin/bash

set -e

echo "========================================================"
echo "KEDA SQS Demo - Step 2: Setting up LocalStack with SQS"
echo "========================================================"
echo ""

CLUSTER_NAME="keda-demo"
QUEUE_NAME="demo-queue"
LOCALSTACK_ENDPOINT="http://localstack:4566"

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "❌ Error: Cluster '${CLUSTER_NAME}' does not exist."
    echo "   Please run ./scripts/01-setup-kind.sh first."
    exit 1
fi

# Ensure we're using the correct context
kubectl config use-context "kind-${CLUSTER_NAME}"

echo "📦 Deploying LocalStack to the cluster..."
kubectl apply -f k8s/localstack-deployment.yaml

echo ""
echo "⏳ Waiting for LocalStack to be ready (this may take 1-2 minutes)..."
kubectl wait --for=condition=available --timeout=180s deployment/localstack

echo ""
echo "⏳ Waiting for LocalStack pod to be fully ready..."
kubectl wait --for=condition=Ready --timeout=120s pod -l app=localstack

# Give LocalStack a few extra seconds to fully initialize
echo "⏳ Giving LocalStack a few seconds to initialize services..."
sleep 10

echo ""
echo "🔍 Checking LocalStack health..."
kubectl exec deployment/localstack -- curl -s http://localhost:4566/_localstack/health | head -20

echo ""
echo "📬 Creating SQS queue '${QUEUE_NAME}'..."

# Create the SQS queue using awslocal (AWS CLI wrapper for LocalStack)
QUEUE_URL=$(kubectl exec deployment/localstack -- \
    awslocal sqs create-queue \
    --queue-name "${QUEUE_NAME}" \
    --output text \
    --query 'QueueUrl' 2>/dev/null || echo "")

if [ -z "$QUEUE_URL" ]; then
    echo "⚠️  Queue might already exist, trying to get existing queue URL..."
    QUEUE_URL=$(kubectl exec deployment/localstack -- \
        awslocal sqs get-queue-url \
        --queue-name "${QUEUE_NAME}" \
        --output text \
        --query 'QueueUrl' 2>/dev/null || echo "")
fi

if [ -n "$QUEUE_URL" ]; then
    echo "✅ SQS Queue created/found: ${QUEUE_URL}"
else
    echo "❌ Failed to create/find SQS queue"
    exit 1
fi

echo ""
echo "🔍 Verifying queue attributes..."
kubectl exec deployment/localstack -- \
    awslocal sqs get-queue-attributes \
    --queue-url "${QUEUE_URL}" \
    --attribute-names All

echo ""
echo "📋 Listing all SQS queues:"
kubectl exec deployment/localstack -- awslocal sqs list-queues

echo ""
echo "✅ LocalStack is ready!"
echo ""
echo "📊 LocalStack service info:"
kubectl get service localstack

echo ""
echo "💡 To access LocalStack from your host machine, run in a separate terminal:"
echo "   kubectl port-forward svc/localstack 4566:4566"
echo ""
echo "✅ Step 2 complete! Next step:"
echo "   ./scripts/03-setup-keda.sh"
echo ""
