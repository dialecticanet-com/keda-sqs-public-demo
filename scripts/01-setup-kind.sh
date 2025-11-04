#!/bin/bash

set -e

echo "================================================"
echo "KEDA SQS Demo - Step 1: Setting up kind cluster"
echo "================================================"
echo ""

CLUSTER_NAME="keda-demo"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "❌ Error: kind is not installed. Please install it first:"
    echo "   brew install kind"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed. Please install it first:"
    echo "   brew install kubectl"
    exit 1
fi

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "⚠️  Cluster '${CLUSTER_NAME}' already exists."
    read -p "Do you want to delete it and create a new one? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting existing cluster..."
        kind delete cluster --name "${CLUSTER_NAME}"
    else
        echo "✅ Using existing cluster '${CLUSTER_NAME}'"
        kubectl cluster-info --context "kind-${CLUSTER_NAME}"
        exit 0
    fi
fi

echo "🚀 Creating kind cluster '${CLUSTER_NAME}'..."
echo ""

# Create kind cluster with custom configuration
cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 4566
    hostPort: 4566
    protocol: TCP
EOF

echo ""
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo ""
echo "✅ Kind cluster '${CLUSTER_NAME}' is ready!"
echo ""
echo "📊 Cluster info:"
kubectl cluster-info --context "kind-${CLUSTER_NAME}"

echo ""
echo "🎯 Current context:"
kubectl config current-context

echo ""
echo "✅ Step 1 complete! Next step:"
echo "   ./scripts/02-setup-localstack.sh"
echo ""
