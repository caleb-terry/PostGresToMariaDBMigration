# E-Commerce Platform Migration Notes

## Overview
This dataset represents an intermediate to advanced PostgreSQL to MariaDB migration scenario featuring a complex e-commerce platform. It demonstrates enterprise-level challenges including high transaction volumes, complex relationships, and the need for high availability.

## Key Learning Objectives
- Advanced data type conversions (custom types, domains, arrays)
- Complex JSON/JSONB migration strategies
- Full-text search migration from PostgreSQL to MariaDB
- Stored procedure and function conversion (PL/pgSQL → SQL/PSM)
- High availability setup with Galera Cluster
- Performance optimization for e-commerce workloads
- MariaDB-specific storage engine utilization

## PostgreSQL Advanced Features Used

### Custom Types and Domains
```sql
CREATE TYPE order_status AS ENUM ('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded');
CREATE DOMAIN email_address AS TEXT CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
CREATE DOMAIN currency_amount AS NUMERIC(10,2) CHECK (VALUE >= 0);
```

### Advanced JSONB Usage
- Product specifications and features
- User preferences and settings
- Order address storage
- Dynamic product attributes
- Search analytics data

### Full-Text Search
- Weighted search vectors (A, B, C, D weights)
- GIN indexes for performance
- Trigram matching for fuzzy search
- Complex search procedures with ranking

### Advanced PostgreSQL Extensions
- **uuid-ossp**: UUID generation
- **pg_trgm**: Trigram matching for fuzzy search
- **btree_gin**: Combined B-tree and GIN indexes
- **hstore**: Key-value storage (alternative to JSON)

## MariaDB Migration Strategies

### 1. Data Type Conversions

| PostgreSQL | MariaDB | Migration Notes |
|------------|---------|-----------------|
| `ENUM` types | `ENUM` or `VARCHAR` | MariaDB supports ENUM natively |
| `DOMAIN` types | `CHECK` constraints | Use constraints for validation |
| `JSONB` | `JSON` | MariaDB JSON with virtual columns |
| `TEXT[]` | `JSON` arrays | Store arrays as JSON |
| `tsvector` | `FULLTEXT` indexes | Use MATCH/AGAINST syntax |
| `POINT` | `DECIMAL` pair | Store lat/lng separately |
| `INET` | `VARCHAR(45)` | Support IPv4/IPv6 |

### 2. Advanced MariaDB Features Utilized

#### Virtual and Persistent Columns
```sql
-- Extract JSON data for fast queries
email_offers BOOLEAN AS (JSON_EXTRACT(preferences, '$.email_offers')) VIRTUAL,
-- Pre-calculate expensive operations
current_price DECIMAL(12,2) AS (COALESCE(sale_price, base_price)) PERSISTENT,
-- Stock status computation
stock_status ENUM('in_stock', 'low_stock', 'out_of_stock') AS (
    CASE 
        WHEN stock_quantity = 0 THEN 'out_of_stock'
        WHEN stock_quantity <= min_stock_level THEN 'low_stock'
        ELSE 'in_stock'
    END
) PERSISTENT
```

#### Storage Engine Selection
- **InnoDB**: Primary tables with ACID compliance
- **ColumnStore**: Analytics queries (`search_queries` table)
- **Partitioning**: Time-based for `inventory_movements`, `price_history`

#### Full-Text Search Migration
```sql
-- PostgreSQL
CREATE INDEX idx_products_search_vector ON products USING GIN(search_vector);

-- MariaDB
FULLTEXT ft_product_search (name, short_description, description)

-- Query conversion
-- PostgreSQL: WHERE search_vector @@ plainto_tsquery('english', 'laptop')
-- MariaDB: WHERE MATCH(name, description) AGAINST('laptop' IN BOOLEAN MODE)
```

### 3. Galera Cluster Optimizations

#### Conflict-Safe Design
```sql
-- Use BIGINT for high-volume tables
id BIGINT AUTO_INCREMENT PRIMARY KEY,
-- Version columns for optimistic locking
version INT DEFAULT 0,
-- Node tracking for debugging
node_id TINYINT DEFAULT @@server_id,
-- Start auto-increment high to avoid conflicts
AUTO_INCREMENT=1000000
```

#### Distributed Locking
```sql
-- Custom distributed lock table
CREATE TABLE distributed_locks (
    lock_name VARCHAR(100) PRIMARY KEY,
    locked_by VARCHAR(100) NOT NULL,
    locked_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
    expires_at TIMESTAMP(6) NOT NULL,
    node_id TINYINT DEFAULT @@server_id
);
```

### 4. Complex Stored Procedure Migration

#### PostgreSQL Function
```sql
CREATE OR REPLACE FUNCTION search_products(
    p_query TEXT,
    p_category_id INTEGER DEFAULT NULL,
    ...
) RETURNS TABLE (
    product_id INTEGER,
    name VARCHAR,
    rank REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.name, ts_rank(p.search_vector, plainto_tsquery('english', p_query))
    FROM products p
    WHERE p.search_vector @@ plainto_tsquery('english', p_query);
END;
$$ LANGUAGE plpgsql;
```

