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

  # Ensure Docker is installed
  if ! command -v docker >/dev/null 2>&1; then
    echo "🐳 Docker not found. Installing..."
    sudo dnf update -y
    sudo dnf install -y docker
    sudo systemctl enable docker
    sudo systemctl start docker
  fi

  # Ensure docker service is running
  sudo systemctl status docker || sudo systemctl start docker

  # Ensure docker-compose is available (standalone binary for compatibility)
  if ! command -v docker-compose >/dev/null 2>&1; then
    echo "🧩 docker-compose not found. Installing standalone binary..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
  fi

  # Stop any existing containers
  sudo docker-compose -f docker-compose.yml down || true

  # Pull the latest image
  sudo docker pull $IMAGE

  # Start the new container
  sudo docker-compose -f docker-compose.yml up -d

  echo "🎉 Deployment complete! Running containers:"
  sudo docker ps
EOF


