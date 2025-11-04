#!/usr/bin/env python3
"""
SQS Consumer for KEDA Demo

This script:
1. Connects to LocalStack SQS
2. Receives one message from the queue
3. Prints the message payload
4. Deletes the message
5. Exits (allowing the Kubernetes Job to complete)
"""

import os
import sys
import json
import boto3
from datetime import datetime

# Configuration from environment variables
SQS_QUEUE_URL = os.environ.get('SQS_QUEUE_URL', 'http://localstack:4566/000000000000/demo-queue')
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')
AWS_ENDPOINT_URL = os.environ.get('AWS_ENDPOINT_URL', 'http://localstack:4566')

# Dummy credentials for LocalStack (required but can be any value)
AWS_ACCESS_KEY_ID = os.environ.get('AWS_ACCESS_KEY_ID', 'test')
AWS_SECRET_ACCESS_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY', 'test')


def main():
    """Main consumer logic"""
    print(f"[{datetime.now().isoformat()}] 🚀 SQS Consumer starting...")
    print(f"[{datetime.now().isoformat()}] 📬 Queue URL: {SQS_QUEUE_URL}")
    print(f"[{datetime.now().isoformat()}] 🌐 Endpoint: {AWS_ENDPOINT_URL}")
    print("")

    try:
        # Create SQS client
        sqs = boto3.client(
            'sqs',
            endpoint_url=AWS_ENDPOINT_URL,
            region_name=AWS_REGION,
            aws_access_key_id=AWS_ACCESS_KEY_ID,
            aws_secret_access_key=AWS_SECRET_ACCESS_KEY
        )

        print(f"[{datetime.now().isoformat()}] 🔍 Polling for messages...")

        # Receive message from SQS
        response = sqs.receive_message(
            QueueUrl=SQS_QUEUE_URL,
            MaxNumberOfMessages=1,
            WaitTimeSeconds=10,  # Long polling
            VisibilityTimeout=30
        )

        # Check if we got any messages
        if 'Messages' not in response or len(response['Messages']) == 0:
            print(f"[{datetime.now().isoformat()}] ℹ️  No messages available in queue")
            return 0

        # Process the message
        message = response['Messages'][0]
        receipt_handle = message['ReceiptHandle']
        body = message['Body']

        print(f"[{datetime.now().isoformat()}] 📨 Message received!")
        print("")
        print("=" * 80)

        try:
            # Try to parse as JSON
            message_data = json.loads(body)

            # Extract the fortune message
            if 'message' in message_data:
                fortune_text = message_data['message']
                timestamp = message_data.get('timestamp', 'N/A')

                print(f"🎲 Fortune Message:")
                print("")
                print(fortune_text)
                print("")
                print(f"⏰ Message Timestamp: {timestamp}")
            else:
                # If no 'message' field, just print the whole body
                print(f"📄 Message Body:")
                print(json.dumps(message_data, indent=2))
        except json.JSONDecodeError:
            # If not JSON, print as plain text
            print(f"📄 Message Body (plain text):")
            print(body)

        print("=" * 80)
        print("")

        # Delete the message from the queue
        print(f"[{datetime.now().isoformat()}] 🗑️  Deleting message from queue...")
        sqs.delete_message(
            QueueUrl=SQS_QUEUE_URL,
            ReceiptHandle=receipt_handle
        )

        print(f"[{datetime.now().isoformat()}] ✅ Message processed and deleted successfully!")
        return 0

    except Exception as e:
        print(f"[{datetime.now().isoformat()}] ❌ Error: {str(e)}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    exit_code = main()
    print(f"[{datetime.now().isoformat()}] 👋 Consumer exiting with code {exit_code}")
    sys.exit(exit_code)
