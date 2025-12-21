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

ORG_URL="https://dev.azure.com/santosh1808"
AGENT_POOL="MyPool"
AGENT_NAME="ado-agent"
ADO_PAT="Cr3lkYM8YqfKp3jnBd4dVMBXIRo0IAQ6UHW6WtZyLwn56nCjf7e3JQQJ99BLACAAAAAAAAAAAAASAZDO3fri"

AGENT_DIR="/home/santosh/ado-agent"
SERVICE_NAME="vsts.agent.santosh1808.MyPool.ado-agent"

echo "=== Azure DevOps Agent Bootstrap Started ==="

# -----------------------------
# Ensure directory + ownership
# -----------------------------
mkdir -p "$AGENT_DIR"
chown -R santosh:santosh "$AGENT_DIR"

# -----------------------------
# If agent already configured → remove cleanly
# -----------------------------
if [ -f "$AGENT_DIR/.agent" ]; then
  echo "Agent already configured. Removing existing agent..."

  if systemctl list-units --full -all | grep -q "$SERVICE_NAME"; then
    echo "Stopping agent service..."
    sudo ./svc.sh stop || true

    echo "Uninstalling agent service..."
    sudo ./svc.sh uninstall || true
  fi

  echo "Removing agent registration from Azure DevOps..."
  sudo -u santosh bash <<EOF
  cd "$AGENT_DIR"
  ./config.sh remove --unattended --auth pat --token "$ADO_PAT" || true
EOF

  echo "Cleanup complete."
fi

# -----------------------------
# Download agent if not present
# -----------------------------
sudo -u santosh bash <<EOF
set -e
cd "$AGENT_DIR"

if [ ! -f "config.sh" ]; then
  echo "Downloading Azure DevOps agent..."
  curl -O https://download.agent.dev.azure.com/agent/4.266.2/vsts-agent-linux-x64-4.266.2.tar.gz
  tar zxvf vsts-agent-linux-x64-4.266.2.tar.gz
fi
EOF

# -----------------------------
# Configure agent (fresh)
# -----------------------------
sudo -u santosh bash <<EOF
set -e
cd "$AGENT_DIR"

echo "Configuring new agent..."
./config.sh --unattended \
  --url "$ORG_URL" \
  --auth pat \
  --token "$ADO_PAT" \
  --pool "$AGENT_POOL" \
  --agent "$AGENT_NAME" \
  --acceptTeeEula
EOF

# -----------------------------
# Install & start service
# -----------------------------
cd "$AGENT_DIR"
echo "Installing agent service..."
sudo ./svc.sh install

echo "Starting agent service..."
sudo ./svc.sh start

echo "=== Azure DevOps Agent Bootstrap Completed Successfully ==="
