import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

cmds = [
    'wget -q https://localtonet.com/download/localtonet-linux-x64.zip',
    'unzip -o -q localtonet-linux-x64.zip',
    'sudo mv localtonet /usr/local/bin/localtonet',
    'sudo chmod +x /usr/local/bin/localtonet',
    'localtonet --help'
]

for cmd in cmds:
    stdin, stdout, stderr = ssh.exec_command(f'echo rushi1928 | sudo -S sh -c "{cmd}"')
    print(f"--- {cmd} ---")
    print(stdout.read().decode('utf-8', errors='ignore'))
    print(stderr.read().decode('utf-8', errors='ignore'))
