#!/bin/bash
set -e

echo "================================================"
echo "  JARVIS — Cloud Deployment"
echo "  Starting Hermes Agent Gateway..."
echo "================================================"

export HERMES_HOME="${HERMES_HOME:-/app/hermes-home}"
mkdir -p $HERMES_HOME

# Copy config from repo to Hermes home
cp /app/config.yaml $HERMES_HOME/config.yaml

# Write env vars from Railway secrets
cat > $HERMES_HOME/.env << EOF
DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
EOF

echo ""
echo "  Telegram: ${TELEGRAM_BOT_TOKEN:+✓} ${TELEGRAM_BOT_TOKEN:-✗ not set}"
echo "  DeepSeek: ${DEEPSEEK_API_KEY:+✓} ${DEEPSEEK_API_KEY:-✗ not set}"
echo "  Hermes:   $HERMES_HOME"
echo ""

# Bootstrap non-Python deps (node, browser, etc) — non-fatal
echo "→ Running postinstall (optional deps)..."
hermes postinstall 2>&1 || echo "  (postinstall non-fatal, continuing)"

echo ""
echo "→ Starting gateway..."
echo ""

# Start Hermes gateway in foreground
exec hermes gateway run --config $HERMES_HOME/config.yaml
