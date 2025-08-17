-- Sample data for PostgreSQL Simple Blog System
-- This data demonstrates various PostgreSQL features

-- Insert users
INSERT INTO users (username, email, password_hash, full_name, bio, avatar_url, metadata) VALUES
('johndoe', 'john@example.com', '$2a$10$YS8Uw6L8kO.lN0RJKnCkVeQLxGZ4KqwvY6xb0rcD5QD9pKHamOWKe', 'John Doe', 'Tech enthusiast and blogger', 'https://example.com/avatars/john.jpg', '{"interests": ["technology", "programming"], "social": {"twitter": "@johndoe"}}'),
('janesmith', 'jane@example.com', '$2a$10$YS8Uw6L8kO.lN0RJKnCkVeQLxGZ4KqwvY6xb0rcD5QD9pKHamOWKe', 'Jane Smith', 'Digital marketing expert', 'https://example.com/avatars/jane.jpg', '{"interests": ["marketing", "SEO"], "social": {"linkedin": "janesmith"}}'),
('bobwilson', 'bob@example.com', '$2a$10$YS8Uw6L8kO.lN0RJKnCkVeQLxGZ4KqwvY6xb0rcD5QD9pKHamOWKe', 'Bob Wilson', 'Database administrator and consultant', 'https://example.com/avatars/bob.jpg', '{"interests": ["databases", "optimization"], "certifications": ["PostgreSQL", "MariaDB"]}'),
('alicebrown', 'alice@example.com', '$2a$10$YS8Uw6L8kO.lN0RJKnCkVeQLxGZ4KqwvY6xb0rcD5QD9pKHamOWKe', 'Alice Brown', 'Full-stack developer', 'https://example.com/avatars/alice.jpg', '{"interests": ["web development", "cloud"], "skills": ["React", "Node.js", "PostgreSQL"]}'),
('charlie', 'charlie@example.com', '$2a$10$YS8Uw6L8kO.lN0RJKnCkVeQLxGZ4KqwvY6xb0rcD5QD9pKHamOWKe', 'Charlie Davis', 'DevOps engineer', 'https://example.com/avatars/charlie.jpg', '{"interests": ["automation", "CI/CD"], "tools": ["Docker", "Kubernetes"]}');

-- Update last_login for some users
UPDATE users SET last_login = NOW() - INTERVAL '1 hour' WHERE username = 'johndoe';
UPDATE users SET last_login = NOW() - INTERVAL '2 days' WHERE username = 'janesmith';

-- Insert categories
INSERT INTO categories (name, slug, description) VALUES
('Technology', 'technology', 'All things tech'),
('Database', 'database', 'Database management and optimization'),
('Programming', 'programming', 'Programming languages and techniques'),
('Web Development', 'web-development', 'Frontend and backend development'),
('DevOps', 'devops', 'Development operations and automation'),
('Cloud Computing', 'cloud-computing', 'Cloud platforms and services');

-- Insert child categories
INSERT INTO categories (name, slug, description, parent_id) VALUES
('PostgreSQL', 'postgresql', 'PostgreSQL specific topics', 2),
('MariaDB', 'mariadb', 'MariaDB and MySQL topics', 2),
('JavaScript', 'javascript', 'JavaScript programming', 3),
('Python', 'python', 'Python programming', 3);

-- Insert tags
INSERT INTO tags (name, slug) VALUES
('migration', 'migration'),
('performance', 'performance'),
('tutorial', 'tutorial'),
('best-practices', 'best-practices'),
('security', 'security'),
('optimization', 'optimization'),
('beginner', 'beginner'),
('advanced', 'advanced'),
('tips', 'tips'),
('comparison', 'comparison');

