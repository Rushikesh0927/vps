import paramiko, os, zipfile

# Zip dashboard (excluding node_modules)
zip_path = 'dashboard.zip'
print("Zipping dashboard...")
with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for root, dirs, files in os.walk('dashboard'):
        if 'node_modules' in root:
            continue
        for file in files:
            file_path = os.path.join(root, file)
            zipf.write(file_path, arcname=os.path.relpath(file_path, 'dashboard'))

# Connect
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

def run(cmd):
    print(f"\n[VPS] {cmd}")
    stdin, stdout, stderr = ssh.exec_command(f"echo rushi1928 | sudo -S sh -c '{cmd}'", timeout=120)
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    if out: print(out.encode('ascii', errors='ignore').decode())
    if err: print(err.encode('ascii', errors='ignore').decode())

# Upload zip
print("Uploading...")
sftp = ssh.open_sftp()
sftp.put(zip_path, '/home/rushi/dashboard.zip')
sftp.close()

# Deploy
run("rm -rf /opt/vps-infra/docker/compose/dashboard")
run("mkdir -p /opt/vps-infra/docker/compose/dashboard")
run("unzip -o /home/rushi/dashboard.zip -d /opt/vps-infra/docker/compose/dashboard")
run("rm /home/rushi/dashboard.zip")

# Write docker-compose.yml
compose_content = """services:
  dashboard:
    build: .
    container_name: dashboard
    restart: unless-stopped
    ports:
      - "80:8080"
    environment:
      - ADMIN_PASSWORD=rushiadmin
      - FRIENDS_PIN=1928
      - SERVER_IP=172.17.0.1
      - DISPLAY_IP=rushiserver.duckdns.org:9508
      - BEDROCK_IP=qgv7kxef0w.localto.net:3383
      - DATA_DIR=/data
      - RCLONE_CONFIG=/root/.config/rclone/rclone.conf
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /opt/vps-infra/docker/compose/minecraft/data:/data
      - /home/rushi/.config/rclone:/root/.config/rclone:ro
"""

# Write compose file locally then upload
with open('_tmp_compose.yml', 'w') as f:
    f.write(compose_content)

sftp = ssh.open_sftp()
sftp.put('_tmp_compose.yml', '/home/rushi/docker-compose.yml')
sftp.close()

run("mv /home/rushi/docker-compose.yml /opt/vps-infra/docker/compose/dashboard/docker-compose.yml")

# Build and start
run("cd /opt/vps-infra/docker/compose/dashboard && docker compose up -d --build --force-recreate")

# Verify
run("docker ps")
run("sleep 2 && curl -s -o /dev/null -w '%{http_code}' http://localhost:80")

ssh.close()
os.remove(zip_path)
os.remove('_tmp_compose.yml')
print("\nDashboard v2 deployed!")
