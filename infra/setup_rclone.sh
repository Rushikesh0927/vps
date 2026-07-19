#!/bin/bash
set -e

echo "[*] Installing rclone..."
if ! command -v rclone &> /dev/null; then
    curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip
    unzip -q rclone-current-linux-amd64.zip
    cd rclone-*-linux-amd64
    cp rclone /usr/bin/
    chown root:root /usr/bin/rclone
    chmod 755 /usr/bin/rclone
    mkdir -p /usr/local/share/man/man1
    cp rclone.1 /usr/local/share/man/man1/
    mandb
    cd ..
    rm -rf rclone-*-linux-amd64*
else
    echo "[*] rclone is already installed: $(rclone --version | head -n 1)"
fi

echo "[*] Configuring rclone..."
mkdir -p /root/.config/rclone
if [ -f "/root/.secrets/rclone.conf" ]; then
    echo "[*] Found rclone.conf in secrets. Copying to /root/.config/rclone/"
    cp /root/.secrets/rclone.conf /root/.config/rclone/rclone.conf
    chmod 600 /root/.config/rclone/rclone.conf
else
    echo "[!] WARNING: rclone.conf NOT FOUND!"
    echo "[!] You must manually configure rclone before backups will work."
    echo "[!] Run: rclone config"
fi

echo "[*] rclone setup complete."
