FROM mariadb:11.2

# Install additional tools and storage engines
RUN apt-get update && apt-get install -y \
    mariadb-plugin-connect \
    mariadb-plugin-spider \
    mariadb-plugin-columnstore \
    mariadb-plugin-mroonga \
    python3 \
    python3-pip \
    python3-mysqldb \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create directory for initialization scripts
RUN mkdir -p /docker-entrypoint-initdb.d

# Copy any initialization scripts (will be added later)
# COPY init-scripts/* /docker-entrypoint-initdb.d/

# Set proper permissions
RUN chmod -R 755 /docker-entrypoint-initdb.d

EXPOSE 3306