import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

def run(cmd):
    print(f"\n[VPS] Running: {cmd}")
    # We use sudo because rclone config is stored in /root
    # We pass the password for sudo just in case
    stdin, stdout, stderr = ssh.exec_command(f"echo rushi1928 | sudo -S {cmd}")
    out = stdout.read().decode().strip()
    err = stderr.read().decode().strip()
    if out: print(out)
    if err: print(err)

print("Verifying Google Drive connection...")
run("rclone about gdrive:")
run("rclone lsd gdrive:")

print("Verifying GitHub connection...")
run("rm -rf /tmp/vps-test")
run("git clone https://github.com/Rushikesh0927/vps.git /tmp/vps-test")
run("cd /tmp/vps-test && git log -1 --oneline")

ssh.close()
