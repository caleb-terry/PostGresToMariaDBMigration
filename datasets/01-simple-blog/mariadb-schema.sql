-- MariaDB Schema for Simple Blog System
-- Migrated from PostgreSQL with MariaDB-specific optimizations

-- Users table with MariaDB features
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
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login DATETIME,
    metadata JSON DEFAULT '{}',
    -- MariaDB specific: Virtual columns for JSON data
    interests JSON AS (JSON_EXTRACT(metadata, '$.interests')) VIRTUAL,
    social_links JSON AS (JSON_EXTRACT(metadata, '$.social')) VIRTUAL,
    INDEX idx_email (email),
    INDEX idx_username (username),
    INDEX idx_metadata ((CAST(metadata AS CHAR(255))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Posts table with MariaDB optimizations
CREATE TABLE posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    author_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(200) UNIQUE NOT NULL,
    content LONGTEXT NOT NULL,
    excerpt TEXT,
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    published_at DATETIME,
    view_count INT DEFAULT 0,
    estimated_read_time INT, -- in minutes
    featured_image VARCHAR(500),
    meta_description VARCHAR(160),
    meta_keywords JSON, -- Using JSON instead of array
    -- MariaDB Full-text search
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_author_id (author_id),
    INDEX idx_status (status),
    INDEX idx_published_at (published_at DESC),
    INDEX idx_slug (slug),
    FULLTEXT ft_search (title, excerpt, content),
    -- MariaDB specific: Persistent computed column for faster queries
    is_published BOOLEAN AS (status = 'published') PERSISTENT,
    INDEX idx_is_published (is_published)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Categories table
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    parent_id INT,
    display_order INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL,
    INDEX idx_parent_id (parent_id),
    INDEX idx_display_order (display_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tags table
CREATE TABLE tags (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(30) UNIQUE NOT NULL,
    slug VARCHAR(30) UNIQUE NOT NULL,
    usage_count INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_usage_count (usage_count DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Post categories (many-to-many)
CREATE TABLE post_categories (
    post_id INT,
    category_id INT,
    PRIMARY KEY (post_id, category_id),
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
    INDEX idx_category_post (category_id, post_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Post tags (many-to-many)
CREATE TABLE post_tags (
    post_id INT,
    tag_id INT,
    PRIMARY KEY (post_id, tag_id),
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE,
    INDEX idx_tag_post (tag_id, post_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Comments table with nested structure
CREATE TABLE comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT,
    parent_id INT,
    content TEXT NOT NULL,
    author_name VARCHAR(100),
    author_email VARCHAR(100),
    author_ip VARCHAR(45), -- Supports both IPv4 and IPv6
    is_approved BOOLEAN DEFAULT FALSE,
    likes_count INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE,
    INDEX idx_post_id (post_id),
    INDEX idx_user_id (user_id),
    INDEX idx_parent_id (parent_id),
    INDEX idx_is_approved (is_approved),
    INDEX idx_created_at (created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User sessions table
CREATE TABLE user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_session_token (session_token),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Audit log table with partitioning support
CREATE TABLE audit_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(50) NOT NULL,
    table_name VARCHAR(50),
    record_id INT,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at DESC),
    INDEX idx_action (action),
    INDEX idx_table_name (table_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
PARTITION BY RANGE (YEAR(created_at)) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION pmax VALUES LESS THAN MAXVALUE
);

-- Create view for published posts with author info
CREATE VIEW published_posts_with_author AS
SELECT 
    p.id,
    p.uuid,
    p.title,
    p.slug,
    p.excerpt,
    p.content,
    p.published_at,
    p.view_count,
    p.estimated_read_time,
    p.featured_image,
    u.username AS author_username,
    u.full_name AS author_name,
    u.avatar_url AS author_avatar,
    COUNT(DISTINCT c.id) AS comment_count
FROM posts p
JOIN users u ON p.author_id = u.id
LEFT JOIN comments c ON p.id = c.post_id AND c.is_approved = TRUE
WHERE p.status = 'published'
GROUP BY p.id;

-- Create view for popular tags (MariaDB doesn't have materialized views natively)
-- We'll use a regular table that gets refreshed periodically
CREATE TABLE popular_tags_cache (
    id INT PRIMARY KEY,
    name VARCHAR(30),
    slug VARCHAR(30),
    post_count INT,
    last_used DATETIME,
    last_refreshed DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_post_count (post_count DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Stored procedure to refresh popular tags cache
DELIMITER //

CREATE PROCEDURE refresh_popular_tags()
BEGIN
    TRUNCATE TABLE popular_tags_cache;
    
    INSERT INTO popular_tags_cache (id, name, slug, post_count, last_used)
    SELECT 
        t.id,
        t.name,
        t.slug,
        COUNT(pt.post_id) AS post_count,
        MAX(p.published_at) AS last_used
    FROM tags t
    JOIN post_tags pt ON t.id = pt.tag_id
    JOIN posts p ON pt.post_id = p.id
    WHERE p.status = 'published'
    GROUP BY t.id, t.name, t.slug
    ORDER BY post_count DESC;
    
    UPDATE popular_tags_cache SET last_refreshed = NOW();
END//

-- Stored procedure for post statistics (converted from PostgreSQL)
CREATE PROCEDURE get_post_statistics(IN p_user_id INT)
BEGIN
    SELECT 
        COUNT(*) AS total_posts,
        SUM(CASE WHEN status = 'published' THEN 1 ELSE 0 END) AS published_posts,
        SUM(CASE WHEN status = 'draft' THEN 1 ELSE 0 END) AS draft_posts,
        COALESCE(SUM(view_count), 0) AS total_views,
        (SELECT COUNT(*) FROM comments c WHERE c.post_id IN (SELECT id FROM posts WHERE author_id = p_user_id)) AS total_comments,
        AVG(estimated_read_time) AS avg_read_time
    FROM posts
    WHERE author_id = p_user_id;
END//

-- Trigger to update tag usage count
CREATE TRIGGER update_tag_usage_after_insert
AFTER INSERT ON post_tags
FOR EACH ROW
BEGIN
    UPDATE tags SET usage_count = usage_count + 1 WHERE id = NEW.tag_id;
END//

CREATE TRIGGER update_tag_usage_after_delete
AFTER DELETE ON post_tags
FOR EACH ROW
BEGIN
    UPDATE tags SET usage_count = usage_count - 1 WHERE id = OLD.tag_id;
END//

-- Event to refresh popular tags cache every hour
CREATE EVENT refresh_popular_tags_event
ON SCHEDULE EVERY 1 HOUR
DO CALL refresh_popular_tags()//

DELIMITER ;

-- Add constraints (converted from PostgreSQL CHECK constraints)
-- MariaDB supports CHECK constraints from version 10.2+
ALTER TABLE posts ADD CONSTRAINT valid_published_date 
    CHECK (published_at IS NULL OR (status = 'published' AND published_at IS NOT NULL));

ALTER TABLE users ADD CONSTRAINT valid_email 
    CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$');

-- MariaDB-specific features demonstrated:
-- 1. AUTO_INCREMENT instead of SERIAL
-- 2. UUID() function for UUID generation
-- 3. JSON data type and JSON functions
-- 4. Virtual and Persistent columns
-- 5. ON UPDATE CURRENT_TIMESTAMP for automatic timestamp updates
-- 6. ENUM type for constrained values
-- 7. FULLTEXT indexes for text search
-- 8. Table partitioning for audit_logs
-- 9. Events for scheduled tasks
-- 10. Stored procedures
-- 11. Triggers for maintaining derived data
-- 12. CHECK constraints (10.2+)

-- Performance optimizations:
-- 1. InnoDB engine for all tables (ACID compliance)
-- 2. Appropriate indexes for common queries
-- 3. Persistent computed columns for frequently accessed calculations
-- 4. Partitioning for large audit table
-- 5. Cache table for expensive aggregations