# Simple Blog System Migration Notes

## Overview
This dataset demonstrates the migration of a basic blog system from PostgreSQL to MariaDB. It's designed as a beginner-friendly introduction to PostgreSQL → MariaDB migration concepts while showcasing MariaDB's unique advantages.

## Key Learning Objectives
- Understanding basic data type mappings
- Converting PostgreSQL SERIAL to MariaDB AUTO_INCREMENT
- Handling JSON data migration (JSONB → JSON)
- Converting PostgreSQL functions and triggers to MariaDB equivalents
- Implementing MariaDB-specific optimizations

## PostgreSQL Features Used
- **SERIAL/BIGSERIAL**: Auto-incrementing primary keys
- **UUID**: Universally unique identifiers with uuid-ossp extension
- **JSONB**: Binary JSON storage with indexing
- **TIMESTAMP WITH TIME ZONE**: Time zone aware timestamps
- **TEXT[]**: Array data type for keywords
- **INET**: IP address data type
- **tsvector**: Full-text search vectors
- **Materialized Views**: Cached query results
- **PL/pgSQL**: Stored procedures and functions
- **Triggers**: Automatic data maintenance
- **GIN Indexes**: Generalized inverted indexes for JSON/arrays

## MariaDB Migration Strategies

### 1. Data Type Conversions

| PostgreSQL | MariaDB | Notes |
|------------|---------|--------|
| `SERIAL` | `INT AUTO_INCREMENT` | Basic auto-increment |
| `BIGSERIAL` | `BIGINT AUTO_INCREMENT` | For larger ranges |
| `UUID` | `CHAR(36)` or `BINARY(16)` | Store as string or binary |
| `JSONB` | `JSON` | MariaDB JSON type with validation |
| `TEXT[]` | `JSON` | Store arrays as JSON arrays |
| `INET` | `VARCHAR(45)` | Support IPv4 and IPv6 |
| `TIMESTAMP WITH TIME ZONE` | `DATETIME` | Convert to UTC |
| `tsvector` | `FULLTEXT` indexes | MariaDB's text search |

### 2. Advanced MariaDB Features Utilized

#### Virtual and Persistent Columns
```sql
-- Extract JSON data as virtual columns for faster queries
interests JSON AS (JSON_EXTRACT(metadata, '$.interests')) VIRTUAL,
-- Pre-calculate expensive operations
search_name VARCHAR(200) AS (CONCAT(username, ' ', COALESCE(full_name, ''))) PERSISTENT
```

#### Storage Engine Selection
- **InnoDB**: Default for ACID compliance and foreign keys
- **ColumnStore**: For analytics tables (post_analytics)
- **Partitioning**: For large audit tables

#### MariaDB-Specific Optimizations
```sql
-- Microsecond precision
created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6)

-- Table compression
COMPRESSION='zlib'

-- Hash indexes for exact lookups
INDEX idx_slug_hash (slug) USING HASH

-- Invisible indexes for future optimization
INDEX idx_last_login (last_login) INVISIBLE
```

### 3. Function and Trigger Migration

#### PostgreSQL Function
```sql
CREATE OR REPLACE FUNCTION update_post_search_vector() RETURNS trigger AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.excerpt, '')), 'B');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

#### MariaDB Equivalent
```sql
-- Use FULLTEXT indexes instead of tsvector
FULLTEXT ft_post_search (title, excerpt, content)

-- Trigger for maintaining derived data
DELIMITER //
CREATE TRIGGER update_tag_usage_after_insert
AFTER INSERT ON post_tags
FOR EACH ROW
BEGIN
    UPDATE tags SET usage_count = usage_count + 1 WHERE id = NEW.tag_id;
