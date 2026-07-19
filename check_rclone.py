import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

def run(cmd):
    print(f"\n[VPS] {cmd}")
    stdin, stdout, stderr = ssh.exec_command(f"echo rushi1928 | sudo -S sh -c '{cmd}'", timeout=60)
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    if out: print(out)
    if err: print(err)

# 1. Check if rclone is installed
run("which rclone")

# 2. Check rclone config
run("cat /home/rushi/.config/rclone/rclone.conf 2>/dev/null || echo 'NO_CONFIG'")

ssh.close()
