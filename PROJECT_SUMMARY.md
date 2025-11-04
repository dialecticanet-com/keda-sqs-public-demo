# KEDA SQS Local Demo - Project Summary

## Overview

This project provides a complete, offline-capable demonstration of Kubernetes Event-Driven Autoscaling (KEDA) using LocalStack SQS. It showcases how KEDA can automatically scale Kubernetes Jobs based on queue depth, making it perfect for demonstrating event-driven architectures to both technical and non-technical audiences.

## Project Structure

```
.
├── README.md                          # Comprehensive documentation
├── QUICKSTART.md                      # Quick start guide
├── PROJECT_SUMMARY.md                 # This file
├── .gitignore                         # Git ignore rules
├── consumer/                          # Python SQS consumer application
│   ├── consumer.py                    # Main consumer logic
│   ├── Dockerfile                     # Container image definition
│   └── requirements.txt               # Python dependencies
├── k8s/                               # Kubernetes manifests
│   ├── localstack-deployment.yaml     # LocalStack deployment + service
│   ├── service-account.yaml           # RBAC configuration
│   ├── consumer-job-template.yaml     # Job template (reference)
│   └── scaledobject.yaml              # KEDA ScaledJob configuration
└── scripts/                           # Setup and demo scripts
    ├── 01-setup-kind.sh               # Create kind cluster
    ├── 02-setup-localstack.sh         # Deploy LocalStack + SQS
    ├── 03-setup-keda.sh               # Install KEDA operator
    ├── 04-deploy-scaledobject.sh      # Deploy consumer + ScaledJob
    ├── produce-messages.sh            # Generate SQS messages
    └── watch-jobs.sh                  # Monitor job creation
```

## Key Features

### 1. Fully Offline Capable
- No internet required after initial setup
- All components run locally in kind
- LocalStack provides AWS SQS emulation

### 2. Modular Setup
- Each component has its own setup script
- Scripts can be run independently for testing
- Clear separation of concerns

### 3. Educational Focus
- Comprehensive documentation for non-technical users
- Clear error messages and troubleshooting guides
- Visual feedback in all scripts
- ASCII art architecture diagram

### 4. Production-Ready Patterns
- Proper RBAC configuration
- Resource limits and requests
- Health checks and readiness probes
- Graceful scaling (0 to N and back to 0)

## Technical Architecture

### Components

1. **kind Cluster**: Single-node Kubernetes cluster running in Docker
2. **LocalStack**: AWS service emulator providing SQS functionality
3. **KEDA Operator**: Monitors SQS queue and scales Jobs
4. **ScaledJob**: KEDA resource that manages Job creation
5. **Consumer Jobs**: Python containers that process messages
6. **Producer Script**: Generates test messages with fortune quotes

### Scaling Behavior

- **Trigger**: AWS SQS queue depth
- **Threshold**: 1 job per message (aggressive scaling for demo visibility)
- **Polling**: Every 5 seconds
- **Min Replicas**: 0 (scales to zero when idle)
- **Max Replicas**: 50 (prevents resource exhaustion)
- **Job TTL**: 300 seconds after completion (automatic cleanup)

### Message Flow

```
Producer Script
    │
    ├─> Port-forward to LocalStack
    │
    ├─> Send JSON message to SQS
    │   {"message": "fortune text", "timestamp": "ISO8601"}
    │
    ▼
LocalStack SQS Queue
    │
    ├─> KEDA polls queue depth
    │
    ▼
KEDA Operator
    │
    ├─> Calculates desired job count
    │
    ├─> Creates Jobs via ScaledJob
    │
    ▼
Consumer Jobs
    │
    ├─> Receive message from SQS
    │
    ├─> Print fortune message
    │
    ├─> Delete message from queue
    │
    └─> Exit (Job completes)
```

## Demo Workflow

### Setup Phase (5 minutes)
1. Create kind cluster with port mapping
2. Deploy LocalStack and create SQS queue
3. Install KEDA operator via Helm
4. Build consumer image and deploy ScaledJob

