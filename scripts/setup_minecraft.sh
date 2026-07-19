#!/bin/bash
set -e

MC_DIR="/opt/vps-infra/docker/compose/minecraft"
BACKUP_ZIP="$1"

echo "=========================================="
echo "    Minecraft Server Deployment Script    "
echo "=========================================="

if [ -z "$BACKUP_ZIP" ]; then
    echo "Usage: ./setup_minecraft.sh <path_to_aternos_backup.zip>"
    echo "Please download the backup from Aternos and upload it to the VPS first."
    exit 1
fi

if [ ! -f "$BACKUP_ZIP" ]; then
    echo "[!] Error: Backup file not found at $BACKUP_ZIP"
    exit 1
fi

echo "[*] Creating Minecraft data directory..."
mkdir -p "$MC_DIR/data"

echo "[*] Extracting Aternos backup..."
# Aternos backups contain the 'world' folder, 'world_nether', etc.
# We extract it directly into the data directory
unzip -q -o "$BACKUP_ZIP" -d "$MC_DIR/data/"

echo "[*] Ensuring permissions are correct..."
# The itzg container usually runs as UID 1000
chown -R 1000:1000 "$MC_DIR/data/"

echo "[*] Starting the Minecraft server..."
cd "$MC_DIR"
docker compose up -d

echo "=========================================="
echo " Minecraft Server is starting!"
echo " Check logs with: docker logs -f minecraft"
echo "=========================================="
