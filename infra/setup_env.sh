#!/bin/bash
set -e

echo "[*] Installing Python and utilities..."
apt-get update -y
apt-get install -y python3 python3-pip python3-venv htop tmux net-tools software-properties-common wget build-essential acl

echo "[*] Installing Node.js 20 LTS..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
else
    echo "[*] Node.js is already installed: $(node -v)"
fi


echo "[*] Environment setup complete."
