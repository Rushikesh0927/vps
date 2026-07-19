import paramiko
import re

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

def run(cmd):
    print(f"\n[VPS] {cmd}")
    stdin, stdout, stderr = ssh.exec_command(f"echo rushi1928 | sudo -S sh -c '{cmd}'")
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    if out: print(out)
    if err: print(err)

# 1. Update server.js to ping the host IP instead of 'minecraft' hostname
run("sed -i \"s/'minecraft', 25565/'100.71.55.44', 25565/g\" /opt/vps-infra/docker/compose/dashboard/server.js")

# 2. Update docker-compose.yml to remove network_mode: "host" so port mapping 80:8080 actually works
run("sed -i '/network_mode/d' /opt/vps-infra/docker/compose/dashboard/docker-compose.yml")

# 3. Rebuild and restart the container
run("cd /opt/vps-infra/docker/compose/dashboard && docker compose up -d --build --force-recreate")
run("docker logs dashboard")

ssh.close()
print("Fixed!")
