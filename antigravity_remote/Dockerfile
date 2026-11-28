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
    && rm -rf /var/lib/apt/lists/*

# Install ttyd (static binary for x86_64 / aarch64; not in Debian bookworm apt)
RUN curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.$(uname -m)" -o /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# Install Google Antigravity CLI (agy)
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash \
    && ln -sf /root/.local/bin/agy /usr/local/bin/agy

ENV PATH="/root/.local/bin:/usr/local/bin:${PATH}"

COPY start.sh /app/start.sh
COPY web-terminal.sh /app/web-terminal.sh
RUN chmod +x /app/start.sh /app/web-terminal.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/app/start.sh"]
