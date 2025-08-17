-- MariaDB Optimized Schema with Advanced Features
-- This version showcases MariaDB-specific optimizations and features

-- Enable specific storage engines and features
SET GLOBAL event_scheduler = ON;

-- Users table with MariaDB advanced features
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    bio TEXT,
    avatar_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6), -- Microsecond precision
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    last_login DATETIME(6),
    metadata JSON DEFAULT '{}',
    -- MariaDB Dynamic Columns (alternative to JSON for flexibility)
    profile_data BLOB, -- For dynamic columns
    -- Virtual columns for fast JSON queries
    interests JSON AS (JSON_EXTRACT(metadata, '$.interests')) VIRTUAL,
    social_links JSON AS (JSON_EXTRACT(metadata, '$.social')) VIRTUAL,
    skills JSON AS (JSON_EXTRACT(metadata, '$.skills')) VIRTUAL,
    -- Persistent column for search optimization
    search_name VARCHAR(200) AS (CONCAT(username, ' ', COALESCE(full_name, ''))) PERSISTENT,
    INDEX idx_email (email),
    INDEX idx_username (username),
    INDEX idx_search_name (search_name),
    FULLTEXT ft_user_search (username, full_name, bio),
    -- Invisible index for future query optimization
    INDEX idx_last_login (last_login) INVISIBLE
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  ROW_FORMAT=DYNAMIC
  STATS_PERSISTENT=1
  STATS_AUTO_RECALC=1;

-- Posts table with advanced MariaDB features
CREATE TABLE posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    author_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(200) UNIQUE NOT NULL,
    content LONGTEXT NOT NULL,
    excerpt TEXT,
    status ENUM('draft', 'published', 'archived', 'featured') DEFAULT 'draft',
    published_at DATETIME(6),
    view_count INT DEFAULT 0,
    estimated_read_time INT,
    featured_image VARCHAR(500),
    meta_description VARCHAR(160),
    meta_keywords JSON,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    -- MariaDB Sequence for ordering
    sort_order BIGINT DEFAULT NEXT VALUE FOR post_sort_seq,
    -- Computed columns for optimization
    is_published BOOLEAN AS (status = 'published') PERSISTENT,
    publish_year INT AS (YEAR(published_at)) PERSISTENT,
    word_count INT AS (
        CHAR_LENGTH(content) - CHAR_LENGTH(REPLACE(content, ' ', '')) + 1
    ) PERSISTENT,
    -- Statistics columns updated by triggers
    comment_count INT DEFAULT 0,
    like_count INT DEFAULT 0,
    FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_author_id (author_id),
    INDEX idx_status (status),
    INDEX idx_published_year (publish_year, published_at DESC),
    INDEX idx_slug (slug),
    INDEX idx_view_count (view_count DESC),
    INDEX idx_is_published_views (is_published, view_count DESC),
    FULLTEXT ft_post_search (title, excerpt, content),
    -- Hash index for exact slug lookups (MariaDB extension)
    INDEX idx_slug_hash (slug) USING HASH
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  ROW_FORMAT=DYNAMIC
  STATS_PERSISTENT=1
  COMPRESSION='zlib'; -- Enable compression for large content

-- Create sequence for post ordering
CREATE SEQUENCE post_sort_seq START WITH 1 INCREMENT BY 1;

-- Posts archive table using Spider engine for partitioning
CREATE TABLE posts_archive (
    id INT AUTO_INCREMENT,
    uuid CHAR(36),
    author_id INT,
    title VARCHAR(200),
    slug VARCHAR(200),
    content LONGTEXT,
    excerpt TEXT,
    status ENUM('draft', 'published', 'archived', 'featured'),
    published_at DATETIME(6),
    archived_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    view_count INT DEFAULT 0,
    estimated_read_time INT,
    created_at DATETIME(6),
    updated_at DATETIME(6),
    INDEX idx_archived_at (archived_at),
    INDEX idx_author_id (author_id),
    PRIMARY KEY (id, archived_at)
) ENGINE=InnoDB
  PARTITION BY RANGE (YEAR(archived_at)) (
    PARTITION p2020 VALUES LESS THAN (2021),
    PARTITION p2021 VALUES LESS THAN (2022),
    PARTITION p2022 VALUES LESS THAN (2023),
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION pcurrent VALUES LESS THAN MAXVALUE
  );

