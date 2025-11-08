#!/bin/bash
set -eux

# Update and install Docker
dnf update -y
dnf install -y docker

systemctl enable docker
systemctl start docker

# Install git & curl (handy)
dnf install -y git curl

# Create a directory for the systemd service we’ll push from CI
mkdir -p /opt/app
touch /opt/app/.placeholder

# Open firewall for HTTP (Amazon Linux uses nftables; EC2 SG already allows 80)
# We'll run container mapping 80:5000
