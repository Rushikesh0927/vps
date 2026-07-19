import paramiko
import time
import re

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

shell = ssh.invoke_shell()
shell.send('echo rushi1928 | sudo -S tmux kill-session -t bore\n')
time.sleep(2)
shell.send('echo rushi1928 | sudo -S tmux new-session -d -s bore "bore local 25565 --to bore.pub"\n')
time.sleep(3)

stdin, stdout, stderr = ssh.exec_command('echo rushi1928 | sudo -S tmux capture-pane -t bore -p')
output = stdout.read().decode('utf-8', errors='ignore')
print("TMUX OUTPUT:")
print(output)

match = re.search(r'listening at bore.pub:(\d+)', output)
if match:
    print(f"\nSUCCESS! PORT: {match.group(1)}")
else:
    print("\nFAILED TO FIND PORT")
