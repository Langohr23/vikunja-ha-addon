FROM python:3.12-slim

USER root

# Install minimal runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    jq \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Install ttyd (static binary for x86_64 / aarch64)
RUN curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.$(uname -m)" -o /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# Install mcp-proxy (Python Streamable HTTP/SSE bridge) and outlook-mcp (no Node.js needed)
RUN pip3 install --no-cache-dir mcp-proxy outlook-mcp

COPY start.sh /app/start.sh
COPY web-terminal.sh /app/web-terminal.sh
RUN chmod +x /app/start.sh /app/web-terminal.sh

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--", "/app/start.sh"]