### Demo Phase (Interactive)
1. **Terminal 1**: Run producer (20 messages/second)
2. **Terminal 2**: Watch Jobs being created/completed
3. **Terminal 3**: Follow job logs to see fortune messages

### Observation Points
- Jobs spawn within 5-10 seconds of messages arriving
- Multiple jobs run concurrently (up to 50)
- Each job processes exactly one message
- System scales down to 0 when queue is empty
- Fortune messages are clearly visible in logs

## Configuration Options

### Adjust Scaling Behavior
Edit `k8s/scaledobject.yaml`:
- `queueLength`: Messages per job (default: 1)
- `pollingInterval`: Seconds between checks (default: 5)
- `maxReplicaCount`: Maximum concurrent jobs (default: 50)

### Adjust Message Rate
Edit `scripts/produce-messages.sh`:
- `MESSAGES_PER_SECOND`: Production rate (default: 20)

### Adjust Consumer Behavior
Edit `consumer/consumer.py`:
- Modify message processing logic
- Add custom business logic
- Change output formatting

## Use Cases

### 1. Educational Demos
- Teaching event-driven architectures
- Demonstrating Kubernetes autoscaling
- Explaining queue-based processing

### 2. Proof of Concepts
- Testing KEDA integration
- Validating scaling strategies
- Prototyping SQS consumers

### 3. Development Testing
- Local development environment
- Integration testing
- Performance testing

## Customization for Production

To adapt this demo for production use:

1. **Replace LocalStack with Real AWS SQS**
   - Update endpoint URLs in ScaledObject
   - Configure proper AWS credentials
   - Use IAM roles for authentication

2. **Enhance Consumer Logic**
   - Add error handling and retries
   - Implement dead letter queue
   - Add metrics and monitoring

3. **Adjust Scaling Parameters**
   - Tune queueLength based on processing time
   - Adjust maxReplicaCount based on capacity
   - Configure cooldown periods

4. **Add Observability**
   - Integrate Prometheus metrics
   - Add distributed tracing
   - Configure log aggregation

5. **Implement Security**
   - Use network policies
   - Add pod security policies
   - Configure secrets management

## Troubleshooting Quick Reference

| Issue | Quick Fix |
|-------|-----------|
| Cluster won't start | Check Docker is running |
| LocalStack not ready | Wait 2 minutes, check pod logs |
| KEDA not scaling | Verify ScaledJob status with `kubectl describe` |
| Jobs failing | Check consumer logs, verify SQS connection |
| Producer can't connect | Ensure port-forward is running |
| No fortune messages | Install fortune or use fallback messages |

## Performance Characteristics

- **Cluster startup**: ~60-90 seconds
- **LocalStack ready**: ~30-60 seconds
- **KEDA installation**: ~30-45 seconds
- **Image build + load**: ~20-30 seconds
- **Job spawn latency**: ~5-10 seconds
- **Message processing**: ~1-2 seconds per message

## Resource Requirements

- **Docker Memory**: 4GB minimum, 8GB recommended
- **Docker CPUs**: 2 minimum, 4 recommended
- **Disk Space**: ~2GB for images and data
- **Network**: None required after initial setup

## Future Enhancements

Potential additions to this demo:

1. **Multiple Queue Types**: Add SNS, Kinesis, or other triggers
2. **Metrics Dashboard**: Add Grafana for visualization
3. **Load Testing**: Add automated load testing scripts
4. **Multi-Consumer**: Demonstrate different consumer types
5. **Failure Scenarios**: Add chaos engineering examples
6. **CI/CD Integration**: Add GitHub Actions workflow

## Credits

This demo uses:
- [KEDA](https://keda.sh/) - Kubernetes Event-Driven Autoscaling
- [LocalStack](https://localstack.cloud/) - AWS service emulation
- [kind](https://kind.sigs.k8s.io/) - Kubernetes in Docker
- [fortune](https://en.wikipedia.org/wiki/Fortune_(Unix)) - Random quote generator

## License

This demo is provided as-is for educational purposes.
