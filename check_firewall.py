import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

def run(cmd):
    stdin, stdout, stderr = ssh.exec_command(f"echo rushi1928 | sudo -S sh -c '{cmd}'", timeout=30)
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    if out: print(out)
    if err and 'password' not in err.lower(): print('[ERR]', err)

print("=== UFW Status ===")
run("ufw status")
print("\n=== iptables port 80 ===")
run("iptables -L INPUT -n | grep 80")
print("\n=== Current docker ps ===")
run("docker ps")
print("\n=== Port 80 listening ===")
run("ss -tlnp | grep ':80'")
print("\n=== curl localhost ===")
run("curl -s -o /dev/null -w '%{http_code}' http://localhost:80")
print("\n=== Public IP test from VPS ===")
run("curl -s -o /dev/null -w '%{http_code}' http://8.243.184.137:80")

ssh.close()
