#!/bin/bash
set -e

echo "Starting Joplin Server Add-on Setup..."

# Ensure data directories exist
PGDATA="/data/postgres"
mkdir -p "$PGDATA"

# Find postgres user name (usually 'postgres')
PGUSER_NAME=$(getent passwd postgres | cut -d: -f1)
if [ -z "$PGUSER_NAME" ]; then
    echo "Creating postgres user..."
    addgroup -S postgres || true
    adduser -S -G postgres postgres || true
    PGUSER_NAME="postgres"
fi

chown -R "$PGUSER_NAME":"$PGUSER_NAME" "$PGDATA"
chmod 700 "$PGDATA"

# Find postgres binaries
PGBIN=$(find /usr/lib/postgresql -name initdb | head -n 1 | xargs dirname)
if [ -z "$PGBIN" ]; then
    echo "Error: PostgreSQL binaries not found"
    exit 1
fi
export PATH="$PATH:$PGBIN"

# 1. Initialize PostgreSQL if not already done
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "Initializing new database in $PGDATA..."
    su - "$PGUSER_NAME" -s /bin/bash -c "$PGBIN/initdb -D $PGDATA"
    
    # Allow local connections
    echo "host all all 127.0.0.1/32 trust" >> "$PGDATA/pg_hba.conf"
    echo "host all all ::1/128 trust" >> "$PGDATA/pg_hba.conf"
fi

# 2. Start PostgreSQL
echo "Starting PostgreSQL..."
su - "$PGUSER_NAME" -s /bin/bash -c "$PGBIN/pg_ctl start -D $PGDATA -l $PGDATA/log"

# Wait for Postgres to be ready
echo "Waiting for PostgreSQL to start..."
MAX_TRIES=30
TRIES=0
until pg_isready -h localhost -p 5432 || [ $TRIES -eq $MAX_TRIES ]; do
  sleep 1
  TRIES=$((TRIES + 1))
done

if [ $TRIES -eq $MAX_TRIES ]; then
    echo "Error: PostgreSQL failed to start"
    cat "$PGDATA/log" || true
    exit 1
fi

# 3. Create Joplin Database and User if they don't exist
echo "Setting up Joplin database..."
psql -h localhost -U "$PGUSER_NAME" -d postgres <<EOF
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'joplin') THEN
        CREATE ROLE joplin WITH LOGIN PASSWORD 'joplin';
    END IF;
END
\$\$;

SELECT 'CREATE DATABASE joplin OWNER joplin'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'joplin')\gexec
EOF

# 4. Read configuration from Home Assistant options
if [ -f /data/options.json ]; then
    export APP_BASE_URL=$(jq -r '.APP_BASE_URL // empty' /data/options.json)
    export ADMIN_EMAIL=$(jq -r '.AdminEmail // "admin@localhost"' /data/options.json)
    export MAILER_ENABLED=$(jq -r '.MailerEnabled // false' /data/options.json)
    export MAILER_HOST=$(jq -r '.MailerHost // empty' /data/options.json)
    export MAILER_PORT=$(jq -r '.MailerPort // 587' /data/options.json)
    export MAILER_USER=$(jq -r '.MailerUser // empty' /data/options.json)
    export MAILER_PASSWORD=$(jq -r '.MailerPassword // empty' /data/options.json)
    export MAILER_FROM=$(jq -r '.MailerFrom // empty' /data/options.json)
    export MAILER_SECURITY=$(jq -r '.MailerSecurity // "starttls"' /data/options.json)
fi

if [ -z "$APP_BASE_URL" ]; then
    echo "Warning: APP_BASE_URL not set, using default"
    export APP_BASE_URL="http://localhost:22300"
fi

echo "Joplin Configured:"
echo "APP_BASE_URL: $APP_BASE_URL"
echo "Admin Email: $ADMIN_EMAIL"
echo "Mailer Enabled: $MAILER_ENABLED"

