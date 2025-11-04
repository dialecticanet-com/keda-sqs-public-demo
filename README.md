# KEDA SQS Local Demo

A complete local demonstration of Kubernetes Event-Driven Autoscaling (KEDA) with AWS SQS, running entirely offline using kind and LocalStack.

## Overview

This demo showcases how KEDA can automatically scale Kubernetes Jobs based on the number of messages in an SQS queue. As messages arrive, KEDA spawns consumer Jobs that process and print the messages, then terminate. When the queue is empty, the system scales down to zero.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    kind Kubernetes Cluster                   │
│                                                              │
│  ┌──────────────┐      ┌─────────────────┐                 │
│  │  LocalStack  │      │  KEDA Operator  │                 │
│  │   (SQS)      │◄─────┤  (Monitoring)   │                 │
│  └──────────────┘      └─────────────────┘                 │
│         ▲                       │                            │
│         │                       │ Spawns Jobs                │
│         │                       ▼                            │
│         │              ┌─────────────────┐                  │
│         │              │ ScaledObject    │                  │
│         │              │ (queueLength=1) │                  │
│         │              └─────────────────┘                  │
│         │                       │                            │
│         │                       ▼                            │
│         │              ┌─────────────────┐                  │
│         └──────────────┤ Consumer Jobs   │                  │
│                        │ (Python)        │                  │
│                        └─────────────────┘                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
         ▲
         │ Produces Messages
         │
  ┌──────────────┐
  │   Producer   │
  │   Script     │
  └──────────────┘
```

## Prerequisites

Before starting, ensure you have the following installed:

- **Docker Desktop** (or Docker Engine) - Running and accessible
- **kubectl** - Kubernetes command-line tool
  ```bash
  brew install kubectl
  ```
- **kind** - Kubernetes in Docker
  ```bash
  brew install kind
  ```
- **Helm** - Kubernetes package manager
  ```bash
  brew install helm
  ```
- **AWS CLI** - For sending messages to LocalStack SQS
  ```bash
  brew install awscli
  ```
- **fortune** - For generating random messages (optional, script will use fallback)
  ```bash
  brew install fortune
  ```
- **jq** - JSON processor (optional, for better output formatting)
  ```bash
  brew install jq
  ```

## Quick Start

### 1. Setup the Environment

Run each setup script in order:

```bash
# Create the kind cluster
./scripts/01-setup-kind.sh

# Deploy LocalStack and create SQS queue
./scripts/02-setup-localstack.sh

# Install KEDA operator
./scripts/03-setup-keda.sh

# Build consumer image and deploy KEDA ScaledObject
./scripts/04-deploy-scaledobject.sh
```

### 2. Run the Demo

Open three terminal windows:

**Terminal 1 - Message Producer:**
```bash
./scripts/produce-messages.sh
```
This will generate 20 messages per second with fortune quotes.

**Terminal 2 - Watch Jobs:**
```bash
./scripts/watch-jobs.sh
```
Or manually:
```bash
watch -n 1 'kubectl get jobs -o wide'
```

**Terminal 3 - Watch Logs:**
```bash
# Follow logs from all consumer jobs
kubectl logs -f -l app=sqs-consumer --max-log-requests=20
```

Or to see logs from a specific job:
```bash
kubectl logs -f job/<job-name>
```

### 3. Observe the Behavior

- **Terminal 1**: Messages being sent to SQS
- **Terminal 2**: Jobs being created and completed
- **Terminal 3**: Fortune messages being printed by consumers

Stop the producer (Ctrl+C) and watch the system scale down to zero as the queue empties.

## Project Structure

```
.
├── README.md                          # This file
├── scripts/
│   ├── 01-setup-kind.sh              # Create kind cluster
│   ├── 02-setup-localstack.sh        # Deploy LocalStack + create SQS queue
│   ├── 03-setup-keda.sh              # Install KEDA
│   ├── 04-deploy-scaledobject.sh     # Deploy KEDA ScaledObject + Job template
│   ├── produce-messages.sh           # Generate SQS messages with fortune
│   └── watch-jobs.sh                 # Helper to watch job status
├── k8s/
│   ├── localstack-deployment.yaml    # LocalStack deployment + service
│   ├── consumer-job-template.yaml    # Job template for SQS consumers
│   ├── scaledobject.yaml             # KEDA ScaledObject config
│   └── service-account.yaml          # RBAC for jobs
└── consumer/
    ├── Dockerfile                    # Python consumer container
    ├── requirements.txt              # boto3, etc.
    └── consumer.py                   # SQS consumer script
