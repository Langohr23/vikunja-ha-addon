FROM alpine:latest

USER root

# Install dependencies (gcompat/libstdc++ for glibc compatibility, ttyd from Alpine repo)
RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    gcompat \
    jq \
    libgcc \
    libstdc++ \
    tini \
    ttyd

# Install Google Antigravity CLI (agy)
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash \
    && ln -sf /root/.local/bin/agy /usr/local/bin/agy

ENV PATH="/root/.local/bin:/usr/local/bin:${PATH}"

COPY start.sh /app/start.sh
COPY web-terminal.sh /app/web-terminal.sh
RUN chmod +x /app/start.sh /app/web-terminal.sh

ENTRYPOINT ["/sbin/tini", "--", "/app/start.sh"]
