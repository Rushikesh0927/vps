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
if [ -d "/opt/vps-infra" ]; then
    # We explicitly define the directories that have docker-compose.yml files
    COMPOSE_DIRS=(
        "/opt/vps-infra/docker/compose/example"
        "/opt/vps-infra/docker/compose/friends"
        "/opt/vps-infra/docker/compose/cloudflared"
        "/opt/vps-infra/hari"
        "/opt/vps-infra/OpenWA"
        "/opt/vps-infra/dashboard"
    )

    for d in "${COMPOSE_DIRS[@]}" ; do
        if [ -d "$d" ] && [ -f "$d/docker-compose.yml" ]; then
            echo "[*] Updating compose stack in $d"
            cd "$d"
            docker compose pull
            docker compose up -d
        fi
    done
fi

echo "[*] System update complete at $(date)"