```

## How It Works

### KEDA ScaledObject

The ScaledObject monitors the LocalStack SQS queue and scales the number of Jobs based on queue depth:

- **Trigger**: AWS SQS (pointing to LocalStack endpoint)
- **queueLength**: 1 (creates 1 job per message)
- **pollingInterval**: 5 seconds
- **minReplicaCount**: 0 (scales to zero when idle)
- **maxReplicaCount**: 50 (limits maximum concurrent jobs)

### Consumer Jobs

Each Job:
1. Connects to LocalStack SQS
2. Receives one message
3. Prints the fortune message payload
4. Deletes the message from the queue
5. Exits (Job completes)

### Message Producer

The producer script:
- Generates 20 messages per second
- Each message contains a fortune quote
- JSON payload: `{"message": "fortune text", "timestamp": "ISO8601"}`
- Sends to LocalStack SQS using AWS CLI

## Troubleshooting

### Kind cluster fails to create

**Issue**: Docker not running or insufficient resources

**Solution**:
```bash
# Ensure Docker is running
docker ps

# Delete existing cluster and retry
kind delete cluster --name keda-demo
./scripts/01-setup-kind.sh
```

### LocalStack pod not starting

**Issue**: Image pull or resource constraints

**Solution**:
```bash
# Check pod status
kubectl get pods -l app=localstack

# View pod logs
kubectl logs -l app=localstack

# Restart LocalStack
kubectl rollout restart deployment localstack
```

### KEDA not scaling Jobs

**Issue**: ScaledObject misconfiguration or KEDA operator not running

**Solution**:
```bash
# Check KEDA operator
kubectl get pods -n keda

# Check ScaledObject status
kubectl get scaledobject
kubectl describe scaledobject sqs-consumer-scaledobject

# Check KEDA operator logs
kubectl logs -n keda -l app=keda-operator
```

### Consumer Jobs failing

**Issue**: Cannot connect to LocalStack or SQS queue doesn't exist

**Solution**:
```bash
# Check if LocalStack service is accessible
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://localstack:4566/_localstack/health

# Verify SQS queue exists
kubectl exec -it deployment/localstack -- \
  awslocal sqs list-queues

# Check job logs
kubectl logs -l app=sqs-consumer --tail=50
```

### No messages being consumed

**Issue**: AWS credentials not configured or wrong endpoint

**Solution**:
```bash
# Verify the ScaledObject has correct endpoint
kubectl get scaledobject sqs-consumer-scaledobject -o yaml | grep endpoint

# Check if messages are in the queue
kubectl exec -it deployment/localstack -- \
  awslocal sqs get-queue-attributes \
  --queue-url http://localhost:4566/000000000000/demo-queue \
  --attribute-names ApproximateNumberOfMessages
```

### Producer script fails

**Issue**: AWS CLI not configured or LocalStack not accessible

**Solution**:
```bash
# Port-forward LocalStack to localhost
kubectl port-forward svc/localstack 4566:4566 &

# Verify connection
aws --endpoint-url=http://localhost:4566 sqs list-queues

# Run producer script again
./scripts/produce-messages.sh
```

## Cleanup

To completely remove the demo environment:

```bash
# Delete the kind cluster (removes everything)
kind delete cluster --name keda-demo

# Verify cleanup
kind get clusters
```

To keep the cluster but remove the demo components:

```bash
# Delete KEDA resources
kubectl delete scaledobject sqs-consumer-scaledobject
kubectl delete jobs -l app=sqs-consumer

# Delete LocalStack
kubectl delete deployment localstack
kubectl delete service localstack

# Uninstall KEDA
helm uninstall keda -n keda
kubectl delete namespace keda
```

## Customization

### Adjust Scaling Behavior

Edit `k8s/scaledobject.yaml`:

```yaml
# Scale more aggressively (1 job per message)
queueLength: "1"

# Scale less aggressively (1 job per 5 messages)
queueLength: "5"

# Poll more frequently
pollingInterval: 2

# Increase max concurrent jobs
maxReplicaCount: 100
```

### Change Message Rate

Edit `scripts/produce-messages.sh`:

```bash
# Produce 50 messages per second
MESSAGES_PER_SECOND=50
```

### Modify Consumer Behavior

Edit `consumer/consumer.py` to change how messages are processed.

## Learning Resources

- **KEDA Documentation**: https://keda.sh/docs/
- **KEDA SQS Scaler**: https://keda.sh/docs/scalers/aws-sqs/
- **LocalStack Documentation**: https://docs.localstack.cloud/
- **Kind Documentation**: https://kind.sigs.k8s.io/

## License

This demo is provided as-is for educational purposes.