-- Analytics table using ColumnStore for reporting
CREATE TABLE post_analytics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    event_type ENUM('view', 'like', 'share', 'comment') NOT NULL,
    user_id INT,
    session_id VARCHAR(255),
    ip_address VARCHAR(45),
    user_agent TEXT,
    referrer VARCHAR(500),
    country CHAR(2),
    region VARCHAR(100),
    city VARCHAR(100),
    device_type ENUM('desktop', 'tablet', 'mobile') DEFAULT 'desktop',
    browser VARCHAR(50),
    os VARCHAR(50),
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    -- Derived date columns for faster aggregation
    event_date DATE AS (DATE(created_at)) PERSISTENT,
    event_hour INT AS (HOUR(created_at)) PERSISTENT,
    INDEX idx_post_event (post_id, event_type, event_date),
    INDEX idx_user_events (user_id, event_type, created_at),
    INDEX idx_analytics_date (event_date, event_hour)
) ENGINE=ColumnStore
  DEFAULT CHARSET=utf8mb4;

-- Categories with nested set model for hierarchical data
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    parent_id INT,
    -- Nested set model columns
    lft INT NOT NULL,
    rgt INT NOT NULL,
    level INT DEFAULT 0,
    display_order INT DEFAULT 0,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL,
    INDEX idx_nested_set (lft, rgt),
    INDEX idx_parent_id (parent_id),
    INDEX idx_level (level),
    UNIQUE KEY unique_lft (lft),
    UNIQUE KEY unique_rgt (rgt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tags with full-text search optimization
CREATE TABLE tags (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(30) UNIQUE NOT NULL,
    slug VARCHAR(30) UNIQUE NOT NULL,
    description TEXT,
    color VARCHAR(7), -- Hex color code
    usage_count INT DEFAULT 0,
    trending_score DECIMAL(5,2) DEFAULT 0.00,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    INDEX idx_usage_count (usage_count DESC),
    INDEX idx_trending (trending_score DESC),
    FULLTEXT ft_tag_search (name, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Comments with thread optimization
CREATE TABLE comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    post_id INT NOT NULL,
    user_id INT,
    parent_id INT,
    thread_id INT, -- Root comment ID for faster thread queries
    depth INT DEFAULT 0,
    content TEXT NOT NULL,
    content_html TEXT, -- Pre-rendered HTML
    author_name VARCHAR(100),
    author_email VARCHAR(100),
    author_ip VARCHAR(45),
    is_approved BOOLEAN DEFAULT FALSE,
    is_spam BOOLEAN DEFAULT FALSE,
    likes_count INT DEFAULT 0,
    replies_count INT DEFAULT 0,
    spam_score DECIMAL(3,2) DEFAULT 0.00,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE,
    INDEX idx_post_thread (post_id, thread_id, depth),
    INDEX idx_user_comments (user_id, created_at DESC),
    INDEX idx_parent_replies (parent_id, created_at),
    INDEX idx_approved_recent (is_approved, created_at DESC),
    INDEX idx_spam_detection (is_spam, spam_score)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Advanced audit logging with temporal tables
CREATE TABLE audit_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action ENUM('CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT') NOT NULL,
    table_name VARCHAR(50),
    record_id BIGINT,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    request_id VARCHAR(36), -- For tracing related operations
    session_id VARCHAR(255),
    execution_time_ms INT, -- Query execution time
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    -- System versioning columns
    row_start DATETIME(6) GENERATED ALWAYS AS ROW START,
    row_end DATETIME(6) GENERATED ALWAYS AS ROW END,
    PERIOD FOR SYSTEM_TIME(row_start, row_end),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_actions (user_id, action, created_at),
    INDEX idx_table_operations (table_name, action, created_at),
    INDEX idx_request_trace (request_id, created_at)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  WITH SYSTEM VERSIONING
  PARTITION BY RANGE (UNIX_TIMESTAMP(created_at)) (
    PARTITION p202401 VALUES LESS THAN (UNIX_TIMESTAMP('2024-02-01')),
    PARTITION p202402 VALUES LESS THAN (UNIX_TIMESTAMP('2024-03-01')),
    PARTITION p202403 VALUES LESS THAN (UNIX_TIMESTAMP('2024-04-01')),
    PARTITION pcurrent VALUES LESS THAN MAXVALUE
  );

-- Performance metrics table for monitoring
CREATE TABLE performance_metrics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,4),
    metric_unit VARCHAR(20),
    tags JSON,
    measured_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    INDEX idx_metric_time (metric_name, measured_at),
    INDEX idx_measured_at (measured_at)
) ENGINE=ColumnStore;

-- Advanced stored procedures using MariaDB features

DELIMITER //

-- Procedure to calculate trending scores
CREATE PROCEDURE calculate_trending_scores()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE tag_id INT;
    DECLARE recent_usage INT;
    DECLARE total_usage INT;
    DECLARE trending_score DECIMAL(5,2);
    
    DECLARE tag_cursor CURSOR FOR 
        SELECT id FROM tags;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN tag_cursor;
    
    tag_loop: LOOP
        FETCH tag_cursor INTO tag_id;
        IF done THEN
            LEAVE tag_loop;
        END IF;
        
        -- Calculate recent usage (last 7 days)
        SELECT COUNT(*) INTO recent_usage
        FROM post_tags pt
        JOIN posts p ON pt.post_id = p.id
        WHERE pt.tag_id = tag_id 
        AND p.published_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        AND p.status = 'published';
        
        -- Calculate total usage
        SELECT usage_count INTO total_usage
        FROM tags WHERE id = tag_id;
        
        -- Calculate trending score (weighted by recency)
        SET trending_score = CASE 
            WHEN total_usage = 0 THEN 0
            ELSE (recent_usage * 10.0) / total_usage
        END;
        
        UPDATE tags 
        SET trending_score = trending_score
        WHERE id = tag_id;
        
    END LOOP;
    
    CLOSE tag_cursor;
END//

-- Advanced analytics procedure
CREATE PROCEDURE get_advanced_post_analytics(
    IN p_post_id INT,
    IN p_date_from DATE,
    IN p_date_to DATE
)
BEGIN
    -- Views by date
    SELECT 
        event_date,
        COUNT(*) as views,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(DISTINCT session_id) as sessions
    FROM post_analytics
    WHERE post_id = p_post_id
    AND event_type = 'view'
    AND event_date BETWEEN p_date_from AND p_date_to
    GROUP BY event_date
    ORDER BY event_date;
    
    -- Device breakdown
    SELECT 
        device_type,
        COUNT(*) as views,
        COUNT(DISTINCT user_id) as unique_users
    FROM post_analytics
    WHERE post_id = p_post_id
    AND event_type = 'view'
    AND event_date BETWEEN p_date_from AND p_date_to
    GROUP BY device_type;
    
    -- Hourly distribution
    SELECT 
        event_hour,
        COUNT(*) as views
    FROM post_analytics
    WHERE post_id = p_post_id
    AND event_type = 'view'
    AND event_date BETWEEN p_date_from AND p_date_to
    GROUP BY event_hour
    ORDER BY event_hour;
END//

DELIMITER ;

-- Create events for automated maintenance

-- Event to calculate trending scores hourly
CREATE EVENT calculate_trending_hourly
ON SCHEDULE EVERY 1 HOUR
DO CALL calculate_trending_scores();

-- Event to archive old posts monthly
CREATE EVENT archive_old_posts
ON SCHEDULE EVERY 1 MONTH
DO
BEGIN
    INSERT INTO posts_archive 
    SELECT *, NOW() 
    FROM posts 
    WHERE status = 'archived' 
    AND updated_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);
    
    DELETE FROM posts 
    WHERE status = 'archived' 
    AND updated_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);
END;

-- MariaDB-specific optimizations demonstrated:
-- 1. Microsecond precision timestamps
-- 2. Dynamic columns for flexible data
-- 3. Computed persistent columns
-- 4. Sequences for ordering
-- 5. Hash indexes for exact matches
-- 6. ColumnStore engine for analytics
-- 7. Table compression
-- 8. Nested set model for hierarchies
-- 9. System versioning (temporal tables)
-- 10. Advanced partitioning strategies
-- 11. Invisible indexes for future optimization
-- 12. Thread pool optimization via table design
-- 13. JSON path expressions in virtual columns
-- 14. Advanced stored procedures with cursors
-- 15. Automated events for maintenance