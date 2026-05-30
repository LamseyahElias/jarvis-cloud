#!/bin/bash
set -eo pipefail

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

# Copy config and inject real token using Python (safe with any special chars)
cp /app/config.yaml $HERMES_HOME/config.yaml

if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
  echo "ERROR: TELEGRAM_BOT_TOKEN is not set!"
  echo "Add it as a Railway environment variable in the Variables tab."
  exit 1
fi

python3 -c "
import re
with open('$HERMES_HOME/config.yaml', 'r') as f:
    content = f.read()
content = content.replace('\${TELEGRAM_BOT_TOKEN}', '$TELEGRAM_BOT_TOKEN')
with open('$HERMES_HOME/config.yaml', 'w') as f:
    f.write(content)
print('Token injected successfully')
"

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
