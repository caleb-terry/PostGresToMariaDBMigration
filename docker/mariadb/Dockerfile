FROM mariadb:11.2

# Install additional tools AFTER database initialization
# We'll install plugins manually via SQL commands once the database is up
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-mysqldb \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create directory for initialization scripts
RUN mkdir -p /docker-entrypoint-initdb.d

# Copy initialization script to install plugins after database is ready
COPY init-complete.sql /docker-entrypoint-initdb.d/99-init-complete.sql

# Set proper permissions
RUN chmod -R 755 /docker-entrypoint-initdb.d

EXPOSE 3306