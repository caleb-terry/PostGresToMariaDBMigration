-- PostgreSQL Schema for Simple Blog System
-- This demonstrates basic PostgreSQL features that need migration consideration

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table with PostgreSQL-specific features
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    bio TEXT,
    avatar_url VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Posts table with full-text search capabilities
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    author_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(200) UNIQUE NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    published_at TIMESTAMP WITH TIME ZONE,
    view_count INTEGER DEFAULT 0,
    estimated_read_time INTEGER, -- in minutes
    featured_image VARCHAR(500),
    meta_description VARCHAR(160),
    meta_keywords TEXT[],
    search_vector tsvector,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Categories table
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    parent_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tags table
CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(30) UNIQUE NOT NULL,
    slug VARCHAR(30) UNIQUE NOT NULL,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Post categories (many-to-many)
CREATE TABLE post_categories (
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, category_id)
);

-- Post tags (many-to-many)
CREATE TABLE post_tags (
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    tag_id INTEGER REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, tag_id)
);

-- Comments table with nested structure
CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    parent_id INTEGER REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    author_name VARCHAR(100),
    author_email VARCHAR(100),
    author_ip INET,
    is_approved BOOLEAN DEFAULT false,
    likes_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User sessions table
CREATE TABLE user_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Audit log table
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL,
    table_name VARCHAR(50),
    record_id INTEGER,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_posts_author_id ON posts(author_id);
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_published_at ON posts(published_at DESC) WHERE status = 'published';
CREATE INDEX idx_posts_slug ON posts(slug);
CREATE INDEX idx_posts_search_vector ON posts USING GIN(search_vector);
CREATE INDEX idx_posts_meta_keywords ON posts USING GIN(meta_keywords);

CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_parent_id ON comments(parent_id);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_metadata ON users USING GIN(metadata);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- Create function for updating search vector
CREATE OR REPLACE FUNCTION update_post_search_vector() RETURNS trigger AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.excerpt, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.content, '')), 'C');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for search vector
CREATE TRIGGER update_post_search_vector_trigger
    BEFORE INSERT OR UPDATE OF title, excerpt, content
    ON posts
    FOR EACH ROW
    EXECUTE FUNCTION update_post_search_vector();

-- Create function for updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column() RETURNS trigger AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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
LEFT JOIN comments c ON p.id = c.post_id AND c.is_approved = true
WHERE p.status = 'published'
GROUP BY p.id, u.username, u.full_name, u.avatar_url;

-- Create materialized view for popular tags
CREATE MATERIALIZED VIEW popular_tags AS
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

-- Create index on materialized view
CREATE INDEX idx_popular_tags_post_count ON popular_tags(post_count DESC);

-- Sample stored procedure for post statistics
CREATE OR REPLACE FUNCTION get_post_statistics(p_user_id INTEGER)
RETURNS TABLE (
    total_posts INTEGER,
    published_posts INTEGER,
    draft_posts INTEGER,
    total_views BIGINT,
    total_comments BIGINT,
    avg_read_time NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER AS total_posts,
        COUNT(*) FILTER (WHERE status = 'published')::INTEGER AS published_posts,
        COUNT(*) FILTER (WHERE status = 'draft')::INTEGER AS draft_posts,
        COALESCE(SUM(view_count), 0)::BIGINT AS total_views,
        (SELECT COUNT(*) FROM comments c WHERE c.post_id IN (SELECT id FROM posts WHERE author_id = p_user_id))::BIGINT AS total_comments,
        AVG(estimated_read_time)::NUMERIC AS avg_read_time
    FROM posts
    WHERE author_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Add some PostgreSQL-specific constraints
ALTER TABLE posts ADD CONSTRAINT valid_published_date 
    CHECK (published_at IS NULL OR (status = 'published' AND published_at IS NOT NULL));

ALTER TABLE users ADD CONSTRAINT valid_email 
    CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- Create custom type for post status (enum alternative)
CREATE TYPE post_status_type AS ENUM ('draft', 'published', 'archived');

-- Note: This schema uses several PostgreSQL-specific features:
-- 1. SERIAL for auto-increment
-- 2. UUID generation with uuid-ossp extension
-- 3. JSONB data type for flexible metadata
-- 4. Arrays (TEXT[])
-- 5. INET data type for IP addresses
-- 6. Full-text search with tsvector and GIN indexes
-- 7. TIMESTAMP WITH TIME ZONE
-- 8. Materialized views
-- 9. PL/pgSQL functions and triggers
-- 10. Check constraints with regex