# Update Admin Email in database in background (since tables are created on start)
if [ "$ADMIN_EMAIL" != "admin@localhost" ]; then
    (
        echo "Background: Waiting for Joplin to initialize tables..."
        # Wait up to 5 minutes for the table to exist
        for i in {1..60}; do
            if psql -h 127.0.0.1 -U "$PGUSER_NAME" -d joplin -c "SELECT 1 FROM users LIMIT 1;" >/dev/null 2>&1; then
                echo "Background: Table 'users' found, updating admin email..."
                psql -h 127.0.0.1 -U "$PGUSER_NAME" -d joplin -c "UPDATE users SET email = '$ADMIN_EMAIL' WHERE id = 'user_1' OR email = 'admin@localhost';"
                echo "Background: Admin email updated to $ADMIN_EMAIL"
                break
            fi
            sleep 5
        done
    ) &
fi

# 5. Start Joplin Server
echo "Starting Joplin Server..."

# Determine the app directory
if [ -d "/home/joplin/packages/server" ]; then
    JOPLIN_DIR="/home/joplin/packages/server"
else
    # Improved find to avoid signal 13
    JOPLIN_DIR=$(find /home -name "package.json" -path "*/packages/server/*" | head -n 1)
    JOPLIN_DIR=$(dirname "$JOPLIN_DIR")
fi

if [ -z "$JOPLIN_DIR" ] || [ ! -d "$JOPLIN_DIR" ]; then
    echo "Error: Joplin Server directory not found"
    exit 1
fi

cd "$JOPLIN_DIR"
echo "Working directory: $(pwd)"

# --- THE FIXES ---

# 1. Hostname Mapping: If the app insists on 'host.docker.internal', we make it point to local
echo "Mapping host.docker.internal to 127.0.0.1 in /etc/hosts..."
echo "127.0.0.1 host.docker.internal" >> /etc/hosts || echo "Warning: Could not update /etc/hosts"

# 2. Clean up ALL potential .env files that might be shadowing our variables
echo "Cleaning up potential .env files in /home/joplin..."
find /home/joplin -name ".env" -delete || true

# 3. Set a clean .env with both POSTGRES_ and DB_ prefixes
cat <<EOF > .env
DB_CLIENT=pg
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_USER=joplin
POSTGRES_PASSWORD=joplin
POSTGRES_DATABASE=joplin
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=joplin
DB_PASS=joplin
DB_NAME=joplin
PGHOST=127.0.0.1
PGPORT=5432
PGUSER=joplin
PGPASSWORD=joplin
PGDATABASE=joplin

# Mailer settings
MAILER_ENABLED=$MAILER_ENABLED
MAILER_HOST=$MAILER_HOST
MAILER_PORT=$MAILER_PORT
MAILER_USER=$MAILER_USER
MAILER_PASSWORD=$MAILER_PASSWORD
MAILER_NOREPLY_NAME="Joplin Server"
MAILER_NOREPLY_EMAIL=$MAILER_FROM
MAILER_SECURITY=$MAILER_SECURITY

# App settings
APP_PORT=22300
APP_BASE_URL=$APP_BASE_URL
NODE_ENV=production
RUNNING_IN_DOCKER=1
USER_VERIFICATION_ENABLED=false
EOF

# 4. Export them for the current shell
export $(grep -v '^#' .env | xargs)

echo "Launch variables check (Node Process):"
node -e 'console.log("POSTGRES_HOST in Node:", process.env.POSTGRES_HOST); console.log("DB_HOST in Node:", process.env.DB_HOST)'

# 5. Start the app
echo "----------------------------------------------------------"
echo "DEBUG: Letzter Passwort-Reset-Link aus der Datenbank:"
psql -h 127.0.0.1 -U "$PGUSER_NAME" -d joplin -c "SELECT body FROM emails ORDER BY created_time DESC LIMIT 1;" || echo "Kein Link in der Datenbank gefunden."
echo "----------------------------------------------------------"

echo "Executing: node dist/app.js"
exec node dist/app.js
