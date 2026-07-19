import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

def run(cmd):
    print(f"[VPS] {cmd}")
    stdin, stdout, stderr = ssh.exec_command(f"echo rushi1928 | sudo -S sh -c '{cmd}'")
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    if out: print(out)
    if err: print(err)

run("curl -SsL https://playit-cloud.github.io/ppa/key.gpg | apt-key add -")
run("curl -SsL -o /etc/apt/sources.list.d/playit-cloud.list https://playit-cloud.github.io/ppa/playit-cloud.list")
run("apt update")
run("apt install -y playit")
run("systemctl enable playit")
run("systemctl restart playit")

print("Playit installed. Getting claim URL from logs...")
run("sleep 3 && grep -o 'https://playit.gg/claim/.*' /var/log/syslog | tail -n 1")

ssh.close()
