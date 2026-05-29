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

cat > $HERMES_HOME/.env << 'KEYS'
DEEPSEEK_API_KEY=sk-58c3d462886c4eb6bfacd631d8c55178
KEYS

echo ""
echo "  Telegram Bot: ✓ Configured"
echo "  DeepSeek:     ✓ Configured"
echo "  Hermes Home:  $HERMES_HOME"
echo ""

exec python -m gateway.run --config $HERMES_HOME/config.yaml
