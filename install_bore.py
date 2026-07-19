import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

cmds = [
    'wget -q https://github.com/ekzhang/bore/releases/download/v0.4.1/bore-v0.4.1-x86_64-unknown-linux-musl.tar.gz',
    'tar xf bore-v0.4.1-x86_64-unknown-linux-musl.tar.gz',
    'sudo mv bore /usr/local/bin/bore',
    'sudo chmod +x /usr/local/bin/bore',
    'rm bore-v0.4.1-x86_64-unknown-linux-musl.tar.gz'
]

for cmd in cmds:
    stdin, stdout, stderr = ssh.exec_command(f'echo rushi1928 | sudo -S sh -c "{cmd}"')
    print(stdout.read().decode('utf-8', errors='ignore'))
