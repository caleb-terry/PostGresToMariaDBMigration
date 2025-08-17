# PostgreSQL to MariaDB Migration Training Environment

This repository provides a comprehensive training environment for migrating from PostgreSQL to MariaDB, featuring three progressive datasets and advanced MariaDB capabilities.

## Quick Start

### Environment Setup
```bash
# Start the entire environment
cd docker && docker-compose up -d

# Check service health
docker-compose ps

# Stop environment
docker-compose down
```

### Service Access Points
- **PostgreSQL**: localhost:5432 (postgres/postgres123)
- **MariaDB Primary**: localhost:3306 (root/mariadb123)
- **MariaDB Replica 1**: localhost:3307 (root/mariadb123)  
- **MariaDB Replica 2**: localhost:3308 (root/mariadb123)
- **MaxScale Read/Write Split**: localhost:4000
- **MaxScale Read-Only**: localhost:4001
- **pgAdmin**: http://localhost:5050 (admin@example.com/admin123)
- **phpMyAdmin**: http://localhost:8080
- **MaxScale REST API**: http://localhost:8989

## Dataset Architecture

The training environment features three progressively complex datasets:

### 1. Simple Blog System (`/datasets/01-simple-blog/`)
**Purpose**: Introduction to basic migration concepts
**PostgreSQL Features**: SERIAL, UUID, JSONB, TIMESTAMP WITH TIME ZONE, TEXT[], tsvector, GIN indexes
**MariaDB Features**: AUTO_INCREMENT, Virtual columns, JSON, FULLTEXT indexes, Query cache

**Key Files**:
- `postgres-schema.sql` - Original PostgreSQL schema
- `mariadb-schema.sql` - Converted MariaDB schema with optimizations
- `mariadb-optimized.sql` - Advanced MariaDB features implementation
- `migration-notes.md` - Detailed migration strategies and comparisons

### 2. E-Commerce Platform (`/datasets/02-ecommerce-platform/`)
**Purpose**: Intermediate to advanced migration scenarios
**PostgreSQL Features**: Custom ENUMs, domains, complex JSONB, full-text search, stored procedures
**MariaDB Features**: Galera Cluster preparation, ColumnStore for analytics, advanced partitioning

**Key Files**:
- `postgres-schema.sql` - Complex e-commerce schema
- `mariadb-schema.sql` - Converted schema
- `mariadb-galera-ready.sql` - Galera Cluster optimized version
- `migration-notes.md` - Enterprise migration strategies

### 3. Financial System (`/datasets/03-financial-system/`)
**Purpose**: Enterprise-level migration complexity
**PostgreSQL Features**: Custom types, domains, partitioning, advanced triggers, audit logging, regulatory compliance
**MariaDB Features**: Advanced security, compliance tracking, performance optimization

**Current Status**: PostgreSQL schema complete, MariaDB migration in progress

## Docker Environment

### Architecture
- **PostgreSQL**: Source database with sample data
- **MariaDB Cluster**: 3-node setup (1 primary, 2 replicas)
- **MaxScale**: Load balancer and proxy
- **Management Tools**: pgAdmin and phpMyAdmin

### Key Configuration Files
- `/docker/docker-compose.yml` - Service definitions
- `/docker/mariadb/mariadb-custom.cnf` - MariaDB performance tuning
- `/docker/mariadb/maxscale.cnf` - Load balancer configuration

### Important Docker Commands
```bash
# Load sample data into PostgreSQL
docker exec -it postgres-source psql -U postgres -d migration_db -f /datasets/01-simple-blog/postgres-schema.sql

# Load converted schema into MariaDB
docker exec -it mariadb-primary mysql -u root -pmaria db123 migration_db < /datasets/01-simple-blog/mariadb-schema.sql

# Monitor MariaDB cluster status
docker exec -it mariadb-primary mysql -u root -pmaria db123 -e "SHOW STATUS LIKE 'wsrep%'"

# Check MaxScale status
curl http://localhost:8989/v1/servers
```

## Migration Workflow

