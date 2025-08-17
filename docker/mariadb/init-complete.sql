-- This script runs after MariaDB is initialized
-- Create the migration database if it doesn't exist
CREATE DATABASE IF NOT EXISTS migration_db;

-- Grant privileges to the mariadb user
GRANT ALL PRIVILEGES ON migration_db.* TO 'mariadb'@'%';
GRANT REPLICATION SLAVE ON *.* TO 'mariadb'@'%';

-- Create replication user for replicas
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'repl123';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';

-- Flush privileges
FLUSH PRIVILEGES;

-- Note: Additional plugins can be installed here later if needed
-- Currently avoiding SPIDER and ColumnStore as they require additional configuration