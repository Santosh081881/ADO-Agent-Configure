#!/bin/bash
set -euxo pipefail

LOG=/var/log/ado-agent-bootstrap.log
exec > >(tee -a $LOG) 2>&1

apt update -y
apt install -y curl unzip zip git ca-certificates gnupg lsb-release

# Docker
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/hashicorp.list
apt update && apt install -y terraform