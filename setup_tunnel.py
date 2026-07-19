import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('100.71.55.44', username='rushi', password='rushi1928')

def run(cmd):
    stdin, stdout, stderr = ssh.exec_command(f'echo rushi1928 | sudo -S sh -c "{cmd}"')
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    return out, err

print("Routing DNS...")
stdin, stdout, stderr = ssh.exec_command('cloudflared tunnel route dns rushimc-dashboard rushi-vps.me')
print('ROUTE OUT:', stdout.read().decode('utf-8'))
print('ROUTE ERR:', stderr.read().decode('utf-8'))

config = """tunnel: 12f1049c-b857-4c09-8c34-9deadaa16898
credentials-file: /home/rushi/.cloudflared/12f1049c-b857-4c09-8c34-9deadaa16898.json
protocol: http2

ingress:
  - hostname: rushi-vps.me
    service: http://localhost:80
  - service: http_status:404
"""

print("Writing config...")
stdin, stdout, stderr = ssh.exec_command(f"cat << 'EOF' > /home/rushi/.cloudflared/config.yml\n{config}EOF")
stdout.read()

service = """[Unit]
Description=Cloudflare Tunnel for Rushi's MC Dashboard
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=rushi
Restart=on-failure
RestartSec=5s
ExecStart=/usr/bin/cloudflared tunnel --config /home/rushi/.cloudflared/config.yml run
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
"""

print("Updating service...")
run(f"cat << 'EOF' > /etc/systemd/system/cloudflared-dashboard.service\n{service}EOF")
run('systemctl daemon-reload')
run('systemctl restart cloudflared-dashboard')

print('DONE')
ssh.close()
