-- PostgreSQL Schema for E-Commerce Platform
-- This demonstrates intermediate to advanced PostgreSQL features

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "hstore";

-- Custom types and domains
CREATE TYPE order_status AS ENUM ('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded');
CREATE TYPE payment_status AS ENUM ('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded');
CREATE TYPE user_role AS ENUM ('customer', 'vendor', 'admin', 'moderator');
CREATE TYPE product_status AS ENUM ('draft', 'active', 'discontinued', 'out_of_stock');

CREATE DOMAIN email_address AS TEXT CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
CREATE DOMAIN currency_amount AS NUMERIC(10,2) CHECK (VALUE >= 0);
CREATE DOMAIN percentage AS NUMERIC(5,2) CHECK (VALUE >= 0 AND VALUE <= 100);

-- Users/Customers table with comprehensive profile
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    email email_address UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role user_role DEFAULT 'customer',
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(10),
    profile_picture VARCHAR(500),
    preferences JSONB DEFAULT '{}',
    settings JSONB DEFAULT '{}',
    loyalty_points INTEGER DEFAULT 0,
    total_spent currency_amount DEFAULT 0,
    last_login TIMESTAMP WITH TIME ZONE,
    email_verified BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- Full-text search vector
    search_vector tsvector
);

-- Vendors/Sellers table
CREATE TABLE vendors (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    business_name VARCHAR(100) NOT NULL,
    business_type VARCHAR(50),
    business_registration VARCHAR(100),
    tax_id VARCHAR(50),
    description TEXT,
    logo_url VARCHAR(500),
    website_url VARCHAR(500),
    commission_rate percentage DEFAULT 5.00,
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    total_sales currency_amount DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0.00,
    review_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Categories with hierarchical structure
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    parent_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    icon VARCHAR(100),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    seo_title VARCHAR(200),
    seo_description VARCHAR(300),
    seo_keywords TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- Materialized path for hierarchy
    path TEXT,
    level INTEGER DEFAULT 0
);

-- Brands table
CREATE TABLE brands (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    logo_url VARCHAR(500),
    website_url VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Products table with complex attributes
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    vendor_id INTEGER NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    brand_id INTEGER REFERENCES brands(id) ON DELETE SET NULL,
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(200) UNIQUE NOT NULL,
    description TEXT,
    short_description TEXT,
    specifications JSONB DEFAULT '{}',
    features TEXT[],
    tags TEXT[],
    status product_status DEFAULT 'draft',
    base_price currency_amount NOT NULL,
    sale_price currency_amount,
    cost_price currency_amount,
    weight DECIMAL(8,2), -- in grams
    dimensions JSONB, -- {length, width, height}
    digital_product BOOLEAN DEFAULT false,
    downloadable_files JSONB DEFAULT '[]',
    stock_quantity INTEGER DEFAULT 0,
    min_stock_level INTEGER DEFAULT 0,
    track_inventory BOOLEAN DEFAULT true,
    allow_backorders BOOLEAN DEFAULT false,
    tax_class VARCHAR(50) DEFAULT 'standard',
    shipping_class VARCHAR(50),
    rating DECIMAL(3,2) DEFAULT 0.00,
    review_count INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    sold_count INTEGER DEFAULT 0,
    featured BOOLEAN DEFAULT false,
    seo_title VARCHAR(200),
    seo_description VARCHAR(300),
    seo_keywords TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- Full-text search
    search_vector tsvector
);

