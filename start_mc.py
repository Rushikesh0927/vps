import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

def run(cmd):
    print(f"\n[VPS] Running: {cmd}")
    stdin, stdout, stderr = ssh.exec_command(f"echo rushi1928 | sudo -S sh -c '{cmd}'")
    exit_status = stdout.channel.recv_exit_status()
    out = stdout.read().decode().strip()
    err = stderr.read().decode().strip()
    if out: print(out)
    if err: print(err)

run("rm -rf /opt/vps-infra")
run("git clone https://github.com/Rushikesh0927/vps.git /opt/vps-infra")
run("cd /opt/vps-infra/docker/compose/minecraft && docker compose up -d")
run("docker ps | grep minecraft")

ssh.close()