-- Insert posts
INSERT INTO posts (author_id, title, slug, content, excerpt, status, published_at, view_count, estimated_read_time, featured_image, meta_description, meta_keywords) VALUES
(1, 'Getting Started with PostgreSQL to MariaDB Migration', 'postgresql-to-mariadb-migration-guide', 
'# PostgreSQL to MariaDB Migration Guide

Migrating from PostgreSQL to MariaDB can seem daunting, but with the right approach, it can be straightforward. In this comprehensive guide, we will explore the key considerations and steps involved.

## Understanding the Differences

PostgreSQL and MariaDB have different philosophies:
- **PostgreSQL** focuses on standards compliance and advanced features
- **MariaDB** emphasizes performance and MySQL compatibility

## Key Migration Challenges

1. **Data Types**: PostgreSQL''s SERIAL vs MariaDB''s AUTO_INCREMENT
2. **JSON Support**: JSONB in PostgreSQL vs JSON in MariaDB
3. **Stored Procedures**: PL/pgSQL vs SQL/PSM

## Migration Tools

Several tools can help with migration:
- pgloader
- AWS Database Migration Service
- Custom scripts

Stay tuned for detailed examples!', 
'A comprehensive guide to migrating from PostgreSQL to MariaDB, covering key differences and migration strategies.', 
'published', NOW() - INTERVAL '5 days', 1250, 8, 'https://example.com/images/migration.jpg',
'Learn how to migrate from PostgreSQL to MariaDB with this comprehensive guide',
ARRAY['postgresql', 'mariadb', 'migration', 'database']),

(2, 'MariaDB Performance Optimization Techniques', 'mariadb-performance-optimization',
'# MariaDB Performance Optimization

Performance is crucial for any database system. MariaDB offers several unique features for optimization.

## Query Cache
Unlike PostgreSQL, MariaDB still supports query cache, which can significantly improve read performance for repetitive queries.

## Thread Pool
MariaDB''s thread pool can handle thousands of connections efficiently.

## Storage Engines
Choose the right storage engine:
- InnoDB for ACID compliance
- ColumnStore for analytics
- Spider for sharding

## Indexing Strategies
Proper indexing is essential for performance...', 
'Discover advanced techniques to optimize MariaDB performance for your applications.',
'published', NOW() - INTERVAL '3 days', 890, 6, 'https://example.com/images/performance.jpg',
'MariaDB performance optimization techniques and best practices',
ARRAY['mariadb', 'performance', 'optimization', 'database']),

(3, 'Understanding MariaDB Storage Engines', 'mariadb-storage-engines-explained',
'# MariaDB Storage Engines Explained

One of MariaDB''s strengths is its variety of storage engines. Each engine is optimized for different use cases.

## InnoDB
The default storage engine, perfect for:
- ACID transactions
- Foreign keys
- Row-level locking

## ColumnStore
Ideal for analytical workloads:
- Columnar storage
- Massive parallel processing
- Data compression

## Spider
For horizontal partitioning:
- Sharding across multiple servers
- Transparent to applications

## CONNECT
Access external data sources:
- CSV files
- Remote databases
- JSON files

Choose wisely based on your needs!',
'An in-depth look at MariaDB storage engines and when to use each one.',
'published', NOW() - INTERVAL '7 days', 1100, 10, 'https://example.com/images/storage-engines.jpg',
'Complete guide to MariaDB storage engines - InnoDB, ColumnStore, Spider, and more',
ARRAY['mariadb', 'storage-engines', 'innodb', 'columnstore']),

(1, 'Setting Up MariaDB Galera Cluster', 'mariadb-galera-cluster-setup',
'# Setting Up MariaDB Galera Cluster

High availability is critical for production systems. Galera Cluster provides synchronous multi-master replication.

## What is Galera?
- Synchronous replication
- Active-active multi-master topology
- Automatic node joining
- True parallel replication

## Prerequisites
- At least 3 nodes (odd number recommended)
- Network connectivity between nodes
- Identical MariaDB versions

## Configuration Steps
[Detailed configuration steps would follow...]',
'Step-by-step guide to setting up a highly available MariaDB Galera Cluster.',
'published', NOW() - INTERVAL '2 days', 750, 12, 'https://example.com/images/galera.jpg',
'How to set up MariaDB Galera Cluster for high availability',
ARRAY['mariadb', 'galera', 'cluster', 'high-availability']),

