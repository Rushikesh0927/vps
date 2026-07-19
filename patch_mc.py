import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

def run(cmd):
    print(f"\n[VPS] Running: {cmd}")
    # Run directly with sudo, no sh -c which messes up quotes
    stdin, stdout, stderr = ssh.exec_command(f"echo rushi1928 | sudo -S {cmd}")
    exit_status = stdout.channel.recv_exit_status()
    out = stdout.read().decode().strip()
    err = stderr.read().decode().strip()
    if out: print(out)
    if err: print(err)

# 1. Enable TNT / Piston Duping in Paper
run('sed -i "s/allow-piston-duplication: false/allow-piston-duplication: true/g" /opt/vps-infra/docker/compose/minecraft/data/config/paper-global.yml')

# 2. Enable Bedrock Nether Roof Building in Geyser
run('sed -i "s/above-bedrock-nether-building: false/above-bedrock-nether-building: true/g" /opt/vps-infra/docker/compose/minecraft/data/plugins/Geyser-Spigot/config.yml')

# 3. Restart the Minecraft Container to apply changes
run('docker compose -f /opt/vps-infra/docker/compose/minecraft/docker-compose.yml restart')

ssh.close()
print("Done patching configurations!")
