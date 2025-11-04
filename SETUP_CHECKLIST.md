# Setup Checklist

Use this checklist to verify your environment is ready for the KEDA SQS demo.

## Pre-Setup Verification

### Required Tools

- [ ] **Docker Desktop** is installed and running
  ```bash
  docker --version
  docker ps
  ```

- [ ] **kubectl** is installed
  ```bash
  kubectl version --client
  ```

- [ ] **kind** is installed
  ```bash
  kind version
  ```

- [ ] **helm** is installed
  ```bash
  helm version
  ```

- [ ] **AWS CLI** is installed
  ```bash
  aws --version
  ```

### Optional Tools

- [ ] **fortune** is installed (recommended for better demo experience)
  ```bash
  fortune --version || echo "Not installed - will use fallback messages"
  ```

- [ ] **watch** is installed (for better job monitoring)
  ```bash
  watch --version || echo "Not installed - will use fallback monitoring"
  ```

- [ ] **jq** is installed (for JSON formatting)
  ```bash
  jq --version || echo "Not installed - demo will still work"
  ```

## Setup Steps

### Step 1: Create kind Cluster

- [ ] Run `./scripts/01-setup-kind.sh`
- [ ] Verify cluster is running: `kind get clusters`
- [ ] Verify kubectl context: `kubectl cluster-info`

**Expected output**: Cluster named "keda-demo" should be listed

### Step 2: Deploy LocalStack

- [ ] Run `./scripts/02-setup-localstack.sh`
- [ ] Verify LocalStack pod is running: `kubectl get pods -l app=localstack`
- [ ] Verify SQS queue exists: `kubectl exec deployment/localstack -- awslocal sqs list-queues`

**Expected output**: Queue URL containing "demo-queue"

### Step 3: Install KEDA

- [ ] Run `./scripts/03-setup-keda.sh`
- [ ] Verify KEDA namespace: `kubectl get namespace keda`
- [ ] Verify KEDA pods: `kubectl get pods -n keda`
- [ ] Verify KEDA CRDs: `kubectl get crd | grep keda`

**Expected output**: 2 KEDA pods running, multiple CRDs listed

### Step 4: Deploy ScaledJob

- [ ] Run `./scripts/04-deploy-scaledobject.sh`
- [ ] Verify ScaledJob: `kubectl get scaledjob`
- [ ] Verify ServiceAccount: `kubectl get serviceaccount sqs-consumer-sa`
- [ ] Verify no jobs yet: `kubectl get jobs`

**Expected output**: ScaledJob exists, no jobs running (queue is empty)

## Demo Verification

### Terminal 1: Producer

- [ ] Run `./scripts/produce-messages.sh`
- [ ] Verify port-forward is working
- [ ] Verify messages are being sent (counter incrementing)

**Expected output**: "Sent X messages" counter increasing

### Terminal 2: Job Monitor

- [ ] Run `./scripts/watch-jobs.sh`
- [ ] Verify jobs are being created
- [ ] Verify jobs are completing successfully

**Expected output**: Jobs appearing and completing

### Terminal 3: Logs

- [ ] Run `kubectl logs -f -l app=sqs-consumer --max-log-requests=20`
- [ ] Verify fortune messages are appearing
- [ ] Verify messages are being deleted from queue

**Expected output**: Fortune quotes with timestamps

## Post-Demo Verification

### Scaling Down

- [ ] Stop producer (Ctrl+C in Terminal 1)
- [ ] Wait 1-2 minutes
- [ ] Verify jobs stop being created
- [ ] Verify system scales to 0: `kubectl get jobs`

**Expected output**: No new jobs after queue is empty

### Cleanup

- [ ] Run `kind delete cluster --name keda-demo`
- [ ] Verify cluster is deleted: `kind get clusters`

**Expected output**: No clusters listed

## Troubleshooting

If any step fails, check:

1. **Docker Issues**
   ```bash
   docker ps
   docker system df  # Check disk space
   ```

2. **Cluster Issues**
   ```bash
   kubectl get pods --all-namespaces
   kubectl get events --sort-by='.lastTimestamp'
   ```

3. **LocalStack Issues**
   ```bash
   kubectl logs -l app=localstack --tail=50
   kubectl describe pod -l app=localstack
   ```

4. **KEDA Issues**
   ```bash
   kubectl logs -n keda -l app=keda-operator --tail=50
   kubectl describe scaledjob sqs-consumer-scaledobject
   ```

5. **Consumer Issues**
   ```bash
   kubectl logs -l app=sqs-consumer --tail=50
   kubectl describe jobs -l app=sqs-consumer
   ```

## Success Criteria

✅ All checkboxes above are checked
✅ Jobs spawn within 5-10 seconds of messages
✅ Fortune messages appear in logs
✅ System scales down to 0 when queue is empty
✅ Demo runs completely offline

## Next Steps

Once everything is working:

1. Experiment with different message rates
2. Adjust scaling parameters in `k8s/scaledobject.yaml`
3. Modify consumer logic in `consumer/consumer.py`
4. Try adding your own message processing logic

For more information, see:
- [README.md](README.md) - Full documentation
- [QUICKSTART.md](QUICKSTART.md) - Quick reference
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Technical details
