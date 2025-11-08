#!/usr/bin/env bash
set -euo pipefail

EC2_HOST="$1"
EC2_USER="$2"
SSH_KEY_FILE="$3"
IMAGE="$4"

# copy service file and substitute image
TMP_SERVICE="$(mktemp)"
sed "s|\${DOCKER_IMAGE}|$IMAGE|g" deploy/app.service > "$TMP_SERVICE"

# copy service & reload
scp -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no "$TMP_SERVICE" "$EC2_USER@$EC2_HOST:/tmp/app.service"
ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_HOST" "sudo mv /tmp/app.service /etc/systemd/system/app.service && sudo systemctl daemon-reload"

# login not required for Docker Hub public pulls
ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_HOST" "sudo systemctl stop app.service || true"
ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_HOST" "sudo docker pull $IMAGE"
ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_HOST" "sudo systemctl enable app.service && sudo systemctl start app.service"
