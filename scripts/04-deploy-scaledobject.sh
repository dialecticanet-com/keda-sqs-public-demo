#!/bin/bash

set -e

echo "=========================================================="
echo "KEDA SQS Demo - Step 4: Deploying Consumer and ScaledJob"
echo "=========================================================="
echo ""

CLUSTER_NAME="keda-demo"
IMAGE_NAME="sqs-consumer"
IMAGE_TAG="latest"

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "❌ Error: Cluster '${CLUSTER_NAME}' does not exist."
    echo "   Please run ./scripts/01-setup-kind.sh first."
    exit 1
fi

# Ensure we're using the correct context
kubectl config use-context "kind-${CLUSTER_NAME}"

# Check if KEDA is installed
if ! kubectl get namespace keda &> /dev/null; then
    echo "❌ Error: KEDA namespace not found."
    echo "   Please run ./scripts/03-setup-keda.sh first."
    exit 1
fi

# Check if LocalStack is running
if ! kubectl get deployment localstack &> /dev/null; then
    echo "❌ Error: LocalStack deployment not found."
    echo "   Please run ./scripts/02-setup-localstack.sh first."
    exit 1
fi

echo "🏗️  Building consumer Docker image..."
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" ./consumer/

echo ""
echo "📦 Loading image into kind cluster..."
kind load docker-image "${IMAGE_NAME}:${IMAGE_TAG}" --name "${CLUSTER_NAME}"

echo ""
echo "🔐 Creating ServiceAccount and RBAC..."
kubectl apply -f k8s/service-account.yaml

echo ""
echo "🚀 Deploying KEDA ScaledJob..."
kubectl apply -f k8s/scaledobject.yaml

echo ""
echo "⏳ Waiting a few seconds for KEDA to process the ScaledJob..."
sleep 5

echo ""
echo "🔍 Verifying ScaledJob deployment..."
kubectl get scaledjob

echo ""
echo "📊 ScaledJob details:"
kubectl describe scaledjob sqs-consumer-scaledobject

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Current state:"
echo "   - Consumer image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "   - ScaledJob: sqs-consumer-scaledobject"
echo "   - Polling interval: 5 seconds"
echo "   - Queue length threshold: 1 message per job"
echo "   - Max concurrent jobs: 50"
echo ""
echo "🎯 The system is now ready to scale based on SQS queue depth!"
echo ""
echo "✅ Step 4 complete! Next steps:"
echo ""
echo "   Terminal 1 - Start producing messages:"
echo "   ./scripts/produce-messages.sh"
echo ""
echo "   Terminal 2 - Watch jobs being created:"
echo "   ./scripts/watch-jobs.sh"
echo ""
echo "   Terminal 3 - Watch job logs:"
echo "   kubectl logs -f -l app=sqs-consumer --max-log-requests=20"
echo ""
