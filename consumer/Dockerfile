FROM python:3.11-slim

WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy consumer script
COPY consumer.py .

# Make script executable
RUN chmod +x consumer.py

# Run the consumer
CMD ["python", "consumer.py"]
