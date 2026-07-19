# Minecraft VPS Server Infrastructure

This repository contains the complete infrastructure as code and deployment scripts for a fully automated, cross-play Minecraft server running on a free Aura Nodes VPS.

## Overview

- **Server Type**: Paper (Java Edition) with GeyserMC and Floodgate (for Bedrock support).
- **Version**: Minecraft 1.21.1
- **Hosting**: Aura Nodes (Free Tier, 4GB RAM, 10GB Storage)
- **Containerization**: Docker & Docker Compose
- **Backups**: Automated every 5 minutes to Google Drive using `rclone`.

## Tunneling & Connectivity

Since the free VPS provider does not supply a dedicated public IP address and restricts port forwarding, we use external tunnels to expose the server.

### Java Edition Tunnel (`bore.pub`)
- **Service**: [Bore](http://bore.pub)
- **Port**: `9508`
- **DNS**: `rushiserver.duckdns.org` is dynamically routed to the Bore tunnel.
- **Connection Address**: `rushiserver.duckdns.org:9508`

### Bedrock Edition Tunnel (`localtonet`)
Bedrock Edition strictly requires a UDP tunnel. Since `bore` only supports TCP, we use Localtonet.
- **Service**: [Localtonet](https://localtonet.com/)
- **Connection Address**: `qgv7kxef0w.localto.net:3383`

## Web Dashboard

A custom web dashboard is deployed alongside the server on port 80. It provides real-time monitoring and management:
- Live CPU, Memory, and Network graphs
- Real-time player counts and status
- Start, Stop, and Restart controls
- Web-based file manager (edit configs instantly)
- Google Drive Backup Manager
- **Access**: Connected via Tailscale VPN at `http://100.71.55.44`

## Automated Backups

- The server uses `rclone` to back up the entire Minecraft `data/` directory.
- A cron job runs every 5 minutes: `*/5 * * * * /home/rushi/mc_backup.sh`
- Backups are compressed into `.tar.gz` and uploaded directly to a Google Drive folder named `minecraft_backups`.
- A maximum of 3 rolling backups are kept; older ones are automatically purged to save space.
- A fix was implemented to use `sudo` during the archiving phase to ensure complete backups of Docker-owned files.

## Repository Structure

- `/dashboard`: Source code for the web dashboard (Node.js + Express).
- `deploy_dashboard.py`: Script to zip, upload, and deploy the dashboard to the VPS.
- `setup_backup.py`: Script to generate the backup shell script and configure the cron job.
- `install_bore.py` / `install_localtonet.py`: Scripts to install and configure the background tunneling agents as systemd services.
- `docker-compose.yml`: (Generated on VPS) Defines the `minecraft` and `dashboard` services.

## Setup Instructions

If deploying from scratch:
1. Ensure the VPS has Docker and Python installed.
2. Run the `setup_env.sh` (if applicable) or use the python deployment scripts in order:
   - `python patch_mc.py` (Setup Minecraft server)
   - `python install_bore.py`
   - `python install_localtonet.py`
   - `python deploy_dashboard.py`
   - `python setup_backup.py`

Enjoy the server!
