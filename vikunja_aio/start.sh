#!/bin/bash
set -e

echo "Starting Vikunja Add-on Setup (Pure Bash)..."

# Ensure data directories exist
mkdir -p /data/vikunja
mkdir -p /data/files

# Get config options using jq (with fallback)
PUBLIC_URL=""
ENABLE_REGISTRATION="true"
if [ -f /data/options.json ]; then
    PUBLIC_URL=$(jq -r '.PublicURL // empty' /data/options.json)
    ENABLE_REGISTRATION=$(jq -r '.EnableRegistration // "true"' /data/options.json)
fi

if [ -z "$PUBLIC_URL" ]; then
    echo "Warning: PublicURL not found or empty, defaulting to localhost"
    PUBLIC_URL="http://localhost:3456"
fi

# Get timezone from Supervisor (optional, fallback to UTC)
TIMEZONE="UTC"
if [ -n "$SUPERVISOR_TOKEN" ]; then
    # Try to fetch timezone from Supervisor API
    # We use a short timeout to prevent hanging if supervisor is unreachable
    TZ_RESPONSE=$(curl -s -m 5 -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/info 2>/dev/null || true)
    FETCHED_TZ=$(echo "$TZ_RESPONSE" | jq -r '.data.timezone // empty')
    
    if [ -n "$FETCHED_TZ" ]; then
        TIMEZONE="$FETCHED_TZ"
    fi
fi

echo "Configuring Vikunja..."
echo "Public URL: $PUBLIC_URL"
echo "Timezone: $TIMEZONE"
echo "Registration Enabled: $ENABLE_REGISTRATION"

# Configure Vikunja via Environment Variables
export VIKUNJA_SERVICE_INTERFACE=":3456"
export VIKUNJA_SERVICE_PUBLICURL="$PUBLIC_URL"
export VIKUNJA_SERVICE_ROOTPATH="/app/vikunja/frontend"
export VIKUNJA_SERVICE_STATICPATH="/app/vikunja/frontend"
export VIKUNJA_SERVICE_ENABLEREGISTRATION="$ENABLE_REGISTRATION"
export VIKUNJA_SERVICE_ENABLEPUBLICLINKSHARE="true"
export VIKUNJA_SERVICE_ENABLETASKATTACHMENTS="true"
export VIKUNJA_SERVICE_TIMEZONE="$TIMEZONE"

export VIKUNJA_DATABASE_TYPE="sqlite"
export VIKUNJA_DATABASE_PATH="/data/vikunja.db"

export VIKUNJA_FILES_BASEPATH="/data/files"

export VIKUNJA_LOG_LEVEL="info"

echo "Starting Vikunja Binary..."
cd /app/vikunja

# Use exec to replace the shell process
exec ./vikunja
