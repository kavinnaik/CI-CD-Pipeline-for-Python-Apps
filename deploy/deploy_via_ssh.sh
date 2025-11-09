#!/bin/bash
set -e

EC2_HOST=$1
EC2_USER=$2
KEY_PATH=$3
IMAGE=$4

echo "🚀 Deploying image $IMAGE to $EC2_HOST"

# Fix SSH permissions explicitly
chmod 600 "$KEY_PATH"

# Copy docker-compose file from correct path
if [ -f "./deploy/docker-compose.yml" ]; then
  echo "📦 Copying docker-compose.yml to EC2"
  scp -o StrictHostKeyChecking=no -i "$KEY_PATH" ./deploy/docker-compose.yml "$EC2_USER@$EC2_HOST:/home/$EC2_USER/docker-compose.yml"
else
  echo "⚠️ docker-compose.yml not found at ./deploy/docker-compose.yml"
  exit 1
fi

# Deploy remotely
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" "$EC2_USER@$EC2_HOST" <<EOF
  echo "✅ Connected to EC2 host: $EC2_HOST"

  # Stop any existing containers
  docker compose -f docker-compose.yml down || true

  # Pull the latest image
  docker pull $IMAGE

  # Start the new container
  docker compose -f docker-compose.yml up -d

  echo "🎉 Deployment complete! Running containers:"
  docker ps
EOF

