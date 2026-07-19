import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')
stdin, stdout, stderr = ssh.exec_command("lscpu | grep 'Model name'")
print(stdout.read().decode().strip())
ssh.close()
