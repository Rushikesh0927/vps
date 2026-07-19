import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

def run(cmd):
    stdin, stdout, stderr = ssh.exec_command(f"echo rushi1928 | sudo -S sh -c '{cmd}'", timeout=30)
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    if out: print(out)
    if err and 'password' not in err.lower(): print(err)

# Check what's listening
run("ss -tlnp")
print("---MINECRAFT COMPOSE---")
run("cat /opt/vps-infra/docker/compose/minecraft/docker-compose.yml")
print("---DASHBOARD COMPOSE---")
run("cat /opt/vps-infra/docker/compose/dashboard/docker-compose.yml")

ssh.close()
