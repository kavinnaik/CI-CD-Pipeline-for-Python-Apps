#!/bin/bash
set -e  # exit immediately on error

EC2_HOST=$1
EC2_USER=$2
KEY_PATH=$3
IMAGE=$4

echo "🚀 Deploying image $IMAGE to $EC2_HOST"

# Copy deployment files
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no docker-compose.yml $EC2_USER@$EC2_HOST:/home/$EC2_USER/ || echo "⚠️ No docker-compose.yml found"

# Run deployment commands remotely
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << EOF
  set -e
  echo "🔐 Connected to $EC2_HOST"
  sudo systemctl start docker || true
  docker pull $IMAGE
  docker ps -q --filter "name=app" && docker stop app && docker rm app || true
  docker run -d --name app -p 80:80 $IMAGE
  echo "✅ Deployment successful!"
EOF
