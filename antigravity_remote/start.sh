#!/bin/bash
set -e

echo "Starting Antigravity Remote Add-on..."

OPTIONS_FILE="/data/options.json"
PERSIST_DIR="/data/.gemini"
CONFIG_DIR="${PERSIST_DIR}/config"
CLI_DIR="${PERSIST_DIR}/antigravity-cli"
MCP_CONFIG_FILE="${CONFIG_DIR}/mcp_config.json"

# Ensure persistent Antigravity / Gemini directory survives container restarts
mkdir -p "$CONFIG_DIR" "$CLI_DIR"
if [ -d /root/.gemini ] && [ ! -L /root/.gemini ]; then
    cp -rn /root/.gemini/. "$PERSIST_DIR/" 2>/dev/null || true
    rm -rf /root/.gemini
fi
ln -sfn "$PERSIST_DIR" /root/.gemini

# Defaults
INSTANCE_NAME="Home Assistant"
API_KEY=""
WORKSPACE_DIR="/data/workspace"
MCP_CONFIG_RAW=""

if [ -f "$OPTIONS_FILE" ]; then
    INSTANCE_NAME=$(jq -r '.instance_name // "Home Assistant"' "$OPTIONS_FILE")
    API_KEY=$(jq -r '.api_key // empty' "$OPTIONS_FILE")
    WORKSPACE_DIR=$(jq -r '.workspace_dir // "/data/workspace"' "$OPTIONS_FILE")
    MCP_CONFIG_RAW=$(jq -r '.mcp_config_json // empty' "$OPTIONS_FILE")

    # Apply custom environment variables
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

if [ -n "$API_KEY" ]; then
    export ANTIGRAVITY_API_KEY="$API_KEY"
    echo "ANTIGRAVITY_API_KEY configured from add-on options."
fi

# Build mcp_config.json
TMP_MCP=$(mktemp)
if [ -n "$MCP_CONFIG_RAW" ]; then
    if echo "$MCP_CONFIG_RAW" | jq -e '.mcpServers' >/dev/null 2>&1; then
        echo "$MCP_CONFIG_RAW" | jq '.' > "$TMP_MCP"
    else
        echo "Error: mcp_config_json must be valid JSON containing a top-level \"mcpServers\" object."
        rm -f "$TMP_MCP"
        exit 1
    fi
else
    echo '{"mcpServers": {}}' > "$TMP_MCP"
fi

if [ -f "$OPTIONS_FILE" ]; then
    SERVER_COUNT=$(jq -r '.mcp_servers // [] | length' "$OPTIONS_FILE" 2>/dev/null || echo 0)
    for ((i=0; i<SERVER_COUNT; i++)); do
        S_NAME=$(jq -r ".mcp_servers[$i].name // empty" "$OPTIONS_FILE")
        S_URL=$(jq -r ".mcp_servers[$i].server_url // empty" "$OPTIONS_FILE")
        S_AUTH=$(jq -r ".mcp_servers[$i].auth_header // empty" "$OPTIONS_FILE")
        S_CMD=$(jq -r ".mcp_servers[$i].command // empty" "$OPTIONS_FILE")
        S_ARGS=$(jq -r ".mcp_servers[$i].args // empty" "$OPTIONS_FILE")

        if [ -z "$S_NAME" ]; then
            continue
        fi

        if [ -n "$S_URL" ]; then
            if [ -n "$S_AUTH" ]; then
                jq --arg name "$S_NAME" --arg url "$S_URL" --arg auth "$S_AUTH" \
                    '.mcpServers[$name] = {"serverUrl": $url, "headers": {"Authorization": $auth}}' \
                    "$TMP_MCP" > "${TMP_MCP}.next" && mv "${TMP_MCP}.next" "$TMP_MCP"
            else
                jq --arg name "$S_NAME" --arg url "$S_URL" \
                    '.mcpServers[$name] = {"serverUrl": $url}' \
                    "$TMP_MCP" > "${TMP_MCP}.next" && mv "${TMP_MCP}.next" "$TMP_MCP"
            fi
        elif [ -n "$S_CMD" ]; then
            jq --arg name "$S_NAME" --arg cmd "$S_CMD" --arg args "$S_ARGS" \
                '.mcpServers[$name] = {"command": $cmd, "args": ($args | split(" ") | map(select(length > 0)))}' \
                "$TMP_MCP" > "${TMP_MCP}.next" && mv "${TMP_MCP}.next" "$TMP_MCP"
        else
            echo "Warning: MCP server '$S_NAME' has neither server_url nor command; skipping."
        fi
    done
fi

mv "$TMP_MCP" "$MCP_CONFIG_FILE"
chmod 600 "$MCP_CONFIG_FILE"

CONFIGURED_SERVERS=$(jq -r '.mcpServers | keys | join(", ")' "$MCP_CONFIG_FILE")
echo "Configured MCP servers: ${CONFIGURED_SERVERS:-none}"

mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"
echo "Workspace directory: $(pwd)"

# Start Ingress Web Terminal (ttyd) for interactive OAuth login and diagnostics
echo "Starting Ingress Web Terminal on port 8099..."
ttyd -W -p 8099 /app/web-terminal.sh &
TTYD_PID=$!

cleanup() {
    echo "Stopping Antigravity Remote Control and Web Terminal..."
    agy remote-control stop >/dev/null 2>&1 || true
    kill "$TTYD_PID" >/dev/null 2>&1 || true
    exit 0
}
trap cleanup SIGTERM SIGINT

# Start and monitor Remote Control without crash-looping if login is still pending
NOTIFIED_LOGIN=0
while true; do
    STATUS_OUT=$(agy remote-control status 2>&1 || true)
    if echo "$STATUS_OUT" | grep -qiE "Daemon status:\s*(active|running)"; then
        NOTIFIED_LOGIN=0
        sleep 30 &
        wait $!
    else
        echo "Starting Antigravity Remote Control (instance: $INSTANCE_NAME)..."
        if agy remote-control start --name "$INSTANCE_NAME"; then
            echo "Antigravity Remote Control is running."
            NOTIFIED_LOGIN=0
            sleep 30 &
            wait $!
        else
            if [ "$NOTIFIED_LOGIN" -eq 0 ]; then
                echo "Remote Control could not start yet (most likely waiting for Google login)."
                echo "Open the Add-on Web UI in Home Assistant and run: agy"
                NOTIFIED_LOGIN=1
            fi
            sleep 15 &
            wait $!
        fi
    fi
done
