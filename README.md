# JARVIS Cloud — Persistent Hermes Agent on Railway

Deploy JARVIS (Hermes Agent) to Railway for 24/7 availability with Telegram integration, while maintaining the ability to manage your Windows PC through a secure local tunnel.

## Architecture

```
Telegram ──► Railway (24/7) ◄── SSH/Tunnel ──► Windows PC
                │                                      │
           Web APIs, Cron,                    Local files, Trading
           Webhooks, Skills                    Terminal, Browser
```

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | Builds Hermes Agent container |
| `config.yaml` | Cloud-optimized config (Telegram, SSH backend) |
| `entrypoint.sh` | Startup — sets keys, launches gateway |
| `railway.json` | Railway deployment config |
| `local-tunnel/server.js` | Windows daemon for local command execution |
| `local-tunnel/install-service.js` | Install as Windows service |

## Setup

### 1. Deploy to Railway

Connect this repo to Railway. Set these environment variables:

| Variable | Required | Description |
|---|---|---|
| `TELEGRAM_BOT_TOKEN` | Yes | Your Telegram bot token |
| `DEEPSEEK_API_KEY` | Yes | DeepSeek API key |
| `LOCAL_PC_HOST` | No | Windows PC hostname/IP (for SSH tunnel) |
| `LOCAL_PC_USER` | No | Windows username |
| `LOCAL_PC_PORT` | No | SSH port (default: 22) |

### 2. Local Tunnel (Windows)

```bash
cd local-tunnel
npm install
npm start
```

For persistent background service (admin):
```bash
node install-service.js
```

The daemon will print an auth token. Add `TUNNEL_AUTH_TOKEN` to your Tunnel provider.

## Commands (via Telegram)

Once deployed, message your bot on Telegram. JARVIS will respond 24/7.
When your PC is on and connected, JARVIS can access local files and run commands.
When your PC is off, JARVIS still handles cloud tasks and responds to messages.
