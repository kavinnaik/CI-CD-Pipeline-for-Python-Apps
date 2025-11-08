#!/bin/bash
EC2_HOST=$1
EC2_USER=$2
KEY_PATH=$3
IMAGE=$4

echo "Deploying image $IMAGE to $EC2_HOST..."

scp -i "$KEY_PATH" -o StrictHostKeyChecking=no docker-compose.yml $EC2_USER@$EC2_HOST:/home/$EC2_USER/

ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << EOF
  echo "Connected to $EC2_HOST"
  docker pull $IMAGE
  docker stop app || true
  docker rm app || true
  docker run -d --name app -p 80:80 $IMAGE
EOF
