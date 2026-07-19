# AuraNodes VPS Disaster Recovery Guide

## Philosophy
This VPS is designed as **cattle**. It can be deleted, reset, or destroyed at any time without causing permanent data loss. 

All infrastructure code is stored in GitHub.
All application data (databases, volumes, Minecraft worlds) is backed up to Google Drive every 15 minutes.

## The Rebuild Process (Target: < 30 Minutes)

If the VPS is lost, follow these exact steps to rebuild it.

### Step 1: Provision a New VPS
1. Log into your AuraNodes dashboard.
2. Provision a new Ubuntu 22.04 LTS instance.
3. Note the new public IP address.

### Step 2: Install Tailscale
Since AuraNodes does not expose inbound ports (22, 3389) publicly, you must install Tailscale first to gain SSH access.
*You may be able to do this via the AuraNodes web console/VNC.*

```bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up
```
*(Alternatively, pass a Tailscale Auth Key if you have one: `tailscale up --authkey tskey-auth-XXX`)*

### Step 3: Securely Transfer Secrets
From your local Windows machine, you need to transfer the `secrets.tar.gz` to the new VPS. This file contains the `rclone.conf` needed to access Google Drive backups.

```powershell
# From Windows, using the new Tailscale IP of the VPS:
scp C:\path\to\secrets.tar.gz root@<NEW_TAILSCALE_IP>:/tmp/secrets.tar.gz
```

### Step 4: Run the Bootstrap Command
SSH into the new VPS over Tailscale:
```bash
ssh root@<NEW_TAILSCALE_IP>
```

Run the one-liner to rebuild everything:
```bash
curl -sL https://raw.githubusercontent.com/your-username/vps/main/infra/bootstrap.sh | bash
```

### Step 5: Wait and Verify
The bootstrap script will automatically:
1. Install Git, Docker, Node.js, Python, rclone.
2. Clone your infrastructure repository.
3. Pull the latest backups from Google Drive (Minecraft, databases, etc.).
4. Start all Docker Compose stacks.

Once complete, verify that the services (like Minecraft) are running and accessible.

## Updating Secrets
If you need to update `rclone.conf` or other secrets, update your local `secrets.tar.gz` so it is ready for the next disaster.
