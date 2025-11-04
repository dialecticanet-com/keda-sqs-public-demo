# Live Demo Presentation Guide

This guide helps you deliver an effective live demonstration of KEDA's auto-scaling capabilities.

## Pre-Demo Setup (5 minutes before presentation)

### 1. Verify Prerequisites
```bash
# Quick check - all should return version numbers
docker --version && kubectl version --client && kind version && helm version && aws --version
```

### 2. Run Setup Scripts
```bash
./scripts/01-setup-kind.sh      # ~90 seconds
./scripts/02-setup-localstack.sh # ~60 seconds
./scripts/03-setup-keda.sh       # ~45 seconds
./scripts/04-deploy-scaledobject.sh # ~30 seconds
```

**Total setup time**: ~4-5 minutes

### 3. Prepare Your Terminals

Open 3 terminal windows side-by-side:

```
┌─────────────────┬─────────────────┬─────────────────┐
│   Terminal 1    │   Terminal 2    │   Terminal 3    │
│   (Producer)    │  (Job Monitor)  │     (Logs)      │
│                 │                 │                 │
│  Messages sent  │  Jobs created   │  Fortune quotes │
│  20/second      │  Status updates │  being printed  │
└─────────────────┴─────────────────┴─────────────────┘
```

## Demo Script

### Introduction (1 minute)

**Say**: "Today I'll demonstrate Kubernetes Event-Driven Autoscaling using KEDA. We'll see how Kubernetes can automatically scale workloads based on the number of messages in an SQS queue."

**Show**: Architecture diagram from README.md

**Key Points**:
- Everything runs locally (no cloud costs)
- Fully offline after setup
- Real-world pattern (queue-based processing)

### Part 1: Show Initial State (30 seconds)

**Terminal 2**:
```bash
kubectl get jobs
# Should show: No resources found
```

**Say**: "Right now, we have zero jobs running. The system is completely idle, consuming minimal resources."

**Terminal 2**:
```bash
kubectl get scaledjob
# Shows the ScaledJob configuration
```

**Say**: "KEDA is monitoring our SQS queue, ready to create jobs when messages arrive."

### Part 2: Start Message Production (30 seconds)

**Terminal 1**:
```bash
./scripts/produce-messages.sh
```

**Say**: "I'm now sending 20 messages per second to our SQS queue. Each message contains a random fortune quote."

**Show**: Messages being sent counter incrementing

### Part 3: Watch Auto-Scaling in Action (2 minutes)

**Terminal 2**:
```bash
./scripts/watch-jobs.sh
```

**Say**: "Watch what happens - KEDA detects messages in the queue and automatically creates Kubernetes Jobs to process them."

**Point out**:
- Jobs appearing within 5-10 seconds
- Multiple jobs running concurrently
- Job names are auto-generated
- Status transitions: Pending → Running → Completed

**Terminal 3**:
```bash
kubectl logs -f -l app=sqs-consumer --max-log-requests=20
```

**Say**: "Here we can see the actual message processing. Each job receives one message, prints the fortune quote, and exits."

**Point out**:
- Fortune messages appearing
- Timestamps showing when messages were created
- Jobs completing successfully

### Part 4: Demonstrate Scaling Behavior (1 minute)

**Say**: "Let's check how many jobs are running concurrently."

**Terminal 2** (or new terminal):
```bash
kubectl get jobs -l app=sqs-consumer | grep Running | wc -l
```

**Say**: "We have [X] jobs running simultaneously. KEDA is maintaining this based on the queue depth."

**Show queue depth**:
```bash
kubectl exec deployment/localstack -- \
  awslocal sqs get-queue-attributes \
  --queue-url http://localhost:4566/000000000000/demo-queue \
  --attribute-names ApproximateNumberOfMessages
```

### Part 5: Scale Down to Zero (1 minute)

**Terminal 1**: Press Ctrl+C to stop the producer

**Say**: "Now I'll stop sending messages. Watch what happens as the queue empties."

**Terminal 2**: Continue watching jobs

**Point out**:
- Existing jobs continue processing
- No new jobs are created
- Jobs complete and disappear (TTL cleanup)
- System returns to zero after ~1-2 minutes

**Say**: "This is the power of KEDA - automatic scaling from zero to many, and back to zero. No wasted resources when idle."

