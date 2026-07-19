#!/bin/bash
set -e

# Configuration
BACKUP_DIR="/opt/vps-infra/backups"
GDRIVE_REMOTE="gdrive:vps-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "[*] Starting backup process at $(date)"

mkdir -p "$BACKUP_DIR"

# 1. Backup Docker Compose Data (Assuming bind mounts are used inside /opt/vps-infra/docker/data)
echo "[*] Backing up Docker data..."
# Use tar to compress everything in the docker directory, excluding any huge caches if necessary
if [ -d "/opt/vps-infra/docker" ]; then
    tar -czf "$BACKUP_DIR/docker_data_$TIMESTAMP.tar.gz" -C /opt/vps-infra/docker . || true
else
    echo "[!] Docker directory not found, skipping."
fi

# 2. Upload to Google Drive using rclone
echo "[*] Uploading to Google Drive ($GDRIVE_REMOTE)..."
if rclone about "$GDRIVE_REMOTE" > /dev/null 2>&1; then
    rclone sync "$BACKUP_DIR" "$GDRIVE_REMOTE" -v
    
    # 3. Cleanup old local backups (keep last 5 to save VPS disk space)
    echo "[*] Cleaning up old local backups..."
    ls -tp "$BACKUP_DIR"/docker_data_*.tar.gz 2>/dev/null | grep -v '/$' | tail -n +6 | xargs -I {} rm -- {} || true
else
    echo "[!] ERROR: rclone cannot access $GDRIVE_REMOTE. Backup upload failed."
fi

echo "[*] Backup process complete at $(date)"
