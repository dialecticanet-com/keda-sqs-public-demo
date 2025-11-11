# KEDA SQS Live Demo Guide

Quick reference for delivering a live KEDA auto-scaling demonstration.

---

## Pre-Demo Setup (5 minutes)

Run these 4 scripts in order:

```bash
./scripts/01-setup-kind.sh           # Create cluster (~90s)
./scripts/02-setup-localstack.sh     # Deploy LocalStack (~60s)
./scripts/03-setup-keda.sh           # Install KEDA (~45s)
./scripts/04-deploy-scaledobject.sh  # Deploy consumer (~30s)
```

---

## Live Demo (5 minutes)

### 1. Show Initial State (30 seconds)

```bash
# Terminal 1
kubectl get scaledjob
kubectl get jobs
```

**Say**: "System is idle at zero. KEDA is monitoring the SQS queue, ready to scale."

### 2. Send Messages (Quick Method)

```bash
# Terminal 1
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1

# Send 30 messages
for i in {1..30}; do
  aws --endpoint-url=http://localhost:4566 sqs send-message \
    --queue-url http://localhost:4566/000000000000/demo-queue \
    --message-body "{\"message\":\"Demo message $i\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > /dev/null
done
```

**Say**: "Sending 30 messages to the queue..."

### 3. Watch Scaling (2 minutes)

```bash
# Terminal 2 - Watch jobs
kubectl get jobs -w -l app=sqs-consumer

# Terminal 3 - Watch logs
kubectl logs -f -l app=sqs-consumer --max-log-requests=20
```

**Point out**:
- Jobs appear within 5-10 seconds
- Multiple jobs run concurrently
- Each job processes one message and exits
- System scales back to zero when queue empties

### 4. Show Configuration (1 minute)

```bash
kubectl get scaledjob sqs-consumer-scaledobject -o yaml | grep -A 10 "triggers:"
```

**Key settings**:
- `queueLength: "1"` → 1 job per message
- `pollingInterval: 5` → Check every 5 seconds
- `maxReplicaCount: 50` → Max concurrent jobs

---

## Alternative: Use Producer Script

If you want continuous message flow:

```bash
# Terminal 1
./scripts/produce-messages-in-cluster.sh    # 20 messages/second

# Terminal 2
./scripts/watch-jobs.sh          # Monitor SQS backlog

# Terminal 3
kubectl logs --max-log-requests 100 -f -l app=sqs-consumer
```

Press Ctrl+C in Terminal 1 to stop, then watch scale-down to zero.

---

## Key Talking Points

**KEDA Benefits**:
- Scales to zero (unlike HPA)
- Event-driven (50+ scalers: SQS, Kafka, Redis, etc.)
- Standard Kubernetes (no vendor lock-in)
- Cost-effective (pay only for processing time)

**Real-World Use Cases**:
- Image/video processing pipelines
- Email/notification sending
- Data ETL jobs
- Report generation

---

## Quick Troubleshooting

**Jobs not appearing?**
```bash
kubectl logs -n keda -l app=keda-operator --tail=20
```

**Producer fails?**
```bash
# Ensure port-forward is running
kubectl port-forward svc/localstack 4566:4566 &
```

---

## Cleanup

```bash
kind delete cluster --name keda-demo
```

---

## Common Q&A

**Q: How fast does it scale?**
A: 5-10 seconds from message arrival to job creation.

**Q: Maximum scale?**
A: Set to 50 for demo, can go much higher based on cluster capacity.

**Q: Works with real AWS?**
A: Yes! Just change endpoint URL and credentials.

**Q: Other message queues?**
A: Yes! KEDA supports 50+ sources (Kafka, RabbitMQ, Redis, Azure Service Bus, etc.)

**Q: What about costs?**
A: Pay only for job execution time. Near-zero cost when idle.

---

**Total Demo Time**: 5-7 minutes + Q&A