(4, 'Data Type Mapping: PostgreSQL to MariaDB', 'postgresql-mariadb-data-type-mapping',
'# Data Type Mapping Guide

When migrating from PostgreSQL to MariaDB, understanding data type mappings is crucial.

## Numeric Types
- PostgreSQL SERIAL → MariaDB INT AUTO_INCREMENT
- PostgreSQL BIGSERIAL → MariaDB BIGINT AUTO_INCREMENT
- PostgreSQL NUMERIC → MariaDB DECIMAL

## String Types
- PostgreSQL TEXT → MariaDB TEXT
- PostgreSQL VARCHAR → MariaDB VARCHAR
- PostgreSQL CHAR → MariaDB CHAR

## Date/Time Types
- PostgreSQL TIMESTAMP WITH TIME ZONE → MariaDB DATETIME
- PostgreSQL DATE → MariaDB DATE
- PostgreSQL TIME → MariaDB TIME

## Special Types
- PostgreSQL UUID → MariaDB CHAR(36) or BINARY(16)
- PostgreSQL JSONB → MariaDB JSON or LONGTEXT
- PostgreSQL ARRAY → MariaDB JSON

[More detailed mappings...]',
'Complete data type mapping reference for PostgreSQL to MariaDB migration.',
'published', NOW() - INTERVAL '4 days', 2100, 5, 'https://example.com/images/data-types.jpg',
'PostgreSQL to MariaDB data type mapping and conversion guide',
ARRAY['postgresql', 'mariadb', 'data-types', 'migration']),

(5, 'MariaDB MaxScale: Load Balancing and More', 'mariadb-maxscale-guide',
'# MariaDB MaxScale Guide

MaxScale is MariaDB''s advanced database proxy that provides load balancing, high availability, and security.

## Key Features
- Automatic read/write splitting
- Connection-based load balancing
- Query filtering and firewall
- Data masking

## Architecture
MaxScale sits between your application and database servers...

## Configuration Example
[Configuration examples would follow...]',
'Learn how to use MariaDB MaxScale for load balancing and query routing.',
'draft', NULL, 0, 15, 'https://example.com/images/maxscale.jpg',
'MariaDB MaxScale configuration for load balancing and high availability',
ARRAY['mariadb', 'maxscale', 'load-balancing', 'proxy']),

(2, 'Migrating PostgreSQL Functions to MariaDB', 'postgresql-functions-to-mariadb',
'# Migrating Functions from PostgreSQL to MariaDB

One of the challenges in migration is converting stored procedures and functions.

## Language Differences
- PostgreSQL: PL/pgSQL
- MariaDB: SQL/PSM

## Syntax Comparison
[Examples of function conversion...]',
'How to convert PostgreSQL functions and stored procedures to MariaDB.',
'draft', NULL, 0, 8, 'https://example.com/images/functions.jpg',
'Converting PostgreSQL functions and stored procedures to MariaDB',
ARRAY['postgresql', 'mariadb', 'functions', 'stored-procedures']);

-- Update tags usage count
UPDATE tags SET usage_count = 5 WHERE slug = 'migration';
UPDATE tags SET usage_count = 3 WHERE slug = 'performance';
UPDATE tags SET usage_count = 4 WHERE slug = 'tutorial';

-- Insert post categories
INSERT INTO post_categories (post_id, category_id) VALUES
(1, 2), (1, 1),  -- Migration guide: Database, Technology
(2, 8), (2, 2),  -- Performance: MariaDB, Database
(3, 8), (3, 2),  -- Storage Engines: MariaDB, Database
(4, 8), (4, 1),  -- Galera: MariaDB, Technology
(5, 2), (5, 7), (5, 8),  -- Data Types: Database, PostgreSQL, MariaDB
(6, 8), (6, 5),  -- MaxScale: MariaDB, DevOps
(7, 2), (7, 3);  -- Functions: Database, Programming

-- Insert post tags
INSERT INTO post_tags (post_id, tag_id) VALUES
(1, 1), (1, 4), (1, 3),  -- Migration guide: migration, best-practices, tutorial
(2, 2), (2, 6), (2, 4),  -- Performance: performance, optimization, best-practices
(3, 10), (3, 3), (3, 8), -- Storage Engines: comparison, tutorial, advanced
(4, 3), (4, 4), (4, 8),  -- Galera: tutorial, best-practices, advanced
(5, 1), (5, 3), (5, 7),  -- Data Types: migration, tutorial, beginner
(6, 8), (6, 4), (6, 2),  -- MaxScale: advanced, best-practices, performance
(7, 1), (7, 8), (7, 9);  -- Functions: migration, advanced, tips

