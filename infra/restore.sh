#!/bin/bash
set -e

GDRIVE_REMOTE="gdrive:vps-backups"
BACKUP_DIR="/opt/vps-infra/backups"

echo "[*] Starting restore process at $(date)"

mkdir -p "$BACKUP_DIR"

if ! rclone about "$GDRIVE_REMOTE" > /dev/null 2>&1; then
    echo "[!] rclone cannot connect to $GDRIVE_REMOTE. Skipping restore."
    echo "[!] If this is a fresh setup, make sure you ran rclone config."
    exit 0
fi

echo "[*] Downloading latest backups from Google Drive..."
rclone sync "$GDRIVE_REMOTE" "$BACKUP_DIR" -v

# Find the latest docker data backup
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/docker_data_*.tar.gz 2>/dev/null | head -n 1)

if [ -n "$LATEST_BACKUP" ]; then
    echo "[*] Restoring $LATEST_BACKUP..."
    mkdir -p /opt/vps-infra/docker
    tar -xzf "$LATEST_BACKUP" -C /opt/vps-infra/docker
    echo "[*] Restore complete."
else
    echo "[!] No backup found to restore."
fi

echo "[*] Restore process complete at $(date)"
