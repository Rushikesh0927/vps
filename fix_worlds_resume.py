import paramiko
import time

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928', timeout=30)

def run(cmd):
    print(f"\n[VPS] {cmd}")
    stdin, stdout, stderr = ssh.exec_command(f"echo rushi1928 | sudo -S {cmd}", timeout=120)
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    if out: print(out.encode('ascii', errors='ignore').decode())
    if err: print(err.encode('ascii', errors='ignore').decode())

# Unzip directly into data/ so it respects Aternos' internal folder structure
print("Extracting worlds...")
run("unzip -o /home/rushi/world.zip -d /opt/vps-infra/docker/compose/minecraft/data/")
run("unzip -o /home/rushi/world_nether.zip -d /opt/vps-infra/docker/compose/minecraft/data/")
run("unzip -o /home/rushi/world_the_end.zip -d /opt/vps-infra/docker/compose/minecraft/data/")

# Fix permissions
print("Fixing permissions...")
run("chown -R 1000:1000 /opt/vps-infra/docker/compose/minecraft/data/")
run("rm -f /home/rushi/world*.zip")

print("Restarting server...")
run("docker compose -f /opt/vps-infra/docker/compose/minecraft/docker-compose.yml start")

ssh.close()
print("Fixed nested folders and successfully restarted!")
