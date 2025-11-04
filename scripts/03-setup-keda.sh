#!/bin/bash

set -e

echo "=============================================="
echo "KEDA SQS Demo - Step 3: Installing KEDA"
echo "=============================================="
echo ""

CLUSTER_NAME="keda-demo"
KEDA_NAMESPACE="keda"
KEDA_VERSION="2.12.1"

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "❌ Error: Cluster '${CLUSTER_NAME}' does not exist."
    echo "   Please run ./scripts/01-setup-kind.sh first."
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Error: helm is not installed. Please install it first:"
    echo "   brew install helm"
    exit 1
fi

# Ensure we're using the correct context
kubectl config use-context "kind-${CLUSTER_NAME}"

# Check if KEDA is already installed
if helm list -n "${KEDA_NAMESPACE}" 2>/dev/null | grep -q "keda"; then
    echo "⚠️  KEDA is already installed."
    read -p "Do you want to upgrade it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "⬆️  Upgrading KEDA..."
        helm upgrade keda kedacore/keda \
            --namespace "${KEDA_NAMESPACE}" \
            --version "${KEDA_VERSION}" \
            --wait
        echo "✅ KEDA upgraded successfully!"
    else
        echo "✅ Using existing KEDA installation"
    fi
else
    echo "📦 Adding KEDA Helm repository..."
    helm repo add kedacore https://kedacore.github.io/charts
    helm repo update

    echo ""
    echo "🚀 Installing KEDA version ${KEDA_VERSION}..."
    helm install keda kedacore/keda \
        --namespace "${KEDA_NAMESPACE}" \
        --create-namespace \
        --version "${KEDA_VERSION}" \
        --wait

    echo ""
    echo "✅ KEDA installed successfully!"
fi

echo ""
echo "⏳ Waiting for KEDA operator to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/keda-operator -n "${KEDA_NAMESPACE}"
kubectl wait --for=condition=available --timeout=120s deployment/keda-operator-metrics-apiserver -n "${KEDA_NAMESPACE}"

echo ""
echo "🔍 Verifying KEDA installation..."
echo ""
echo "KEDA Pods:"
kubectl get pods -n "${KEDA_NAMESPACE}"

echo ""
echo "KEDA CRDs:"
kubectl get crd | grep keda

echo ""
echo "✅ KEDA is ready!"
echo ""
echo "📊 KEDA version:"
kubectl get deployment keda-operator -n "${KEDA_NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "✅ Step 3 complete! Next step:"
echo "   ./scripts/04-deploy-scaledobject.sh"
echo ""
