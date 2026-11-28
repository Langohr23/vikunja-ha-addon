FROM node:22-alpine

USER root

# Install minimal dependencies (ttyd directly from Alpine repo)
RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    jq \
    tini \
    ttyd

# Install supergateway (MCP stdio -> Streamable HTTP bridge) and @codefuturist/email-mcp
RUN npm install -g supergateway @codefuturist/email-mcp

COPY start.sh /app/start.sh
COPY web-terminal.sh /app/web-terminal.sh
RUN chmod +x /app/start.sh /app/web-terminal.sh

EXPOSE 8081

ENTRYPOINT ["/sbin/tini", "--", "/app/start.sh"]
