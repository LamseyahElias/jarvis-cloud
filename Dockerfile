FROM python:3.11-slim

WORKDIR /app

# Install system deps
RUN apt-get update && apt-get install -y \
    git \
    curl \
    openssh-client \
    build-essential \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Clone Hermes Agent
RUN git clone https://github.com/NousResearch/Hermes-Agent.git /app/hermes-agent
WORKDIR /app

# API keys (build-time injection)
ARG TELEGRAM_BOT_TOKEN
ARG DEEPSEEK_API_KEY

ENV TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
ENV DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
/hermes-agent

# Install Python deps
RUN python3 -m venv .venv && \
    . .venv/bin/activate && \
    pip install --upgrade pip && \
    pip install -e . && \
    pip install pyyaml

# Install Node deps (for browser tools)
RUN npm install --ignore-scripts

# Create hermes home directory
ENV HERMES_HOME=/app/hermes-home
RUN mkdir -p $HERMES_HOME

# Copy config
COPY config.yaml $HERMES_HOME/config.yaml

# Copy entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Create skills directory for JARVIS
RUN mkdir -p $HERMES_HOME/skills

# Expose API port (for tunnel + webhooks)
EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]
