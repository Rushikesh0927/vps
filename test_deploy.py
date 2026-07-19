import paramiko
from scp import SCPClient
import os
import zipfile

def create_zip():
    print("Creating zip file...")
    zipf = zipfile.ZipFile('vps.zip', 'w', zipfile.ZIP_DEFLATED)
    for root, dirs, files in os.walk('.'):
        for file in files:
            if file == 'vps.zip' or file == 'test_deploy.py':
                continue
            zipf.write(os.path.join(root, file))
    zipf.close()

def main():
    create_zip()
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    print("Connecting to 100.71.55.44...")
    ssh.connect('100.71.55.44', username='rushi', password='rushi1928')
    
    print("Uploading vps.zip...")
    with SCPClient(ssh.get_transport()) as scp:
        scp.put('vps.zip', '/tmp/vps.zip')
    
    print("Extracting and running setup...")
    # we need sudo. Let's use sudo -S
    commands = [
        "echo rushi1928 | sudo -S mkdir -p /opt/vps-infra",
        "echo rushi1928 | sudo -S apt-get update -y",
        "echo rushi1928 | sudo -S apt-get install -y unzip",
        "echo rushi1928 | sudo -S unzip -o /tmp/vps.zip -d /opt/vps-infra",
        "echo rushi1928 | sudo -S chmod +x /opt/vps-infra/infra/*.sh",
        "echo rushi1928 | sudo -S bash -c 'cd /opt/vps-infra && ./infra/install.sh'"
    ]
    
    for cmd in commands:
        print(f"Running: {cmd}")
        stdin, stdout, stderr = ssh.exec_command(cmd)
        exit_status = stdout.channel.recv_exit_status()
        out = stdout.read().decode()
        err = stderr.read().decode()
        if out: print(out.strip())
        if err: print(err.strip())
        if exit_status != 0:
            print(f"Command failed with status {exit_status}")
            break
            
    ssh.close()
    print("Done!")

if __name__ == "__main__":
    main()
