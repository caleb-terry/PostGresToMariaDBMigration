-- MariaDB Schema for E-Commerce Platform
-- Migrated from PostgreSQL with MariaDB-specific optimizations

-- Users/Customers table with MariaDB features
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('customer', 'vendor', 'admin', 'moderator') DEFAULT 'customer',
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(10),
    profile_picture VARCHAR(500),
    preferences JSON DEFAULT '{}',
    settings JSON DEFAULT '{}',
    loyalty_points INT DEFAULT 0,
    total_spent DECIMAL(10,2) DEFAULT 0,
    last_login DATETIME(6),
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    -- MariaDB virtual columns for fast JSON queries
    email_offers BOOLEAN AS (JSON_EXTRACT(preferences, '$.email_offers')) VIRTUAL,
    sms_alerts BOOLEAN AS (JSON_EXTRACT(preferences, '$.sms_alerts')) VIRTUAL,
    -- Computed column for search
    full_name VARCHAR(101) AS (CONCAT(COALESCE(first_name, ''), ' ', COALESCE(last_name, ''))) PERSISTENT,
    INDEX idx_email (email),
    INDEX idx_username (username),
    INDEX idx_role (role),
    INDEX idx_loyalty_points (loyalty_points DESC),
    INDEX idx_total_spent (total_spent DESC),
    INDEX idx_full_name (full_name),
    FULLTEXT ft_user_search (first_name, last_name, username, email),
    CONSTRAINT valid_email CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Vendors/Sellers table
