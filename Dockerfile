FROM python:3.11-slim

WORKDIR /app

# Install system deps for Hermes runtime
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Hermes Agent from PyPI
RUN pip install --no-cache-dir hermes-agent pyyaml

# Configure Hermes
ENV HERMES_HOME=/app/hermes-home
RUN mkdir -p $HERMES_HOME $HERMES_HOME/skills $HERMES_HOME/sessions

COPY config.yaml $HERMES_HOME/config.yaml
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]
