import paramiko
from scp import SCPClient
import os

print("Connecting to VPS...")
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

def run(cmd):
    print(f"\n[VPS] {cmd}")
    stdin, stdout, stderr = ssh.exec_command(f"echo rushi1928 | sudo -S {cmd}")
    stdout.channel.recv_exit_status()
    print(stdout.read().decode().strip())
    print(stderr.read().decode().strip())

# Stop server first so we don't corrupt files
run("docker compose -f /opt/vps-infra/docker/compose/minecraft/docker-compose.yml stop")

# Upload the zip files
print("Uploading worlds over SFTP (this might take a few minutes)...")
with SCPClient(ssh.get_transport()) as scp:
    scp.put(r"C:\Users\yemul\Desktop\vps\minecraft_worlds\world.zip", "/home/rushi/world.zip")
    print("- Uploaded world.zip")
    scp.put(r"C:\Users\yemul\Desktop\vps\minecraft_worlds\world_nether.zip", "/home/rushi/world_nether.zip")
    print("- Uploaded world_nether.zip")
    scp.put(r"C:\Users\yemul\Desktop\vps\minecraft_worlds\world_the_end.zip", "/home/rushi/world_the_end.zip")
    print("- Uploaded world_the_end.zip")

print("Extracting worlds...")
run("rm -rf /opt/vps-infra/docker/compose/minecraft/data/world*")
run("unzip -o /home/rushi/world.zip -d /opt/vps-infra/docker/compose/minecraft/data/world")
run("unzip -o /home/rushi/world_nether.zip -d /opt/vps-infra/docker/compose/minecraft/data/world_nether")
run("unzip -o /home/rushi/world_the_end.zip -d /opt/vps-infra/docker/compose/minecraft/data/world_the_end")

# Clean up zip files
run("rm /home/rushi/world.zip /home/rushi/world_nether.zip /home/rushi/world_the_end.zip")

print("Restarting server...")
run("docker compose -f /opt/vps-infra/docker/compose/minecraft/docker-compose.yml start")

ssh.close()
print("Done! Aternos worlds restored.")
