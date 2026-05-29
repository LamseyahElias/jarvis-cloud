#!/bin/bash
set -e

echo "================================================"
echo "  JARVIS — Cloud Deployment"
echo "  Starting Hermes Agent Gateway..."
echo "================================================"

cd /app/hermes-agent

# Activate virtual environment
. .venv/bin/activate

# Ensure HERMES_HOME is set
export HERMES_HOME="${HERMES_HOME:-/app/hermes-home}"

# Check required env vars
if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    echo "WARNING: TELEGRAM_BOT_TOKEN not set. Telegram platform will be disabled."
fi

if [ -z "$DEEPSEEK_API_KEY" ]; then
    echo "ERROR: DEEPSEEK_API_KEY is required."
    exit 1
fi

# Write DeepSeek API key to .env
echo "DEEPSEEK_API_KEY=$DEEPSEEK_API_KEY" > $HERMES_HOME/.env

echo ""
echo "  Telegram Bot: ${TELEGRAM_BOT_TOKEN:+✓ Configured}"
echo "  DeepSeek:     ✓ Configured"
echo "  SSH Backend:  ${LOCAL_PC_HOST:+→ $LOCAL_PC_HOST:$LOCAL_PC_PORT}"
echo "  Hermes Home:  $HERMES_HOME"
echo ""

# Start the gateway
exec python -m gateway.run --config $HERMES_HOME/config.yaml
