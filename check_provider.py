import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

def run(cmd):
    stdin, stdout, stderr = ssh.exec_command(f"echo rushi1928 | sudo -S sh -c '{cmd}'", timeout=30)
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    if out: print(out)

# Check OS / cloud metadata to identify VPS provider
print("=== OS Info ===")
run("cat /etc/os-release | grep PRETTY_NAME")

print("\n=== VPS provider hints ===")
run("curl -s --max-time 2 http://169.254.169.254/metadata/v1/region 2>/dev/null || echo 'not digitalocean'")
run("curl -s --max-time 2 http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo 'not aws'")
run("curl -s --max-time 2 -H 'Metadata: true' 'http://169.254.169.254/metadata/instance?api-version=2021-02-01' 2>/dev/null | head -c 100 || echo 'not azure'")
run("curl -s --max-time 2 http://metadata.google.internal/computeMetadata/v1/project/project-id -H 'Metadata-Flavor: Google' 2>/dev/null || echo 'not gcp'")

print("\n=== System Product ===")
run("cat /sys/class/dmi/id/board_vendor 2>/dev/null || echo unknown")
run("cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo unknown")

ssh.close()
