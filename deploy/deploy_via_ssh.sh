#!/bin/bash

HOST=$1
USER=$2
KEY=$3
IMAGE=$4

echo "🚀 Deploying image $IMAGE to $HOST"

# Upload docker-compose.yml
scp -i "$KEY" -o StrictHostKeyChecking=no deploy/docker-compose.yml $USER@$HOST:/home/$USER/docker-compose.yml || echo "⚠️ No docker-compose.yml found"

# SSH and deploy container
ssh -i "$KEY" -o StrictHostKeyChecking=no $USER@$HOST << EOF
  echo "📦 Pulling latest image..."
  docker pull $IMAGE
  echo "🧹 Stopping old containers..."
  docker rm -f ci-cd-python-app || true
  echo "🚀 Starting new container..."
  docker-compose -f docker-compose.yml up -d
EOF

