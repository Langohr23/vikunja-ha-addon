FROM node:22-bookworm-slim

USER root

# Install Python, jq, curl, tini, and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    jq \
    python3 \
    python3-pip \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Install ttyd (static binary for x86_64 / aarch64)
RUN curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.$(uname -m)" -o /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# Install supergateway (MCP stdio -> Streamable HTTP bridge) and outlook-mcp
RUN npm install -g supergateway \
    && pip3 install --no-cache-dir --break-system-packages outlook-mcp

COPY start.sh /app/start.sh
COPY web-terminal.sh /app/web-terminal.sh
RUN chmod +x /app/start.sh /app/web-terminal.sh

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--", "/app/start.sh"]
