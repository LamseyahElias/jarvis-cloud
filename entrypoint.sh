#!/bin/bash
set -e

echo "================================================"
echo "  JARVIS — Cloud Deployment"
echo "  Starting Hermes Agent Gateway..."
echo "================================================"

export HERMES_HOME="${HERMES_HOME:-/app/hermes-home}"
mkdir -p $HERMES_HOME

# Write env vars (DeepSeek reads from .env)
cat > $HERMES_HOME/.env << EOF
DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
EOF

# Copy and inject real tokens into config.yaml
cp /app/config.yaml $HERMES_HOME/config.yaml

# Replace placeholder with real token (sed works on Linux/Railway containers)
sed -i "s/\${TELEGRAM_BOT_TOKEN}/${TELEGRAM_BOT_TOKEN}/g" $HERMES_HOME/config.yaml

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
