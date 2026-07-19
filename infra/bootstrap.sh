#!/bin/bash
set -e

# Default to a placeholder if not provided
REPO_URL=${VPS_REPO_URL:-"https://github.com/Rushikesh0927/vps.git"}
CLONE_DIR="/opt/vps-infra"

echo "=========================================="
echo " Starting AuraNodes VPS Bootstrap Process "
echo "=========================================="

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (or use sudo curl ... | sudo bash)."
  exit 1
fi

echo "[*] Updating apt repositories and installing git..."
apt-get update -y
apt-get install -y git curl unzip tar jq

if [ -d "$CLONE_DIR" ]; then
  echo "[*] Repository already exists at $CLONE_DIR. Pulling latest..."
  cd "$CLONE_DIR"
  git pull
else
  echo "[*] Cloning repository to $CLONE_DIR..."
  git clone "$REPO_URL" "$CLONE_DIR"
  cd "$CLONE_DIR"
fi

echo "[*] Making infrastructure scripts executable..."
chmod +x infra/*.sh

echo "[*] Executing main installer..."
./infra/install.sh

echo "=========================================="
echo " Bootstrap Complete!                      "
echo "=========================================="