-- Insert comments
INSERT INTO comments (post_id, user_id, content, is_approved, created_at) VALUES
(1, 2, 'Great guide! This really helped me understand the migration process.', true, NOW() - INTERVAL '4 days'),
(1, 3, 'Do you have any specific tools recommendations for large database migrations?', true, NOW() - INTERVAL '3 days'),
(1, 4, 'I found pgloader works well for most cases. Thanks for the comprehensive guide!', true, NOW() - INTERVAL '2 days'),
(2, 1, 'The query cache tip is golden! Improved our read performance by 40%.', true, NOW() - INTERVAL '2 days'),
(2, 5, 'How does MariaDB thread pool compare to PostgreSQL connection pooling?', true, NOW() - INTERVAL '1 day'),
(3, 2, 'ColumnStore sounds interesting for our analytics workload. Any benchmarks?', true, NOW() - INTERVAL '6 days'),
(3, NULL, 'Very informative article!', false, NOW() - INTERVAL '5 days'),
(4, 3, 'Galera setup can be tricky. Make sure your network latency is low!', true, NOW() - INTERVAL '1 day'),
(5, 1, 'The UUID mapping is particularly helpful. We use them extensively.', true, NOW() - INTERVAL '3 days'),
(5, 5, 'What about PostgreSQL arrays? How do you handle those in MariaDB?', true, NOW() - INTERVAL '2 days');

-- Insert nested comments (replies)
INSERT INTO comments (post_id, user_id, parent_id, content, is_approved, created_at) VALUES
(1, 1, 2, 'For large migrations, I recommend using AWS DMS or writing custom ETL scripts.', true, NOW() - INTERVAL '2 days'),
(2, 2, 5, 'MariaDB thread pool is more efficient for handling many short-lived connections.', true, NOW() - INTERVAL '12 hours'),
(5, 4, 10, 'You can use JSON arrays in MariaDB as a replacement for PostgreSQL arrays.', true, NOW() - INTERVAL '1 day');

-- Insert user sessions
INSERT INTO user_sessions (user_id, session_token, ip_address, user_agent, expires_at) VALUES
(1, 'token_abc123def456', '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/91.0', NOW() + INTERVAL '7 days'),
(2, 'token_ghi789jkl012', '192.168.1.101', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Safari/14.1', NOW() + INTERVAL '7 days');

-- Insert audit logs
INSERT INTO audit_logs (user_id, action, table_name, record_id, old_values, new_values, ip_address) VALUES
(1, 'CREATE', 'posts', 1, NULL, '{"title": "Getting Started with PostgreSQL to MariaDB Migration"}', '192.168.1.100'),
(1, 'UPDATE', 'posts', 1, '{"status": "draft"}', '{"status": "published"}', '192.168.1.100'),
(2, 'CREATE', 'posts', 2, NULL, '{"title": "MariaDB Performance Optimization Techniques"}', '192.168.1.101'),
(3, 'CREATE', 'comments', 2, NULL, '{"content": "Do you have any specific tools recommendations?"}', '192.168.1.102'),
(1, 'UPDATE', 'users', 1, '{"last_login": null}', '{"last_login": "2024-01-20T10:00:00Z"}', '192.168.1.100');

-- Refresh materialized view
REFRESH MATERIALIZED VIEW popular_tags;

-- Update post view counts (simulating traffic)
UPDATE posts SET view_count = view_count + 500 WHERE id = 1;
UPDATE posts SET view_count = view_count + 300 WHERE id = 2;
UPDATE posts SET view_count = view_count + 400 WHERE id = 3;
UPDATE posts SET view_count = view_count + 200 WHERE id = 4;
UPDATE posts SET view_count = view_count + 1500 WHERE id = 5;

-- Update comment like counts
UPDATE comments SET likes_count = 15 WHERE id = 1;
UPDATE comments SET likes_count = 8 WHERE id = 4;
UPDATE comments SET likes_count = 12 WHERE id = 9;