CREATE TABLE vendors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    user_id INT,
    business_name VARCHAR(100) NOT NULL,
    business_type VARCHAR(50),
    business_registration VARCHAR(100),
    tax_id VARCHAR(50),
    description TEXT,
    logo_url VARCHAR(500),
    website_url VARCHAR(500),
    commission_rate DECIMAL(5,2) DEFAULT 5.00,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    total_sales DECIMAL(10,2) DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0.00,
    review_count INT DEFAULT 0,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_is_verified (is_verified),
    INDEX idx_is_active (is_active),
    INDEX idx_rating (rating DESC),
    INDEX idx_total_sales (total_sales DESC),
    FULLTEXT ft_business_search (business_name, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Categories with nested set model for hierarchy
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    parent_id INT,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    icon VARCHAR(100),
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    seo_title VARCHAR(200),
    seo_description VARCHAR(300),
    seo_keywords JSON, -- Array stored as JSON
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    -- Nested set model columns
    lft INT NOT NULL DEFAULT 0,
    rgt INT NOT NULL DEFAULT 0,
    level INT DEFAULT 0,
    path TEXT, -- Materialized path
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE CASCADE,
    INDEX idx_parent_id (parent_id),
    INDEX idx_nested_set (lft, rgt),
    INDEX idx_level (level),
    INDEX idx_slug (slug),
    INDEX idx_sort_order (sort_order),
    FULLTEXT ft_category_search (name, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Brands table
CREATE TABLE brands (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    logo_url VARCHAR(500),
    website_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    INDEX idx_slug (slug),
    INDEX idx_is_active (is_active),
    FULLTEXT ft_brand_search (name, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Products table with MariaDB optimizations
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    vendor_id INT NOT NULL,
    category_id INT NOT NULL,
    brand_id INT,
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(200) UNIQUE NOT NULL,
    description LONGTEXT,
    short_description TEXT,
    specifications JSON DEFAULT '{}',
    features JSON, -- Array stored as JSON
    tags JSON, -- Array stored as JSON
    status ENUM('draft', 'active', 'discontinued', 'out_of_stock') DEFAULT 'draft',
    base_price DECIMAL(10,2) NOT NULL,
    sale_price DECIMAL(10,2),
    cost_price DECIMAL(10,2),
    weight DECIMAL(8,2), -- in grams
    dimensions JSON, -- {length, width, height}
    digital_product BOOLEAN DEFAULT FALSE,
    downloadable_files JSON DEFAULT '[]',
    stock_quantity INT DEFAULT 0,
    min_stock_level INT DEFAULT 0,
    track_inventory BOOLEAN DEFAULT TRUE,
    allow_backorders BOOLEAN DEFAULT FALSE,
    tax_class VARCHAR(50) DEFAULT 'standard',
    shipping_class VARCHAR(50),
    rating DECIMAL(3,2) DEFAULT 0.00,
    review_count INT DEFAULT 0,
    view_count INT DEFAULT 0,
    sold_count INT DEFAULT 0,
    featured BOOLEAN DEFAULT FALSE,
    seo_title VARCHAR(200),
    seo_description VARCHAR(300),
    seo_keywords JSON, -- Array stored as JSON
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    -- MariaDB computed columns for optimization
    is_on_sale BOOLEAN AS (sale_price IS NOT NULL AND sale_price < base_price) PERSISTENT,
    discount_percentage DECIMAL(5,2) AS (
        CASE WHEN sale_price IS NOT NULL AND sale_price < base_price 
        THEN ROUND(((base_price - sale_price) / base_price) * 100, 2)
        ELSE 0 END
    ) PERSISTENT,
    current_price DECIMAL(10,2) AS (COALESCE(sale_price, base_price)) PERSISTENT,
    profit_margin DECIMAL(10,2) AS (
        CASE WHEN cost_price IS NOT NULL AND cost_price > 0
        THEN ROUND(((COALESCE(sale_price, base_price) - cost_price) / cost_price) * 100, 2)
        ELSE NULL END
    ) PERSISTENT,
    -- Stock status
    stock_status ENUM('in_stock', 'low_stock', 'out_of_stock') AS (
        CASE 
            WHEN stock_quantity = 0 THEN 'out_of_stock'
            WHEN stock_quantity <= min_stock_level THEN 'low_stock'
            ELSE 'in_stock'
        END
    ) PERSISTENT,
    FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
    FOREIGN KEY (brand_id) REFERENCES brands(id) ON DELETE SET NULL,
    INDEX idx_vendor_id (vendor_id),
    INDEX idx_category_id (category_id),
    INDEX idx_brand_id (brand_id),
    INDEX idx_sku (sku),
    INDEX idx_slug (slug),
    INDEX idx_status (status),
    INDEX idx_featured (featured),
    INDEX idx_current_price (current_price),
    INDEX idx_rating (rating DESC),
    INDEX idx_view_count (view_count DESC),
    INDEX idx_sold_count (sold_count DESC),
    INDEX idx_stock_status (stock_status),
    INDEX idx_is_on_sale (is_on_sale),
    INDEX idx_created_at (created_at DESC),
    FULLTEXT ft_product_search (name, short_description, description),
    CONSTRAINT positive_prices CHECK (base_price >= 0 AND (sale_price IS NULL OR sale_price >= 0)),
    CONSTRAINT valid_sale_price CHECK (sale_price IS NULL OR sale_price <= base_price)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  ROW_FORMAT=DYNAMIC
  COMPRESSION='zlib';

-- Product variants (size, color, etc.)
CREATE TABLE product_variants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    product_id INT NOT NULL,
    sku VARCHAR(100) UNIQUE NOT NULL,
    attributes JSON NOT NULL, -- {size: "XL", color: "red"}
    price_adjustment DECIMAL(10,2) DEFAULT 0,
    stock_quantity INT DEFAULT 0,
    image_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    -- Virtual columns for common attributes
    size VARCHAR(20) AS (JSON_UNQUOTE(JSON_EXTRACT(attributes, '$.size'))) VIRTUAL,
    color VARCHAR(50) AS (JSON_UNQUOTE(JSON_EXTRACT(attributes, '$.color'))) VIRTUAL,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_product_id (product_id),
    INDEX idx_sku (sku),
    INDEX idx_size (size),
    INDEX idx_color (color),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Product images
CREATE TABLE product_images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    variant_id INT,
    image_url VARCHAR(500) NOT NULL,
    alt_text VARCHAR(200),
    sort_order INT DEFAULT 0,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE CASCADE,
    INDEX idx_product_id (product_id),
    INDEX idx_variant_id (variant_id),
    INDEX idx_sort_order (sort_order),
    INDEX idx_is_primary (is_primary)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Inventory tracking with partitioning
CREATE TABLE inventory_movements (
    id BIGINT AUTO_INCREMENT,
    product_id INT NOT NULL,
    variant_id INT,
    movement_type ENUM('in', 'out', 'adjustment') NOT NULL,
    quantity INT NOT NULL,
    reference_type VARCHAR(50), -- 'order', 'restock', 'adjustment'
    reference_id INT,
    notes TEXT,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    created_by INT,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_product_id (product_id),
    INDEX idx_created_at (created_at DESC),
    INDEX idx_movement_type (movement_type),
    INDEX idx_reference (reference_type, reference_id),
    PRIMARY KEY (id, created_at)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  PARTITION BY RANGE (UNIX_TIMESTAMP(created_at)) (
    PARTITION p202401 VALUES LESS THAN (UNIX_TIMESTAMP('2024-02-01')),
    PARTITION p202402 VALUES LESS THAN (UNIX_TIMESTAMP('2024-03-01')),
    PARTITION p202403 VALUES LESS THAN (UNIX_TIMESTAMP('2024-04-01')),
    PARTITION pcurrent VALUES LESS THAN MAXVALUE
  );

-- Customer addresses
CREATE TABLE addresses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    user_id INT NOT NULL,
    type ENUM('shipping', 'billing') DEFAULT 'shipping',
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    company VARCHAR(100),
    address_line1 VARCHAR(200) NOT NULL,
    address_line2 VARCHAR(200),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20) NOT NULL,
    country CHAR(2) NOT NULL, -- ISO country code
    phone VARCHAR(20),
    is_default BOOLEAN DEFAULT FALSE,
    latitude DECIMAL(10, 8), -- Geographic coordinates
    longitude DECIMAL(11, 8),
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_type (type),
    INDEX idx_is_default (is_default),
    INDEX idx_country (country),
    INDEX idx_location (latitude, longitude)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Shopping carts with automatic cleanup
CREATE TABLE carts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    user_id INT,
    session_id VARCHAR(255), -- For guest users
    currency CHAR(3) DEFAULT 'USD',
    subtotal DECIMAL(10,2) DEFAULT 0,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    shipping_amount DECIMAL(10,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) DEFAULT 0,
    expires_at DATETIME(6) DEFAULT (CURRENT_TIMESTAMP(6) + INTERVAL 30 DAY),
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_session_id (session_id),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Cart items
CREATE TABLE cart_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cart_id INT NOT NULL,
    product_id INT NOT NULL,
    variant_id INT,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    added_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    FOREIGN KEY (cart_id) REFERENCES carts(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE CASCADE,
    INDEX idx_cart_id (cart_id),
    INDEX idx_product_id (product_id),
    UNIQUE KEY unique_cart_product (cart_id, product_id, variant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Coupons and discounts
CREATE TABLE coupons (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    type ENUM('percentage', 'fixed_amount', 'free_shipping') NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    minimum_amount DECIMAL(10,2) DEFAULT 0,
    maximum_discount DECIMAL(10,2),
    usage_limit INT,
    usage_limit_per_user INT DEFAULT 1,
    used_count INT DEFAULT 0,
    applicable_products JSON, -- Array of product IDs
    applicable_categories JSON, -- Array of category IDs
    valid_from DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    valid_until DATETIME(6),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    -- Computed column for validity
    is_currently_valid BOOLEAN AS (
        is_active = TRUE AND 
        (valid_from IS NULL OR valid_from <= NOW()) AND 
        (valid_until IS NULL OR valid_until >= NOW()) AND
        (usage_limit IS NULL OR used_count < usage_limit)
    ) PERSISTENT,
    INDEX idx_code (code),
    INDEX idx_is_active (is_active),
    INDEX idx_valid_period (valid_from, valid_until),
    INDEX idx_is_currently_valid (is_currently_valid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Orders table with comprehensive tracking
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    order_number VARCHAR(20) UNIQUE NOT NULL,
    user_id INT,
    guest_email VARCHAR(255),
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded') DEFAULT 'pending',
    payment_status ENUM('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded') DEFAULT 'pending',
    currency CHAR(3) DEFAULT 'USD',
    subtotal DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    shipping_amount DECIMAL(10,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    -- Address information (denormalized for historical accuracy)
    billing_address JSON NOT NULL,
    shipping_address JSON NOT NULL,
    shipping_method VARCHAR(100),
    tracking_number VARCHAR(100),
    notes TEXT,
    internal_notes TEXT,
    shipped_at DATETIME(6),
    delivered_at DATETIME(6),
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    -- Computed columns for reporting
    order_year INT AS (YEAR(created_at)) PERSISTENT,
    order_month INT AS (MONTH(created_at)) PERSISTENT,
    is_guest_order BOOLEAN AS (user_id IS NULL) PERSISTENT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_order_number (order_number),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_payment_status (payment_status),
    INDEX idx_created_at (created_at DESC),
    INDEX idx_total_amount (total_amount DESC),
    INDEX idx_order_period (order_year, order_month),
    INDEX idx_is_guest_order (is_guest_order),
    CONSTRAINT valid_guest_email CHECK (user_id IS NOT NULL OR guest_email IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Order items with vendor tracking
CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    variant_id INT,
    vendor_id INT NOT NULL,
    product_snapshot JSON NOT NULL, -- Full product data at time of order
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE RESTRICT,
    FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE RESTRICT,
    INDEX idx_order_id (order_id),
    INDEX idx_product_id (product_id),
    INDEX idx_vendor_id (vendor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Payment transactions
CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    order_id INT NOT NULL,
    payment_method VARCHAR(50) NOT NULL, -- 'credit_card', 'paypal', 'stripe', etc.
    payment_gateway VARCHAR(50),
    gateway_transaction_id VARCHAR(255),
    amount DECIMAL(10,2) NOT NULL,
    currency CHAR(3) NOT NULL,
    status ENUM('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded') DEFAULT 'pending',
    gateway_response JSON,
    processed_at DATETIME(6),
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    INDEX idx_order_id (order_id),
    INDEX idx_status (status),
    INDEX idx_payment_method (payment_method),
    INDEX idx_gateway_transaction_id (gateway_transaction_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Product reviews with moderation
CREATE TABLE reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    product_id INT NOT NULL,
    user_id INT NOT NULL,
    order_item_id INT,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    content TEXT,
    pros JSON, -- Array stored as JSON
    cons JSON, -- Array stored as JSON
    verified_purchase BOOLEAN DEFAULT FALSE,
    helpful_votes INT DEFAULT 0,
    unhelpful_votes INT DEFAULT 0,
    vendor_response TEXT,
    vendor_response_at DATETIME(6),
    is_approved BOOLEAN DEFAULT FALSE,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (order_item_id) REFERENCES order_items(id) ON DELETE SET NULL,
    INDEX idx_product_id (product_id),
    INDEX idx_user_id (user_id),
    INDEX idx_rating (rating),
    INDEX idx_is_approved (is_approved),
    INDEX idx_verified_purchase (verified_purchase),
    INDEX idx_helpful_votes (helpful_votes DESC),
    FULLTEXT ft_review_content (title, content),
    UNIQUE KEY unique_user_product_review (product_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Wishlists
CREATE TABLE wishlists (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    user_id INT NOT NULL,
    name VARCHAR(100) DEFAULT 'My Wishlist',
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_is_public (is_public)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Wishlist items
CREATE TABLE wishlist_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    wishlist_id INT NOT NULL,
    product_id INT NOT NULL,
    variant_id INT,
    added_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    FOREIGN KEY (wishlist_id) REFERENCES wishlists(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE CASCADE,
    INDEX idx_wishlist_id (wishlist_id),
    INDEX idx_product_id (product_id),
    UNIQUE KEY unique_wishlist_product (wishlist_id, product_id, variant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Price history for tracking with partitioning
CREATE TABLE price_history (
    id BIGINT AUTO_INCREMENT,
    product_id INT NOT NULL,
    variant_id INT,
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2) NOT NULL,
    change_type ENUM('price_increase', 'price_decrease', 'sale_start', 'sale_end') NOT NULL,
    changed_by INT,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_product_id (product_id),
    INDEX idx_created_at (created_at DESC),
    INDEX idx_change_type (change_type),
    PRIMARY KEY (id, created_at)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  PARTITION BY RANGE (UNIX_TIMESTAMP(created_at)) (
    PARTITION p202401 VALUES LESS THAN (UNIX_TIMESTAMP('2024-02-01')),
    PARTITION p202402 VALUES LESS THAN (UNIX_TIMESTAMP('2024-03-01')),
    PARTITION p202403 VALUES LESS THAN (UNIX_TIMESTAMP('2024-04-01')),
    PARTITION pcurrent VALUES LESS THAN MAXVALUE
  );

-- Search queries log for analytics using ColumnStore
CREATE TABLE search_queries (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    session_id VARCHAR(255),
    query TEXT NOT NULL,
    results_count INT,
    clicked_product_id INT,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    -- Derived columns for analytics
    search_date DATE AS (DATE(created_at)) PERSISTENT,
    search_hour INT AS (HOUR(created_at)) PERSISTENT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (clicked_product_id) REFERENCES products(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_search_date (search_date),
    INDEX idx_created_at (created_at),
    FULLTEXT ft_search_query (query)
) ENGINE=ColumnStore DEFAULT CHARSET=utf8mb4;

-- Create views for common queries

-- Active products with full vendor and category info
CREATE VIEW active_products_with_details AS
SELECT 
    p.*,
    v.business_name as vendor_name,
    v.rating as vendor_rating,
    v.is_verified as vendor_verified,
    c.name as category_name,
    c.path as category_path,
    b.name as brand_name,
    CASE 
        WHEN p.sale_price IS NOT NULL THEN p.sale_price 
        ELSE p.base_price 
    END as current_price,
    CASE 
        WHEN p.sale_price IS NOT NULL THEN 
            ROUND(((p.base_price - p.sale_price) / p.base_price) * 100, 2)
        ELSE 0 
    END as discount_percentage
FROM products p
JOIN vendors v ON p.vendor_id = v.id
JOIN categories c ON p.category_id = c.id
LEFT JOIN brands b ON p.brand_id = b.id
WHERE p.status = 'active' AND v.is_active = TRUE;

-- Order summary with customer information
CREATE VIEW order_summary AS
SELECT 
    o.*,
    CASE 
        WHEN o.user_id IS NOT NULL THEN CONCAT(u.first_name, ' ', u.last_name)
        ELSE JSON_UNQUOTE(JSON_EXTRACT(o.billing_address, '$.first_name'))
    END as customer_name,
    CASE 
        WHEN o.user_id IS NOT NULL THEN u.email
        ELSE o.guest_email
    END as customer_email,
    COUNT(oi.id) as item_count,
    SUM(oi.quantity) as total_quantity
FROM orders o
LEFT JOIN users u ON o.user_id = u.id
JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id;

-- Advanced stored procedures using MariaDB features

DELIMITER //

-- Procedure to calculate and update product ratings
CREATE PROCEDURE update_product_rating(IN p_product_id INT)
BEGIN
    DECLARE avg_rating DECIMAL(3,2);
    DECLARE review_cnt INT;
    
    SELECT AVG(rating), COUNT(*)
    INTO avg_rating, review_cnt
    FROM reviews
    WHERE product_id = p_product_id AND is_approved = TRUE;
    
    UPDATE products
    SET rating = COALESCE(avg_rating, 0),
        review_count = review_cnt
    WHERE id = p_product_id;
END//

-- Advanced product search procedure
CREATE PROCEDURE search_products(
    IN p_query TEXT,
    IN p_category_id INT,
    IN p_brand_id INT,
    IN p_min_price DECIMAL(10,2),
    IN p_max_price DECIMAL(10,2),
    IN p_min_rating DECIMAL(3,2),
    IN p_limit INT,
    IN p_offset INT
)
BEGIN
    SET @sql = 'SELECT 
        p.id,
        p.name,
        p.current_price,
        p.rating,
        p.view_count,
        v.business_name as vendor_name,
        c.name as category_name,
        b.name as brand_name';
    
    IF p_query IS NOT NULL AND p_query != '' THEN
        SET @sql = CONCAT(@sql, ', MATCH(p.name, p.short_description, p.description) AGAINST(? IN BOOLEAN MODE) as relevance_score');
    END IF;
    
    SET @sql = CONCAT(@sql, ' FROM products p
        JOIN vendors v ON p.vendor_id = v.id
        JOIN categories c ON p.category_id = c.id
        LEFT JOIN brands b ON p.brand_id = b.id
        WHERE p.status = ''active'' AND v.is_active = TRUE');
    
    IF p_query IS NOT NULL AND p_query != '' THEN
        SET @sql = CONCAT(@sql, ' AND MATCH(p.name, p.short_description, p.description) AGAINST(? IN BOOLEAN MODE)');
    END IF;
    
    IF p_category_id IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND p.category_id = ', p_category_id);
    END IF;
    
    IF p_brand_id IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND p.brand_id = ', p_brand_id);
    END IF;
    
    IF p_min_price IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND p.current_price >= ', p_min_price);
    END IF;
    
    IF p_max_price IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND p.current_price <= ', p_max_price);
    END IF;
    
    IF p_min_rating IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND p.rating >= ', p_min_rating);
    END IF;
    
    SET @sql = CONCAT(@sql, ' ORDER BY ');
    IF p_query IS NOT NULL AND p_query != '' THEN
        SET @sql = CONCAT(@sql, 'relevance_score DESC, ');
    END IF;
    SET @sql = CONCAT(@sql, 'p.rating DESC, p.view_count DESC');
    
    IF p_limit IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' LIMIT ', p_limit);
        IF p_offset IS NOT NULL THEN
            SET @sql = CONCAT(@sql, ' OFFSET ', p_offset);
        END IF;
    END IF;
    
    PREPARE stmt FROM @sql;
    IF p_query IS NOT NULL AND p_query != '' THEN
        EXECUTE stmt USING p_query, p_query;
    ELSE
        EXECUTE stmt;
    END IF;
    DEALLOCATE PREPARE stmt;
END//

-- Procedure to process order and update inventory
CREATE PROCEDURE process_order(IN p_order_id INT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE item_product_id INT;
    DECLARE item_variant_id INT;
    DECLARE item_quantity INT;
    
    DECLARE item_cursor CURSOR FOR 
        SELECT product_id, variant_id, quantity 
        FROM order_items 
        WHERE order_id = p_order_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    OPEN item_cursor;
    
    item_loop: LOOP
        FETCH item_cursor INTO item_product_id, item_variant_id, item_quantity;
        IF done THEN
            LEAVE item_loop;
        END IF;
        
        -- Update product inventory
        UPDATE products 
        SET stock_quantity = stock_quantity - item_quantity,
            sold_count = sold_count + item_quantity
        WHERE id = item_product_id;
        
        -- Update variant inventory if applicable
        IF item_variant_id IS NOT NULL THEN
            UPDATE product_variants 
            SET stock_quantity = stock_quantity - item_quantity
            WHERE id = item_variant_id;
        END IF;
        
        -- Record inventory movement
        INSERT INTO inventory_movements (
            product_id, variant_id, movement_type, quantity, 
            reference_type, reference_id
        ) VALUES (
            item_product_id, item_variant_id, 'out', item_quantity,
            'order', p_order_id
        );
        
    END LOOP;
    
    CLOSE item_cursor;
    
    -- Update order status
    UPDATE orders 
    SET status = 'processing', 
        updated_at = CURRENT_TIMESTAMP(6)
    WHERE id = p_order_id;
    
    COMMIT;
END//

-- Event to clean up expired carts
CREATE EVENT cleanup_expired_carts
ON SCHEDULE EVERY 1 HOUR
DO
BEGIN
    DELETE FROM carts WHERE expires_at < NOW();
END//

-- Event to update trending products
CREATE EVENT update_trending_products
ON SCHEDULE EVERY 6 HOUR
DO
BEGIN
    -- Update view counts and recalculate trending scores
    UPDATE products p
    SET view_count = (
        SELECT COUNT(*)
        FROM search_queries sq
        WHERE sq.clicked_product_id = p.id
        AND sq.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    )
    WHERE p.status = 'active';
END//

DELIMITER ;

-- MariaDB-specific features demonstrated:
-- 1. JSON data type with virtual columns for fast queries
-- 2. Computed persistent columns for derived values
-- 3. Advanced partitioning strategies
-- 4. ColumnStore engine for analytics
-- 5. Full-text search with MATCH/AGAINST
-- 6. Complex stored procedures with cursors and error handling
-- 7. Events for automated maintenance
-- 8. Advanced indexing strategies
-- 9. Comprehensive constraints and validation
-- 10. Views for complex queries