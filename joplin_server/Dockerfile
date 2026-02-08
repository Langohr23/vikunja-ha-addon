ARG JOPLIN_VERSION=3.5.2
FROM joplin/server:${JOPLIN_VERSION}

USER root

# Install PostgreSQL and other dependencies (Debian/Ubuntu based)
RUN apt-get update && apt-get install -y \
    postgresql \
    postgresql-contrib \
    jq \
    curl \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Add startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Environment variables for Joplin
ENV APP_PORT=22300
ENV DB_CLIENT=pg
ENV POSTGRES_PORT=5432
ENV POSTGRES_HOST=127.0.0.1
ENV DB_HOST=127.0.0.1
ENV POSTGRES_USER=joplin
ENV POSTGRES_PASSWORD=joplin
ENV POSTGRES_DATABASE=joplin

# Standard PostgreSQL env vars (used by many Node drivers as fallback)
ENV PGHOST=127.0.0.1
ENV PGPORT=5432
ENV PGUSER=joplin
ENV PGPASSWORD=joplin
ENV PGDATABASE=joplin

ENV NODE_ENV=production
ENV RUNNING_IN_DOCKER=1

EXPOSE 22300

ENTRYPOINT ["/usr/bin/tini", "--", "/app/start.sh"]