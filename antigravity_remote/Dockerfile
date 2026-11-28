FROM debian:bookworm-slim

USER root

# Install dependencies (curl, jq, tini, git, Node.js/npm for optional stdio MCP servers)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    nodejs \
    npm \
    tini \
    ttyd \
    && rm -rf /var/lib/apt/lists/*

# Install Google Antigravity CLI (agy)
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash \
    && ln -sf /root/.local/bin/agy /usr/local/bin/agy

ENV PATH="/root/.local/bin:/usr/local/bin:${PATH}"

COPY start.sh /app/start.sh
COPY web-terminal.sh /app/web-terminal.sh
RUN chmod +x /app/start.sh /app/web-terminal.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/app/start.sh"]
