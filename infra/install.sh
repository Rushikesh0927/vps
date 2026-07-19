#!/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LOG_FILE="/var/log/vps-install.log"

# Log all output to file and console
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[*] Starting infrastructure installation at $(date)"

# Wait for secrets (rclone conf, .env) if they are being scp'd over
if [ -f "/tmp/secrets.tar.gz" ]; then
    echo "[*] Found secrets at /tmp/secrets.tar.gz. Extracting..."
    mkdir -p /root/.secrets
    tar -xzf /tmp/secrets.tar.gz -C /root/.secrets/
fi

echo "========================================"
echo " 1. Setting up base environment..."
echo "========================================"
"$SCRIPT_DIR/setup_env.sh"

echo "========================================"
echo " 2. Setting up Docker..."
echo "========================================"
"$SCRIPT_DIR/setup_docker.sh"

echo "========================================"
echo " 3. Setting up Rclone (Google Drive)..."
echo "========================================"
"$SCRIPT_DIR/setup_rclone.sh"

echo "========================================"
echo " 4. Installing systemd timers..."
echo "========================================"
if ls "$SCRIPT_DIR/../configs/systemd/"*.timer 1> /dev/null 2>&1; then
    cp "$SCRIPT_DIR/../configs/systemd/"*.timer /etc/systemd/system/
    cp "$SCRIPT_DIR/../configs/systemd/"*.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable backup.timer --now
    systemctl enable update.timer --now
    echo "[*] Timers enabled successfully."
else
    echo "[!] No systemd timers found to install."
fi

echo "========================================"
echo " 5. Restoring Backups..."
echo "========================================"
"$SCRIPT_DIR/restore.sh"

echo "[*] Installation completed successfully at $(date)!"
echo "Check $LOG_FILE for full logs."
