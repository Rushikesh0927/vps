#!/bin/bash
set -e

echo "[*] Starting system update at $(date)"

# Update apt packages
echo "[*] Updating apt packages..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
apt-get autoremove -y

# Update docker containers if they exist
echo "[*] Updating docker images..."
if [ -d "/opt/vps-infra/docker/compose" ]; then
    cd /opt/vps-infra/docker/compose
    for d in */ ; do
        if [ -f "$d/docker-compose.yml" ]; then
            echo "[*] Updating compose stack in $d"
            cd "$d"
            docker compose pull
            docker compose up -d
            cd ..
        fi
    done
fi

echo "[*] System update complete at $(date)"
