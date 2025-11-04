# Quick Start Guide

This is a condensed guide to get the demo running quickly. For detailed documentation, see [README.md](README.md).

## Prerequisites

Ensure you have installed:
- Docker Desktop (running)
- kubectl
- kind
- helm
- awscli
- fortune (optional)

**macOS:**
```bash
brew install kubectl kind helm awscli fortune
```

**Linux (Debian/Ubuntu):**
```bash
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# awscli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# fortune (optional)
sudo apt-get install fortune-mod
```

**Linux (RHEL/Fedora):**
```bash
# kubectl, kind, helm, awscli - same as Debian/Ubuntu above

# fortune (optional)
sudo dnf install fortune-mod
```

## Setup (5 minutes)

Run these commands in order:

```bash
# 1. Create kind cluster
./scripts/01-setup-kind.sh

# 2. Deploy LocalStack and create SQS queue
./scripts/02-setup-localstack.sh

# 3. Install KEDA
./scripts/03-setup-keda.sh

# 4. Build consumer and deploy ScaledJob
./scripts/04-deploy-scaledobject.sh
```

## Run the Demo

Open 3 terminals:

### Terminal 1: Producer
```bash
./scripts/produce-messages.sh
```

### Terminal 2: Watch Jobs
```bash
./scripts/watch-jobs.sh
```

### Terminal 3: Watch Logs
```bash
kubectl logs -f -l app=sqs-consumer --max-log-requests=20
```

## What to Observe

- **Terminal 1**: Messages being sent (20/sec)
- **Terminal 2**: Jobs being created and completed
- **Terminal 3**: Fortune messages being printed

Stop the producer (Ctrl+C) and watch the system scale down to zero!

## Cleanup

```bash
kind delete cluster --name keda-demo
```

## Troubleshooting

If something goes wrong:

```bash
# Check all pods are running
kubectl get pods --all-namespaces

# Check KEDA is working
kubectl get scaledjob

# Check LocalStack logs
kubectl logs -l app=localstack

# Restart from scratch
kind delete cluster --name keda-demo
./scripts/01-setup-kind.sh
```

For more help, see [README.md](README.md).
