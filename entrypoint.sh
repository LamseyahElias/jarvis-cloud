#!/bin/bash
set -e

echo "================================================"
echo "  JARVIS — Cloud Deployment"
echo "  Starting Hermes Agent Gateway..."
echo "================================================"

cd /app/hermes-agent
. .venv/bin/activate

export HERMES_HOME="${HERMES_HOME:-/app/hermes-home}"
mkdir -p $HERMES_HOME

# Write API key to .env (Hermes reads this)
if [ -n "$DEEPSEEK_API_KEY" ]; then
    echo "DEEPSEEK_API_KEY=$DEEPSEEK_API_KEY" > $HERMES_HOME/.env
fi

echo ""
echo "  Telegram: ${TELEGRAM_BOT_TOKEN:+✓} ${TELEGRAM_BOT_TOKEN:-✗ (not set)}"
echo "  DeepSeek: ${DEEPSEEK_API_KEY:+✓} ${DEEPSEEK_API_KEY:-✗ (not set)}"
echo "  Hermes:   $HERMES_HOME"
echo ""

exec python -m gateway.run --config $HERMES_HOME/config.yaml
