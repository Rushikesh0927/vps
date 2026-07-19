#!/bin/bash
set -e

MC_DIR="/opt/vps-infra/docker/compose/minecraft"
BACKUP_ZIP="$1"

echo "=========================================="
echo "    Minecraft Server Deployment Script    "
echo "=========================================="

if [ -z "$1" ]; then
    echo "Usage: ./setup_minecraft.sh <world.zip> [nether.zip] [end.zip]"
    echo "Please download the backups from Aternos and upload them to the VPS first."
    exit 1
fi

echo "[*] Creating Minecraft data directory..."
mkdir -p "$MC_DIR/data"

echo "[*] Extracting Aternos backups..."

# 1. Overworld
if [ -f "$1" ]; then
    echo " -> Extracting Overworld ($1)..."
    mkdir -p "$MC_DIR/data/world"
    unzip -q -o "$1" -d "$MC_DIR/data/world/"
fi

# 2. Nether
if [ -n "$2" ] && [ -f "$2" ]; then
    echo " -> Extracting Nether ($2)..."
    mkdir -p "$MC_DIR/data/world_nether"
    unzip -q -o "$2" -d "$MC_DIR/data/world_nether/"
fi

# 3. The End
if [ -n "$3" ] && [ -f "$3" ]; then
    echo " -> Extracting The End ($3)..."
    mkdir -p "$MC_DIR/data/world_the_end"
    unzip -q -o "$3" -d "$MC_DIR/data/world_the_end/"
fi

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
