import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

def run(cmd):
    print(f"\n[VPS] {cmd}")
    stdin, stdout, stderr = ssh.exec_command(f"echo rushi1928 | sudo -S {cmd}")
    stdout.channel.recv_exit_status()
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    if out: print(out.encode('ascii', errors='ignore').decode())
    if err: print(err.encode('ascii', errors='ignore').decode())

run("docker compose -f /opt/vps-infra/docker/compose/minecraft/docker-compose.yml stop")

print("Downloading world.zip safely...")
run("gdown 17DInA6Km6LSniWEOoGSrhdB1gQWlIYf_ -O /home/rushi/world.zip")

print("Extracting world.zip...")
run("rm -rf /opt/vps-infra/docker/compose/minecraft/data/world")
run("unzip -o /home/rushi/world.zip -d /opt/vps-infra/docker/compose/minecraft/data/world")
run("rm /home/rushi/world.zip")

run("docker compose -f /opt/vps-infra/docker/compose/minecraft/docker-compose.yml start")

ssh.close()
print("Fixed world download!")