### Part 6: Show Configuration (1 minute)

**Show** `k8s/scaledobject.yaml`:

```bash
cat k8s/scaledobject.yaml | grep -A 5 "triggers:"
```

**Explain**:
- `queueLength: "1"` - One job per message (aggressive for demo)
- `pollingInterval: 5` - Check every 5 seconds
- `maxReplicaCount: 50` - Maximum concurrent jobs
- Can be tuned for production workloads

## Key Talking Points

### For Technical Audiences

1. **Event-Driven Architecture**
   - Decouples message production from consumption
   - Scales based on actual demand, not predictions
   - Cost-effective (pay only for processing time)

2. **KEDA Benefits**
   - Standard Kubernetes (no vendor lock-in)
   - 50+ scalers (SQS, Kafka, Redis, etc.)
   - Scales to zero (unlike HPA)
   - Works with Jobs, Deployments, StatefulSets

3. **Production Considerations**
   - Tune `queueLength` based on processing time
   - Set appropriate resource limits
   - Configure dead letter queues
   - Add monitoring and alerting

### For Non-Technical Audiences

1. **Business Value**
   - Automatic resource optimization
   - Reduced cloud costs (no idle resources)
   - Improved reliability (handles traffic spikes)
   - Faster processing during peak times

2. **Real-World Examples**
   - Image processing pipelines
   - Email/notification sending
   - Data ETL jobs
   - Report generation

3. **Comparison to Traditional Approach**
   - **Old way**: Fixed number of workers (over/under provisioned)
   - **KEDA way**: Dynamic workers (right-sized automatically)

## Common Questions & Answers

**Q: How fast does it scale?**
A: Jobs appear within 5-10 seconds of messages arriving. In production, this can be tuned.

**Q: What's the maximum scale?**
A: We set 50 for this demo, but it can go much higher depending on cluster capacity.

**Q: What happens if a job fails?**
A: Kubernetes will retry (we set backoffLimit: 3). Failed jobs can be routed to a dead letter queue.

**Q: Can this work with real AWS?**
A: Yes! Just change the endpoint URL and credentials. Everything else stays the same.

**Q: What about costs?**
A: You only pay for job execution time. When idle, costs are near zero.

**Q: Does this work with other message queues?**
A: Yes! KEDA supports 50+ sources: Kafka, RabbitMQ, Redis, Azure Service Bus, etc.

## Troubleshooting During Demo

### If jobs don't appear:
```bash
kubectl describe scaledjob sqs-consumer-scaledobject
kubectl logs -n keda -l app=keda-operator --tail=20
```

### If producer fails:
```bash
# Restart port-forward
kubectl port-forward svc/localstack 4566:4566 &
```

### If LocalStack is slow:
```bash
# Check resources
kubectl top pods
# LocalStack needs ~512Mi memory
```

## Post-Demo Cleanup

```bash
# Full cleanup
kind delete cluster --name keda-demo

# Or keep cluster for Q&A
kubectl delete scaledjob sqs-consumer-scaledobject
kubectl delete jobs -l app=sqs-consumer
```

## Demo Variations

### Variation 1: Slower Scaling
Edit `k8s/scaledobject.yaml`:
```yaml
queueLength: "10"  # 1 job per 10 messages
```

### Variation 2: Faster Production
Edit `scripts/produce-messages.sh`:
```bash
MESSAGES_PER_SECOND=50
```

### Variation 3: Different Message Types
Edit `consumer/consumer.py` to process different payloads

## Success Metrics

A successful demo shows:
- ✅ Jobs spawn automatically when messages arrive
- ✅ Multiple jobs run concurrently
- ✅ Fortune messages print correctly
- ✅ System scales to zero when idle
- ✅ No manual intervention needed

## Time Budget

- Setup: 5 minutes (before demo)
- Introduction: 1 minute
- Demo execution: 5-6 minutes
- Q&A: 5-10 minutes
- **Total**: 15-20 minutes

## Additional Resources

For deeper dives:
- KEDA documentation: https://keda.sh/docs/
- This project's README.md for technical details
- PROJECT_SUMMARY.md for architecture overview

---

**Pro Tip**: Practice the demo once before presenting to ensure smooth execution and timing!
