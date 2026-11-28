#!/bin/bash
set -e

echo "Starting IMAP/SMTP Email MCP Server Add-on..."

OPTIONS_FILE="/data/options.json"
PERSIST_EMAIL_DIR="/data/email-mcp"
PERSIST_SHARE="/data/local_share"
CONFIG_FILE="${PERSIST_EMAIL_DIR}/config.toml"

mkdir -p "$PERSIST_EMAIL_DIR" "$PERSIST_SHARE" /root/.config /root/.local

# Persist email-mcp config and local share across container restarts
if [ -d /root/.config/email-mcp ] && [ ! -L /root/.config/email-mcp ]; then
    cp -r /root/.config/email-mcp/. "$PERSIST_EMAIL_DIR/" 2>/dev/null || true
    rm -rf /root/.config/email-mcp
fi
ln -sfn "$PERSIST_EMAIL_DIR" /root/.config/email-mcp

if [ -d /root/.local/share ] && [ ! -L /root/.local/share ]; then
    cp -r /root/.local/share/. "$PERSIST_SHARE/" 2>/dev/null || true
    rm -rf /root/.local/share
fi
ln -sfn "$PERSIST_SHARE" /root/.local/share

CONFIG_TOML_RAW=""
ENABLE_WEB_TERMINAL="true"
if [ -f "$OPTIONS_FILE" ]; then
    CONFIG_TOML_RAW=$(jq -r '.config_toml // empty' "$OPTIONS_FILE")
    ENABLE_WEB_TERMINAL=$(jq -r 'if .enable_web_terminal == false then "false" else "true" end' "$OPTIONS_FILE")

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

if [ -n "$CONFIG_TOML_RAW" ]; then
    printf '%s\n' "$CONFIG_TOML_RAW" > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    echo "Wrote config.toml from add-on options."
fi

TTYD_PID=""
if [ "$ENABLE_WEB_TERMINAL" = "true" ]; then
    echo "Starting Ingress Web Terminal on port 8099..."
    ttyd -W -p 8099 /app/web-terminal.sh &
    TTYD_PID=$!
else
    echo "Ingress Web Terminal disabled (enable_web_terminal: false)."
fi

cleanup() {
    echo "Stopping IMAP/SMTP Email MCP Server..."
    if [ -n "$TTYD_PID" ]; then
        kill "$TTYD_PID" >/dev/null 2>&1 || true
    fi
    exit 0
}
trap cleanup SIGTERM SIGINT

NOTIFIED=0
while [ ! -s "$CONFIG_FILE" ]; do
    if [ "$NOTIFIED" -eq 0 ]; then
        echo "No email-mcp configuration found at $CONFIG_FILE."
        echo "Open the Add-on Web UI in Home Assistant and run: email-mcp setup"
        NOTIFIED=1
    fi
    sleep 10 &
    wait $!
done

echo "Starting supergateway (Streamable HTTP) on port 8081 -> /mcp..."
exec supergateway --port 8081 --outputTransport streamableHttp --stdio "email-mcp"
