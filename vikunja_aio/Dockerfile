
# --------------------------------------------------------------------------
# Multi-stage build (most reliable way):
# --------------------------------------------------------------------------
ARG BUILD_FROM
ARG VIKUNJA_VERSION=1.0.0

# 1. Pull the official Vikunja image
FROM vikunja/vikunja:${VIKUNJA_VERSION} AS source

# 2. Build our Add-on image
FROM alpine:latest

# Install dependencies
RUN apk add --no-cache bash sqlite ca-certificates tzdata gcompat jq curl

WORKDIR /app/vikunja

# Only copy what we KNOW is safe and exists (the binary)
COPY --from=source /app/vikunja/vikunja ./vikunja

# Create data directories
RUN mkdir -p /data/vikunja /data/files && \
    chmod -R 777 /data/vikunja /data/files

COPY start.sh /start.sh
RUN chmod a+x /start.sh

CMD [ "/start.sh" ]
