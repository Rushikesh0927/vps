import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

def run(cmd):
    print(f"\n[VPS] {cmd}")
    stdin, stdout, stderr = ssh.exec_command(f"echo rushi1928 | sudo -S sh -c '{cmd}'", timeout=120)
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    if out: print(out)
    if err: print(err)

# 1. Fix ownership so SFTP can write, then upload rclone config
run("mkdir -p /home/rushi/.config/rclone")
run("chown -R rushi:rushi /home/rushi/.config")

print("Uploading rclone config...")
sftp = ssh.open_sftp()
sftp.put('rclone.conf', '/home/rushi/.config/rclone/rclone.conf')
sftp.close()

# 2. Test rclone access
print("Testing Google Drive access...")
run("rclone lsd gdrive: --config /home/rushi/.config/rclone/rclone.conf 2>&1 | head -5")

# 3. Create the backup script
backup_script = '''#!/bin/bash
RCLONE_CONFIG="/home/rushi/.config/rclone/rclone.conf"
DATA_DIR="/opt/vps-infra/docker/compose/minecraft/data"
BACKUP_DIR="/home/rushi/mc_backups"
GDRIVE_FOLDER="minecraft_backups"
MAX_BACKUPS=3

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%d%m%y_%H%M")
FILENAME="mc_backup_${TIMESTAMP}.tar.gz"

echo "[$(date)] Starting backup: $FILENAME"

echo rushi1928 | sudo -S tar -czf "${BACKUP_DIR}/${FILENAME}" -C "$DATA_DIR" . 2>/dev/null
echo rushi1928 | sudo -S chown rushi:rushi "${BACKUP_DIR}/${FILENAME}"

rclone copy "${BACKUP_DIR}/${FILENAME}" "gdrive:${GDRIVE_FOLDER}/" --config "$RCLONE_CONFIG" 2>&1

if [ $? -eq 0 ]; then
    echo "[$(date)] Upload successful: $FILENAME"
else
    echo "[$(date)] Upload FAILED: $FILENAME"
fi

rm -f "${BACKUP_DIR}/${FILENAME}"

BACKUP_COUNT=$(rclone lsf "gdrive:${GDRIVE_FOLDER}/" --config "$RCLONE_CONFIG" 2>/dev/null | wc -l)

if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    DELETE_COUNT=$((BACKUP_COUNT - MAX_BACKUPS))
    rclone lsf "gdrive:${GDRIVE_FOLDER}/" --config "$RCLONE_CONFIG" 2>/dev/null | sort | head -n "$DELETE_COUNT" | while read -r old_file; do
        echo "[$(date)] Deleting old backup: $old_file"
        rclone deletefile "gdrive:${GDRIVE_FOLDER}/${old_file}" --config "$RCLONE_CONFIG" 2>/dev/null
    done
fi

echo "[$(date)] Backup complete."
rclone lsf "gdrive:${GDRIVE_FOLDER}/" --config "$RCLONE_CONFIG" 2>/dev/null
'''

# Write backup script to a temp file then move it
sftp = ssh.open_sftp()
with sftp.open('/home/rushi/mc_backup.sh', 'w') as f:
    f.write(backup_script)
sftp.close()

run("chmod +x /home/rushi/mc_backup.sh")

# 4. Setup cron job (every 5 minutes)
print("Setting up cron job...")
run("crontab -u rushi -l 2>/dev/null | grep -v mc_backup > /tmp/crontab_clean || true")
run('echo "*/5 * * * * /home/rushi/mc_backup.sh >> /home/rushi/mc_backup.log 2>&1" >> /tmp/crontab_clean')
run("crontab -u rushi /tmp/crontab_clean")
run("rm /tmp/crontab_clean")

run("crontab -u rushi -l")

# 5. Run first backup now
print("\nRunning first backup to test...")
run("bash /home/rushi/mc_backup.sh")

ssh.close()
print("\nAutomatic backups are now active!")
