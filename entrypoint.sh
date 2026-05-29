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

# Write API keys to .env
mkdir -p $HERMES_HOME
cat > $HERMES_HOME/.env << EOF
DEEPSEEK_API_KEY=sk-58c3d462886c4eb6bfacd631d8c55178
EOF

echo ""
echo "  Telegram Bot: ✓ Configured"
echo "  DeepSeek:     ✓ Configured"
echo "  Hermes Home:  $HERMES_HOME"
echo ""

# Start the gateway
exec python -m gateway.run --config $HERMES_HOME/config.yaml