### Data Type Mapping Strategy
| PostgreSQL | MariaDB | Migration Notes |
|------------|---------|-----------------|
| `SERIAL` | `INT AUTO_INCREMENT` | Basic auto-increment |
| `UUID` | `CHAR(36)` with `UUID()` | Use MariaDB's UUID() function |
| `JSONB` | `JSON` | MariaDB JSON with virtual columns |
| `TEXT[]` | `JSON` arrays | Convert arrays to JSON format |
| `tsvector` | `FULLTEXT` indexes | Use MATCH/AGAINST syntax |
| `TIMESTAMP WITH TIME ZONE` | `DATETIME` | Convert to UTC, handle TZ in app |

### Recommended Migration Steps
1. **Schema Analysis**: Review PostgreSQL-specific features
2. **Data Type Conversion**: Map types using reference tables
3. **Feature Migration**: Convert functions, triggers, and procedures
4. **Data Migration**: Use pgloader, custom scripts, or CONNECT engine
5. **Performance Optimization**: Implement MariaDB-specific features
6. **Testing**: Validate data integrity and performance

## MariaDB-Specific Features Demonstrated

### Virtual and Persistent Columns
```sql
-- Extract JSON data as virtual columns
interests JSON AS (JSON_EXTRACT(metadata, '$.interests')) VIRTUAL,
-- Pre-calculate expensive operations  
current_price DECIMAL(12,2) AS (COALESCE(sale_price, base_price)) PERSISTENT
```

### Storage Engine Selection
- **InnoDB**: ACID compliance, foreign keys (default)
- **ColumnStore**: Analytics queries (demonstrated in e-commerce)
- **Partitioning**: Time-based for audit tables

### Performance Features
- **Query Cache**: Enabled in custom configuration
- **Thread Pool**: Configured for high concurrency
- **Galera Cluster**: Multi-master replication setup

### Advanced Indexing
```sql
-- Hash indexes for exact lookups
INDEX idx_slug_hash (slug) USING HASH,
-- Invisible indexes for future optimization
INDEX idx_last_login (last_login) INVISIBLE,
-- Full-text search
FULLTEXT ft_post_search (title, excerpt, content)
```

## Migration Tools Available

### Built-in Options
- **CONNECT Storage Engine**: Direct PostgreSQL access from MariaDB
- **pgloader**: Automated migration tool (documented in e-commerce notes)
- **Custom ETL Scripts**: Python examples provided

### Testing and Validation
```sql
-- Data integrity checks
SELECT 'PostgreSQL' as source, COUNT(*) FROM pg_table UNION
SELECT 'MariaDB' as source, COUNT(*) FROM mariadb_table;

-- Performance comparisons
EXPLAIN SELECT * FROM posts WHERE MATCH(title, content) AGAINST('search term');
```

## Performance Tuning

### MariaDB Configuration Highlights
- **InnoDB Buffer Pool**: 1GB (adjust for production)
- **Thread Pool**: 16 threads, max 500
- **Query Cache**: 128MB enabled
- **Binary Logging**: ROW format for replication

### Monitoring Commands
```sql
-- Check query cache effectiveness
SHOW STATUS LIKE 'Qcache%';

-- Monitor thread pool
SHOW STATUS LIKE 'Threadpool%';

-- Check InnoDB metrics
SHOW ENGINE INNODB STATUS\G
```

## Common Migration Challenges

### Array Data Types
**Issue**: PostgreSQL arrays don't exist in MariaDB
**Solution**: Convert to JSON arrays with proper validation

### Full-Text Search
**Issue**: Different syntax and ranking algorithms
**Solution**: Use MariaDB FULLTEXT with custom relevance scoring

### UUID Generation
**Issue**: PostgreSQL uuid-ossp extension
**Solution**: Use MariaDB's built-in UUID() function

### Time Zone Handling
**Issue**: TIMESTAMP WITH TIME ZONE differences
**Solution**: Convert to UTC, handle time zones in application

## Exercise Structure

Each dataset includes:
- PostgreSQL source schema with sample data
- MariaDB converted schema
- Migration notes with detailed explanations
- Performance optimization examples
- Testing strategies

Progress through datasets sequentially for comprehensive learning.

## Development Notes

- In Docker Compose, the `version` attribute is obsolete and should be removed
- Always use absolute paths when referencing files in this repository
- Test migrations thoroughly before production implementation
- Consider regulatory compliance requirements for financial datasets
