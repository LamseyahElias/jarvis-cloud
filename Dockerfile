FROM python:3.11-slim as base

# Install system deps
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone Hermes Agent (shallow, no browser tools needed in cloud)
RUN git clone --depth 1 https://github.com/NousResearch/Hermes-Agent.git /app/hermes-agent

WORKDIR /app/hermes-agent

# Install Python deps — no editable install, no extras
RUN python3 -m venv .venv && \
    . .venv/bin/activate && \
    pip install --upgrade pip setuptools wheel && \
    pip install -e . --no-cache-dir && \
    pip install pyyaml --no-cache-dir

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

# Expose API port
EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]
