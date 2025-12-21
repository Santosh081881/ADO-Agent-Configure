#!/bin/bash
set -euo pipefail

ORG_URL="https://dev.azure.com/santosh1808"
AGENT_POOL="MyPool"
AGENT_NAME="ado-agent"
ADO_PAT="ArjJQYKa6j6abahmRSzpRmG7ZxjQvYfGlYjM2XiJW6Zxo8KAt4kJJQQJ99BLACAAAAAAAAAAAAASAZDO4Vbn"

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