END//
DELIMITER ;
```

### 4. Performance Optimizations

#### Query Cache (MariaDB Advantage)
Unlike PostgreSQL, MariaDB still supports query cache:
```sql
query_cache_type = 1
query_cache_size = 128M
```

#### Thread Pool
MariaDB's thread pool handles many connections efficiently:
```sql
thread_handling = pool-of-threads
thread_pool_size = 16
```

#### Computed Columns for Faster Queries
```sql
is_published BOOLEAN AS (status = 'published') PERSISTENT,
word_count INT AS (CHAR_LENGTH(content) - CHAR_LENGTH(REPLACE(content, ' ', '')) + 1) PERSISTENT
```

## Migration Steps

### 1. Schema Migration
1. Convert data types according to mapping table
2. Replace PostgreSQL-specific syntax
3. Implement MariaDB optimizations
4. Add virtual/persistent columns where beneficial

### 2. Data Migration Options

#### Option A: pg_dump → Custom Script
```bash
# Export from PostgreSQL
pg_dump -U postgres -h localhost migration_db > postgres_dump.sql

# Use custom Python script to convert data
python3 pg_to_mariadb_converter.py postgres_dump.sql > mariadb_data.sql

# Import to MariaDB
mysql -u root -p migration_db < mariadb_data.sql
```

#### Option B: CONNECT Storage Engine
```sql
-- Create CONNECT table pointing to PostgreSQL
CREATE TABLE pg_users (
    id INT,
    username VARCHAR(50),
    email VARCHAR(100)
) ENGINE=CONNECT 
TABLE_TYPE=ODBC
CONNECTION='DSN=PostgreSQL;UID=postgres;PWD=password'
SRCDEF='SELECT id, username, email FROM users';

-- Copy data to InnoDB table
INSERT INTO users (id, username, email)
SELECT id, username, email FROM pg_users;
```

#### Option C: pgloader
```bash
# Install pgloader
# Configure connection strings
pgloader postgresql://user:pass@pghost/dbname mysql://user:pass@myhost/dbname
```

### 3. Application Code Updates
- Update connection strings
- Modify queries for MariaDB syntax differences
- Update full-text search queries
- Handle JSON operations differently

## Testing Strategy

### 1. Data Integrity Verification
```sql
-- Row counts
SELECT 'PostgreSQL' as source, COUNT(*) FROM pg_users UNION
SELECT 'MariaDB' as source, COUNT(*) FROM users;

-- Checksums for critical data
SELECT MD5(GROUP_CONCAT(username ORDER BY id)) FROM users;
```

### 2. Performance Comparison
```sql
-- Query performance tests
EXPLAIN SELECT * FROM posts WHERE MATCH(title, content) AGAINST('database migration');

-- Index usage verification
SHOW INDEX FROM posts;
```

### 3. Functional Testing
- Test all CRUD operations
- Verify trigger functionality
- Test stored procedures
- Validate JSON operations

## Common Pitfalls and Solutions

### 1. UUID Handling
**Problem**: PostgreSQL UUID extension not available
**Solution**: Use MariaDB's built-in UUID() function or CHAR(36) storage

### 2. Array Data Types
**Problem**: PostgreSQL arrays don't exist in MariaDB
**Solution**: Convert to JSON arrays or normalize into separate tables

### 3. Full-Text Search
**Problem**: PostgreSQL tsvector vs MariaDB FULLTEXT
**Solution**: Recreate search functionality using MariaDB FULLTEXT indexes

### 4. Time Zone Handling
**Problem**: TIMESTAMP WITH TIME ZONE conversion
**Solution**: Convert to UTC and handle time zones in application layer

## Performance Benefits of MariaDB

### 1. Query Cache
- Caches SELECT query results
- Improves performance for read-heavy workloads
- Not available in PostgreSQL

### 2. Thread Pool
- Better handling of many connections
- Reduces context switching overhead
- More efficient than PostgreSQL's process model

### 3. Multiple Storage Engines
- InnoDB for transactions
- ColumnStore for analytics
- MEMORY for temporary data
- MyISAM for read-only data

### 4. Galera Cluster
- Synchronous multi-master replication
- Automatic node provisioning
- Built-in load balancing

## Next Steps
1. Run the migration scripts
2. Test performance characteristics
3. Implement monitoring
4. Plan for production migration
5. Move to more complex datasets (E-Commerce Platform)

## Exercises
1. Convert the PostgreSQL schema manually
2. Write a data migration script
3. Performance test both databases
4. Implement MariaDB-specific optimizations
5. Set up basic replication