-- Product variants (size, color, etc.)
CREATE TABLE product_variants (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    sku VARCHAR(100) UNIQUE NOT NULL,
    attributes JSONB NOT NULL, -- {size: "XL", color: "red"}
    price_adjustment currency_amount DEFAULT 0,
    stock_quantity INTEGER DEFAULT 0,
    image_url VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Product images
CREATE TABLE product_images (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_id INTEGER REFERENCES product_variants(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    alt_text VARCHAR(200),
    sort_order INTEGER DEFAULT 0,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Inventory tracking
CREATE TABLE inventory_movements (
    id BIGSERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_id INTEGER REFERENCES product_variants(id) ON DELETE CASCADE,
    movement_type VARCHAR(20) NOT NULL, -- 'in', 'out', 'adjustment'
    quantity INTEGER NOT NULL,
    reference_type VARCHAR(50), -- 'order', 'restock', 'adjustment'
    reference_id INTEGER,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER REFERENCES users(id) ON DELETE SET NULL
);

-- Customer addresses
CREATE TABLE addresses (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(20) DEFAULT 'shipping', -- 'shipping', 'billing'
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    company VARCHAR(100),
    address_line1 VARCHAR(200) NOT NULL,
    address_line2 VARCHAR(200),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(2) NOT NULL, -- ISO country code
    phone VARCHAR(20),
    is_default BOOLEAN DEFAULT false,
    coordinates POINT, -- Geographic coordinates
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Shopping carts
CREATE TABLE carts (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    session_id VARCHAR(255), -- For guest users
    currency VARCHAR(3) DEFAULT 'USD',
    subtotal currency_amount DEFAULT 0,
    tax_amount currency_amount DEFAULT 0,
    shipping_amount currency_amount DEFAULT 0,
    discount_amount currency_amount DEFAULT 0,
    total_amount currency_amount DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '30 days'),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Cart items
CREATE TABLE cart_items (
    id SERIAL PRIMARY KEY,
    cart_id INTEGER NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_id INTEGER REFERENCES product_variants(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price currency_amount NOT NULL,
    total_price currency_amount NOT NULL,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Coupons and discounts
CREATE TABLE coupons (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    type VARCHAR(20) NOT NULL, -- 'percentage', 'fixed_amount', 'free_shipping'
    value currency_amount NOT NULL,
    minimum_amount currency_amount DEFAULT 0,
    maximum_discount currency_amount,
    usage_limit INTEGER,
    usage_limit_per_user INTEGER DEFAULT 1,
    used_count INTEGER DEFAULT 0,
    applicable_products INTEGER[], -- Array of product IDs
    applicable_categories INTEGER[], -- Array of category IDs
    valid_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Orders table
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    order_number VARCHAR(20) UNIQUE NOT NULL,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    guest_email email_address,
    status order_status DEFAULT 'pending',
    payment_status payment_status DEFAULT 'pending',
    currency VARCHAR(3) DEFAULT 'USD',
    subtotal currency_amount NOT NULL,
    tax_amount currency_amount DEFAULT 0,
    shipping_amount currency_amount DEFAULT 0,
    discount_amount currency_amount DEFAULT 0,
    total_amount currency_amount NOT NULL,
    -- Address information (denormalized for historical accuracy)
    billing_address JSONB NOT NULL,
    shipping_address JSONB NOT NULL,
    shipping_method VARCHAR(100),
    tracking_number VARCHAR(100),
    notes TEXT,
    internal_notes TEXT,
    shipped_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Order items
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    variant_id INTEGER REFERENCES product_variants(id) ON DELETE RESTRICT,
    vendor_id INTEGER NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT,
    product_snapshot JSONB NOT NULL, -- Full product data at time of order
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price currency_amount NOT NULL,
    total_price currency_amount NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Payment transactions
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    payment_method VARCHAR(50) NOT NULL, -- 'credit_card', 'paypal', 'stripe', etc.
    payment_gateway VARCHAR(50),
    gateway_transaction_id VARCHAR(255),
    amount currency_amount NOT NULL,
    currency VARCHAR(3) NOT NULL,
    status payment_status DEFAULT 'pending',
    gateway_response JSONB,
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Product reviews
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_item_id INTEGER REFERENCES order_items(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    content TEXT,
    pros TEXT[],
    cons TEXT[],
    verified_purchase BOOLEAN DEFAULT false,
    helpful_votes INTEGER DEFAULT 0,
    unhelpful_votes INTEGER DEFAULT 0,
    vendor_response TEXT,
    vendor_response_at TIMESTAMP WITH TIME ZONE,
    is_approved BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, user_id) -- One review per product per user
);

-- Wishlists
CREATE TABLE wishlists (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) DEFAULT 'My Wishlist',
    description TEXT,
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Wishlist items
CREATE TABLE wishlist_items (
    id SERIAL PRIMARY KEY,
    wishlist_id INTEGER NOT NULL REFERENCES wishlists(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_id INTEGER REFERENCES product_variants(id) ON DELETE CASCADE,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(wishlist_id, product_id, variant_id)
);

-- Price history for tracking
CREATE TABLE price_history (
    id BIGSERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_id INTEGER REFERENCES product_variants(id) ON DELETE CASCADE,
    old_price currency_amount,
    new_price currency_amount NOT NULL,
    change_type VARCHAR(20) NOT NULL, -- 'price_increase', 'price_decrease', 'sale_start', 'sale_end'
    changed_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Search queries log for analytics
CREATE TABLE search_queries (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    session_id VARCHAR(255),
    query TEXT NOT NULL,
    results_count INTEGER,
    clicked_product_id INTEGER REFERENCES products(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_search_vector ON users USING GIN(search_vector);
CREATE INDEX idx_users_preferences ON users USING GIN(preferences);

CREATE INDEX idx_products_vendor ON products(vendor_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand ON products(brand_id);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_featured ON products(featured);
CREATE INDEX idx_products_price ON products(base_price);
CREATE INDEX idx_products_rating ON products(rating DESC);
CREATE INDEX idx_products_search_vector ON products USING GIN(search_vector);
CREATE INDEX idx_products_tags ON products USING GIN(tags);
CREATE INDEX idx_products_specifications ON products USING GIN(specifications);

CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_orders_total ON orders(total_amount DESC);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

CREATE INDEX idx_inventory_movements_product ON inventory_movements(product_id);
CREATE INDEX idx_inventory_movements_created_at ON inventory_movements(created_at DESC);

CREATE INDEX idx_reviews_product ON reviews(product_id);
CREATE INDEX idx_reviews_user ON reviews(user_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);

-- Create GIN indexes for complex queries
CREATE INDEX idx_categories_path ON categories USING GIN(path gin_trgm_ops);
CREATE INDEX idx_products_name_gin ON products USING GIN(name gin_trgm_ops);

-- Functions and triggers

-- Function to update search vectors for users
CREATE OR REPLACE FUNCTION update_user_search_vector() RETURNS trigger AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.first_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.last_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.username, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.email, '')), 'C');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update search vectors for products
CREATE OR REPLACE FUNCTION update_product_search_vector() RETURNS trigger AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.short_description, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(array_to_string(NEW.tags, ' '), '')), 'D');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column() RETURNS trigger AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to maintain category paths
CREATE OR REPLACE FUNCTION update_category_path() RETURNS trigger AS $$
DECLARE
    parent_path TEXT;
BEGIN
    IF NEW.parent_id IS NULL THEN
        NEW.path := NEW.id::TEXT;
        NEW.level := 0;
    ELSE
        SELECT path, level INTO parent_path, NEW.level 
        FROM categories WHERE id = NEW.parent_id;
        NEW.path := parent_path || '.' || NEW.id::TEXT;
        NEW.level := NEW.level + 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER update_user_search_vector_trigger
    BEFORE INSERT OR UPDATE OF first_name, last_name, username, email
    ON users FOR EACH ROW
    EXECUTE FUNCTION update_user_search_vector();

CREATE TRIGGER update_product_search_vector_trigger
    BEFORE INSERT OR UPDATE OF name, description, short_description, tags
    ON products FOR EACH ROW
    EXECUTE FUNCTION update_product_search_vector();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_category_path_trigger
    BEFORE INSERT OR UPDATE OF parent_id
    ON categories FOR EACH ROW
    EXECUTE FUNCTION update_category_path();

-- Advanced stored procedures

-- Procedure to calculate product ratings
CREATE OR REPLACE FUNCTION update_product_rating(p_product_id INTEGER)
RETURNS VOID AS $$
DECLARE
    avg_rating DECIMAL(3,2);
    review_cnt INTEGER;
BEGIN
    SELECT AVG(rating), COUNT(*)
    INTO avg_rating, review_cnt
    FROM reviews
    WHERE product_id = p_product_id AND is_approved = true;
    
    UPDATE products
    SET rating = COALESCE(avg_rating, 0),
        review_count = review_cnt
    WHERE id = p_product_id;
END;
$$ LANGUAGE plpgsql;

-- Procedure for advanced product search
CREATE OR REPLACE FUNCTION search_products(
    p_query TEXT,
    p_category_id INTEGER DEFAULT NULL,
    p_brand_id INTEGER DEFAULT NULL,
    p_min_price DECIMAL DEFAULT NULL,
    p_max_price DECIMAL DEFAULT NULL,
    p_min_rating DECIMAL DEFAULT NULL,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
) RETURNS TABLE (
    product_id INTEGER,
    name VARCHAR,
    base_price DECIMAL,
    rating DECIMAL,
    rank REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.name,
        p.base_price,
        p.rating,
        ts_rank(p.search_vector, plainto_tsquery('english', p_query)) as rank
    FROM products p
    WHERE 
        (p_query IS NULL OR p.search_vector @@ plainto_tsquery('english', p_query))
        AND (p_category_id IS NULL OR p.category_id = p_category_id)
        AND (p_brand_id IS NULL OR p.brand_id = p_brand_id)
        AND (p_min_price IS NULL OR p.base_price >= p_min_price)
        AND (p_max_price IS NULL OR p.base_price <= p_max_price)
        AND (p_min_rating IS NULL OR p.rating >= p_min_rating)
        AND p.status = 'active'
    ORDER BY 
        CASE WHEN p_query IS NOT NULL THEN rank END DESC,
        p.rating DESC,
        p.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Views for common queries

-- Active products with vendor info
CREATE VIEW active_products_with_vendor AS
SELECT 
    p.*,
    v.business_name as vendor_name,
    v.rating as vendor_rating,
    c.name as category_name,
    b.name as brand_name
FROM products p
JOIN vendors v ON p.vendor_id = v.id
JOIN categories c ON p.category_id = c.id
LEFT JOIN brands b ON p.brand_id = b.id
WHERE p.status = 'active' AND v.is_active = true;

-- Order summary view
CREATE VIEW order_summary AS
SELECT 
    o.*,
    u.first_name || ' ' || u.last_name as customer_name,
    u.email as customer_email,
    COUNT(oi.id) as item_count,
    SUM(oi.quantity) as total_quantity
FROM orders o
LEFT JOIN users u ON o.user_id = u.id
JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id, u.first_name, u.last_name, u.email;

-- This schema demonstrates advanced PostgreSQL features:
-- 1. Custom types and domains for data validation
-- 2. Complex JSONB usage for flexible data storage
-- 3. Arrays for tags and multi-value attributes
-- 4. Full-text search with weighted vectors
-- 5. Geographic data types (POINT)
-- 6. Advanced indexing strategies (GIN, trigram)
-- 7. Complex stored procedures with business logic
-- 8. Materialized path for hierarchical data
-- 9. Comprehensive constraint definitions
-- 10. Advanced query optimization techniques