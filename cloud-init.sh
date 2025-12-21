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

# Create agent directory
mkdir -p /home/santosh/ado-agent
chown -R santosh:santosh /home/santosh/ado-agent

# Download & configure agent as normal user
sudo -u santosh bash <<EOF
set -e
cd /home/santosh/ado-agent

curl -O https://download.agent.dev.azure.com/agent/4.266.2/vsts-agent-linux-x64-4.266.2.tar.gz
tar zxvf vsts-agent-linux-x64-4.266.2.tar.gz

./config.sh --unattended \
  --url "https://dev.azure.com/santosh1808" \
  --auth pat \
  --token "1u0jWQXKWwyweOEDP7AYZRgkWq5FzNNHdTdBDSQcuMEe4vhnMLjYJQQJ99BLACAAAAAAAAAAAAASAZDO2bDA" \
  --pool "MyPool" \
  --agent "ado-agent" \
  --acceptTeeEula
EOF

# Install & start agent service
cd /home/santosh/ado-agent
./svc.sh install
./svc.sh start
