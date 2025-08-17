FROM postgres:16-alpine

# Install additional tools for migration
RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-psycopg2 \
    postgresql-contrib

# Create directory for initialization scripts
RUN mkdir -p /docker-entrypoint-initdb.d

# Copy any initialization scripts (will be added later)
# COPY init-scripts/* /docker-entrypoint-initdb.d/

# Set proper permissions
RUN chmod -R 755 /docker-entrypoint-initdb.d

EXPOSE 5432