#### MariaDB Equivalent
```sql
DELIMITER //
CREATE PROCEDURE search_products(
    IN p_query TEXT,
    IN p_category_id INT,
    ...
)
BEGIN
    SET @sql = 'SELECT p.id, p.name';
    
    IF p_query IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ', MATCH(p.name, p.description) AGAINST(? IN BOOLEAN MODE) as relevance');
    END IF;
    
    SET @sql = CONCAT(@sql, ' FROM products p WHERE p.status = ''active''');
    
    IF p_query IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND MATCH(p.name, p.description) AGAINST(? IN BOOLEAN MODE)');
    END IF;
    
    PREPARE stmt FROM @sql;
    EXECUTE stmt USING p_query, p_query;
    DEALLOCATE PREPARE stmt;
END//
DELIMITER ;
```

## Performance Optimizations

### 1. MariaDB Query Cache
```sql
# Enable query cache for read-heavy workloads
query_cache_type = 1
query_cache_size = 256M
query_cache_limit = 4M
```

### 2. Thread Pool Configuration
```sql
# Handle high connection counts efficiently
thread_handling = pool-of-threads
thread_pool_size = 16
thread_pool_max_threads = 1000
thread_pool_stall_limit = 500
```

### 3. InnoDB Optimizations
```sql
# Optimize for e-commerce workload
innodb_buffer_pool_size = 4G
innodb_log_file_size = 512M
innodb_io_capacity = 4000
innodb_read_io_threads = 8
innodb_write_io_threads = 8
innodb_purge_threads = 4
```

### 4. Table Compression
```sql
-- Enable compression for large tables
ROW_FORMAT=DYNAMIC
COMPRESSION='zlib'
```

## Migration Steps

### Phase 1: Schema Migration
1. **Custom Types**: Convert to ENUM or constraints
2. **Domains**: Implement as CHECK constraints
3. **Arrays**: Convert to JSON format
4. **Full-text**: Replace with FULLTEXT indexes
5. **Functions**: Rewrite in SQL/PSM

### Phase 2: Data Migration Options

#### Option A: Logical Migration with pgloader
```bash
# Install pgloader
pgloader --version

# Create mapping file
cat > ecommerce.load << EOF
LOAD DATABASE
    FROM postgresql://user:pass@pghost/ecommerce
    INTO mysql://user:pass@mariadbhost/ecommerce

WITH include drop, create tables, no truncate,
     create indexes, reset sequences,
     workers = 8, concurrency = 4

SET work_mem to '256MB',
    maintenance_work_mem to '512MB'

CAST type json to text drop typemod,
     type jsonb to json drop typemod,
     type text[] to json,
     type inet to varchar(45);
EOF

pgloader ecommerce.load
```

#### Option B: Custom ETL Pipeline
```python
# Python ETL script example
import psycopg2
import mysql.connector
import json

def migrate_products():
    pg_conn = psycopg2.connect("postgresql://...")
    mysql_conn = mysql.connector.connect(...)
    
    pg_cursor = pg_conn.cursor()
    mysql_cursor = mysql_conn.cursor()
    
    pg_cursor.execute("""
        SELECT id, name, specifications, features, tags
        FROM products
    """)
    
    for row in pg_cursor.fetchall():
        # Convert arrays to JSON
        features_json = json.dumps(row[3]) if row[3] else '[]'
        tags_json = json.dumps(row[4]) if row[4] else '[]'
        
        mysql_cursor.execute("""
            INSERT INTO products (id, name, specifications, features, tags)
            VALUES (%s, %s, %s, %s, %s)
        """, (row[0], row[1], row[2], features_json, tags_json))
    
    mysql_conn.commit()
```

#### Option C: CONNECT Storage Engine
```sql
-- Create CONNECT table pointing to PostgreSQL
CREATE TABLE pg_products (
    id INT,
    name VARCHAR(200),
    specifications JSON,
    features TEXT,
    tags TEXT
) ENGINE=CONNECT 
TABLE_TYPE=ODBC
CONNECTION='DSN=PostgreSQL;UID=user;PWD=pass'
SRCDEF='SELECT id, name, specifications::text, array_to_string(features,'',''), array_to_string(tags,'','') FROM products';

-- Transform and copy data
INSERT INTO products (id, name, specifications, features, tags)
SELECT 
    id, 
    name,
    CAST(specifications AS JSON),
    JSON_ARRAY(features),
    JSON_ARRAY(tags)
FROM pg_products;
```

### Phase 3: Application Migration
1. **Connection Strings**: Update database drivers
2. **Query Syntax**: Convert full-text search queries
3. **JSON Operations**: Update JSON path expressions
4. **Error Handling**: Adapt to MariaDB error codes
5. **Transactions**: Verify isolation levels

### Phase 4: Performance Tuning
1. **Analyze Queries**: Use `EXPLAIN` for optimization
2. **Index Optimization**: Add missing indexes
3. **Cache Configuration**: Tune query cache
4. **Connection Pooling**: Implement appropriate pooling

