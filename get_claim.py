import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

def run(cmd):
    stdin, stdout, stderr = ssh.exec_command(cmd)
    return stdout.read().decode('utf-8', errors='ignore').strip()

print(run("echo rushi1928 | sudo -S systemctl start playit"))
print("CLAIM URL:")
print(run("grep -o 'https://playit.gg/claim/[a-zA-Z0-9]*' /var/log/syslog | tail -n 1"))
