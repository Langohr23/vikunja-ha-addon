#!/bin/bash
set -e

echo "Starting Outlook.com MCP Server Add-on..."

OPTIONS_FILE="/data/options.json"
PERSIST_SHARE="/data/local_share"
PERSIST_CONFIG="/data/config"
PERSIST_CACHE="/data/cache"

mkdir -p "$PERSIST_SHARE" "$PERSIST_CONFIG" "$PERSIST_CACHE" /root/.local

# Persist token/cache/config directories across container restarts
for target_pair in \
    "/root/.local/share:$PERSIST_SHARE" \
    "/root/.config:$PERSIST_CONFIG" \
    "/root/.cache:$PERSIST_CACHE"
do
    SRC="${target_pair%%:*}"
    DST="${target_pair##*:}"
    if [ -d "$SRC" ] && [ ! -L "$SRC" ]; then
        cp -r "$SRC/." "$DST/" 2>/dev/null || true
        rm -rf "$SRC"
    fi
    ln -sfn "$DST" "$SRC"
done

OUTLOOK_CLIENT_ID=""
if [ -f "$OPTIONS_FILE" ]; then
    OUTLOOK_CLIENT_ID=$(jq -r '.outlook_client_id // empty' "$OPTIONS_FILE")

    ENV_COUNT=$(jq -r '.env_vars // [] | length' "$OPTIONS_FILE" 2>/dev/null || echo 0)
    if [ "$ENV_COUNT" -gt 0 ]; then
        echo "Applying $ENV_COUNT custom environment variable(s) from options..."
        for ((i=0; i<ENV_COUNT; i++)); do
            VAR_NAME=$(jq -r ".env_vars[$i].name // empty" "$OPTIONS_FILE")
            VAR_VALUE=$(jq -r ".env_vars[$i].value // \"\"" "$OPTIONS_FILE")
            if [ -n "$VAR_NAME" ]; then
                export "${VAR_NAME}=${VAR_VALUE}"
                echo "Custom env set: $VAR_NAME"
            fi
        done
    fi
fi

if [ -n "$OUTLOOK_CLIENT_ID" ]; then
    export OUTLOOK_CLIENT_ID
    echo "OUTLOOK_CLIENT_ID configured."
elif [ -z "${OUTLOOK_CLIENT_ID:-}" ]; then
    echo "Warning: outlook_client_id is not set in add-on options!"
fi

# Start Ingress Web Terminal on port 8099
echo "Starting Ingress Web Terminal on port 8099..."
ttyd -W -p 8099 /app/web-terminal.sh &
TTYD_PID=$!

cleanup() {
    echo "Stopping Outlook.com MCP Server..."
    kill "$TTYD_PID" >/dev/null 2>&1 || true
    exit 0
}
trap cleanup SIGTERM SIGINT

echo "Starting supergateway (Streamable HTTP) on port 8080 -> /mcp..."
exec supergateway --port 8080 --outputTransport streamableHttp --stdio "outlook-mcp"