## Testing Strategy

### 1. Data Integrity Verification
```sql
-- Row counts comparison
SELECT 'PostgreSQL' as source, COUNT(*) FROM pg_products UNION
SELECT 'MariaDB' as source, COUNT(*) FROM products;

-- JSON data verification
SELECT COUNT(*) FROM products 
WHERE JSON_VALID(specifications) = 0;

-- Full-text search comparison
SELECT COUNT(*) FROM products 
WHERE MATCH(name, description) AGAINST('laptop' IN BOOLEAN MODE);
```

### 2. Performance Benchmarking
```sql
-- Query performance comparison
SET profiling = 1;
SELECT * FROM products WHERE MATCH(name, description) AGAINST('smartphone' IN BOOLEAN MODE);
SHOW PROFILES;

-- Index usage analysis
EXPLAIN SELECT * FROM products WHERE current_price BETWEEN 100 AND 500;
```

### 3. Functional Testing
- E-commerce workflows (order processing)
- Search functionality
- User registration and authentication
- Payment processing
- Inventory management

## High Availability Setup

### Galera Cluster Configuration
```ini
[galera]
wsrep_provider = /usr/lib/galera/libgalera_smm.so
wsrep_cluster_address = gcomm://node1:4567,node2:4567,node3:4567
wsrep_node_name = node1
wsrep_node_address = 192.168.1.101:4567
wsrep_sst_method = rsync
wsrep_cluster_name = ecommerce_cluster

# Performance optimizations
wsrep_slave_threads = 8
wsrep_certify_nonPK = 1
wsrep_max_ws_rows = 0
wsrep_auto_increment_control = 1
wsrep_retry_autocommit = 3

[mysql]
binlog_format = ROW
default_storage_engine = InnoDB
innodb_autoinc_lock_mode = 2
innodb_locks_unsafe_for_binlog = 1
```

### MaxScale Configuration
```ini
[maxscale]
threads=auto

[server1]
type=server
address=galera-node-1
port=3306
protocol=MariaDBBackend

[server2]
type=server
address=galera-node-2
port=3306
protocol=MariaDBBackend

[Galera-Monitor]
type=monitor
module=galeramon
servers=server1,server2,server3
user=maxscale
password=maxscale_pw

[Read-Write-Service]
type=service
router=readwritesplit
servers=server1,server2,server3
user=maxscale
password=maxscale_pw
```

## Common Challenges and Solutions

### 1. Auto-Increment Conflicts in Galera
**Problem**: Multiple nodes generating conflicting IDs
**Solution**: Use auto-increment offset and large starting values
```sql
-- Node 1
SET GLOBAL auto_increment_offset = 1;
SET GLOBAL auto_increment_increment = 3;

-- Node 2  
SET GLOBAL auto_increment_offset = 2;
SET GLOBAL auto_increment_increment = 3;
```

### 2. JSON Array Handling
**Problem**: PostgreSQL arrays vs MariaDB JSON arrays
**Solution**: Convert to JSON format with proper validation
```sql
-- PostgreSQL: tags TEXT[]
-- MariaDB: tags JSON with validation
CHECK (JSON_VALID(tags) AND JSON_TYPE(tags) = 'ARRAY')
```

### 3. Full-Text Search Differences
**Problem**: Different ranking algorithms
**Solution**: Implement custom relevance scoring
```sql
-- Custom relevance calculation
SELECT *, 
    (MATCH(name) AGAINST('query') * 3 +
     MATCH(description) AGAINST('query') * 1) as relevance_score
FROM products
WHERE MATCH(name, description) AGAINST('query' IN BOOLEAN MODE)
ORDER BY relevance_score DESC;
```

### 4. Transaction Isolation
**Problem**: Different default isolation levels
**Solution**: Explicitly set isolation levels
```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

## MariaDB Advantages for E-Commerce

### 1. Multiple Storage Engines
- **InnoDB**: OLTP transactions
- **ColumnStore**: Analytics and reporting
- **Spider**: Horizontal sharding
- **CONNECT**: Data integration

### 2. Advanced Replication
- **Galera**: Synchronous multi-master
- **Parallel Replication**: Improved slave performance
- **GTID**: Global transaction identifiers

### 3. Performance Features
- **Query Cache**: Faster repeated queries
- **Thread Pool**: Better concurrency
- **Table Compression**: Reduced storage
- **Persistent Statistics**: Consistent query plans

### 4. Enterprise Features
- **Data-at-Rest Encryption**: Security compliance
- **Audit Logging**: Compliance requirements
- **Role-Based Security**: Fine-grained access control
- **Temporal Tables**: Change tracking

## Next Steps
1. Set up the Galera cluster environment
2. Run migration scripts with sample data
3. Performance test the converted system
4. Implement monitoring and alerting
5. Plan production migration strategy
6. Move to advanced dataset (Financial System)

This e-commerce migration demonstrates real-world complexity and showcases MariaDB's enterprise capabilities for high-volume, mission-critical applications.