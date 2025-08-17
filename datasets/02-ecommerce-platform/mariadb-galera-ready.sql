-- MariaDB Galera Cluster Ready E-Commerce Schema
-- Optimized for multi-master replication and high availability

-- Galera Cluster specific settings
SET GLOBAL wsrep_sync_wait = 1; -- Ensure read-after-write consistency
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO';

-- Users table optimized for Galera
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
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
    last_login TIMESTAMP(6),
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    -- Galera optimization: avoid auto-increment conflicts
    node_id TINYINT DEFAULT @@server_id,
    -- Version for optimistic locking
    version INT DEFAULT 0,
    -- Virtual columns for fast JSON queries
    email_offers BOOLEAN AS (JSON_EXTRACT(preferences, '$.email_offers')) VIRTUAL,
    sms_alerts BOOLEAN AS (JSON_EXTRACT(preferences, '$.sms_alerts')) VIRTUAL,
    full_name VARCHAR(101) AS (CONCAT(COALESCE(first_name, ''), ' ', COALESCE(last_name, ''))) PERSISTENT,
    INDEX idx_email (email),
    INDEX idx_username (username),
    INDEX idx_role (role),
    INDEX idx_node_id (node_id),
    INDEX idx_version (version),
    INDEX idx_full_name (full_name),
    FULLTEXT ft_user_search (first_name, last_name, username, email),
    CONSTRAINT valid_email CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  AUTO_INCREMENT=1000000; -- Start high to avoid conflicts

-- Vendors table with Galera optimizations
CREATE TABLE vendors (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    user_id BIGINT,
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
    total_sales DECIMAL(12,2) DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0.00,
    review_count INT DEFAULT 0,
    created_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    version INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_is_verified (is_verified),
    INDEX idx_is_active (is_active),
    INDEX idx_rating (rating DESC),
    INDEX idx_total_sales (total_sales DESC),
    INDEX idx_version (version),
    FULLTEXT ft_business_search (business_name, description)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  AUTO_INCREMENT=10000;

-- Categories with conflict-safe hierarchy
CREATE TABLE categories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    parent_id BIGINT,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    icon VARCHAR(100),
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    seo_title VARCHAR(200),
    seo_description VARCHAR(300),
    seo_keywords JSON,
    created_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    -- Nested set model - modified for Galera
    lft BIGINT NOT NULL DEFAULT 0,
    rgt BIGINT NOT NULL DEFAULT 0,
    level INT DEFAULT 0,
    path TEXT,
    version INT DEFAULT 0,
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE CASCADE,
    INDEX idx_parent_id (parent_id),
    INDEX idx_nested_set (lft, rgt),
    INDEX idx_level (level),
    INDEX idx_slug (slug),
    INDEX idx_sort_order (sort_order),
    INDEX idx_version (version),
    FULLTEXT ft_category_search (name, description)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  AUTO_INCREMENT=1000;

-- Brands table
CREATE TABLE brands (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    logo_url VARCHAR(500),
    website_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
    version INT DEFAULT 0,
    INDEX idx_slug (slug),
    INDEX idx_is_active (is_active),
    INDEX idx_version (version),
    FULLTEXT ft_brand_search (name, description)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  AUTO_INCREMENT=100;

-- Products table with extensive Galera optimizations
CREATE TABLE products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    vendor_id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,
    brand_id BIGINT,
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(200) UNIQUE NOT NULL,
    description LONGTEXT,
    short_description TEXT,
    specifications JSON DEFAULT '{}',
    features JSON,
    tags JSON,
    status ENUM('draft', 'active', 'discontinued', 'out_of_stock') DEFAULT 'draft',
    base_price DECIMAL(12,2) NOT NULL,
    sale_price DECIMAL(12,2),
    cost_price DECIMAL(12,2),
    weight DECIMAL(8,2),
    dimensions JSON,
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
    seo_keywords JSON,
    created_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    version INT DEFAULT 0,
    -- Computed columns for optimization
    is_on_sale BOOLEAN AS (sale_price IS NOT NULL AND sale_price < base_price) PERSISTENT,
    current_price DECIMAL(12,2) AS (COALESCE(sale_price, base_price)) PERSISTENT,
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
    INDEX idx_version (version),
    FULLTEXT ft_product_search (name, short_description, description),
    CONSTRAINT positive_prices CHECK (base_price >= 0 AND (sale_price IS NULL OR sale_price >= 0)),
    CONSTRAINT valid_sale_price CHECK (sale_price IS NULL OR sale_price <= base_price)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  ROW_FORMAT=DYNAMIC
  AUTO_INCREMENT=100000;

-- Orders table with conflict resolution
CREATE TABLE orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) UNIQUE NOT NULL DEFAULT (UUID()),
    order_number VARCHAR(20) UNIQUE NOT NULL,
    user_id BIGINT,
    guest_email VARCHAR(255),
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded') DEFAULT 'pending',
    payment_status ENUM('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded') DEFAULT 'pending',
    currency CHAR(3) DEFAULT 'USD',
    subtotal DECIMAL(12,2) NOT NULL,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    shipping_amount DECIMAL(12,2) DEFAULT 0,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    billing_address JSON NOT NULL,
    shipping_address JSON NOT NULL,
    shipping_method VARCHAR(100),
    tracking_number VARCHAR(100),
    notes TEXT,
    internal_notes TEXT,
    shipped_at TIMESTAMP(6),
    delivered_at TIMESTAMP(6),
    created_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    -- Galera specific fields
    node_id TINYINT DEFAULT @@server_id,
    version INT DEFAULT 0,
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
    INDEX idx_node_id (node_id),
    INDEX idx_version (version),
    CONSTRAINT valid_guest_email CHECK (user_id IS NOT NULL OR guest_email IS NOT NULL)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  AUTO_INCREMENT=1000000;

-- Order items optimized for Galera
CREATE TABLE order_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    variant_id BIGINT,
    vendor_id BIGINT NOT NULL,
    product_snapshot JSON NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(12,2) NOT NULL,
    total_price DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE RESTRICT,
    INDEX idx_order_id (order_id),
    INDEX idx_product_id (product_id),
    INDEX idx_vendor_id (vendor_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  AUTO_INCREMENT=1000000;

-- Inventory movements with time-based partitioning for Galera
CREATE TABLE inventory_movements (
    id BIGINT AUTO_INCREMENT,
    product_id BIGINT NOT NULL,
    variant_id BIGINT,
    movement_type ENUM('in', 'out', 'adjustment') NOT NULL,
    quantity INT NOT NULL,
    reference_type VARCHAR(50),
    reference_id BIGINT,
    notes TEXT,
    created_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
    created_by BIGINT,
    -- Galera specific
    node_id TINYINT DEFAULT @@server_id,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_product_id (product_id),
    INDEX idx_created_at (created_at DESC),
    INDEX idx_movement_type (movement_type),
    INDEX idx_reference (reference_type, reference_id),
    INDEX idx_node_id (node_id),
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

-- Galera-safe counters table for statistics
CREATE TABLE counters (
    id VARCHAR(50) PRIMARY KEY,
    counter_value BIGINT DEFAULT 0,
    updated_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    version INT DEFAULT 0,
    INDEX idx_version (version)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Initialize common counters
INSERT INTO counters (id, counter_value) VALUES
('total_orders', 0),
('total_users', 0),
('total_products', 0),
('daily_sales', 0),
('monthly_sales', 0);

-- Distributed locks table for Galera coordination
CREATE TABLE distributed_locks (
    lock_name VARCHAR(100) PRIMARY KEY,
    locked_by VARCHAR(100) NOT NULL,
    locked_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
    expires_at TIMESTAMP(6) NOT NULL,
    node_id TINYINT DEFAULT @@server_id,
    INDEX idx_expires_at (expires_at),
    INDEX idx_node_id (node_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Advanced stored procedures for Galera

DELIMITER //

-- Galera-safe order number generation
CREATE FUNCTION generate_order_number() RETURNS VARCHAR(20)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE order_num VARCHAR(20);
    DECLARE node_suffix CHAR(1);
    DECLARE counter_val INT;
    
    -- Get node-specific suffix (A, B, C based on server_id)
    SET node_suffix = CHAR(64 + @@server_id);
    
    -- Get current date
    SET order_num = CONCAT('ORD', DATE_FORMAT(NOW(), '%Y%m%d'));
    
    -- Get next counter value (Galera-safe)
    SELECT COALESCE(MAX(CAST(SUBSTRING(order_number, 12, 6) AS UNSIGNED)), 0) + 1
    INTO counter_val
    FROM orders
    WHERE order_number LIKE CONCAT(order_num, '%')
      AND DATE(created_at) = CURDATE();
    
    -- Combine with node suffix
    SET order_num = CONCAT(order_num, LPAD(counter_val, 5, '0'), node_suffix);
    
    RETURN order_num;
END//

-- Galera-safe inventory update with conflict resolution
CREATE PROCEDURE update_inventory_safe(
    IN p_product_id BIGINT,
    IN p_variant_id BIGINT,
    IN p_quantity_change INT,
    IN p_reference_type VARCHAR(50),
    IN p_reference_id BIGINT
)
BEGIN
    DECLARE current_version INT;
    DECLARE retry_count INT DEFAULT 0;
    DECLARE max_retries INT DEFAULT 3;
    
    retry_loop: LOOP
        SET retry_count = retry_count + 1;
        
        -- Get current version
        SELECT version INTO current_version
        FROM products
        WHERE id = p_product_id;
        
        -- Attempt update with optimistic locking
        UPDATE products
        SET stock_quantity = stock_quantity + p_quantity_change,
            version = version + 1
        WHERE id = p_product_id 
          AND version = current_version
          AND stock_quantity + p_quantity_change >= 0;
        
        IF ROW_COUNT() > 0 THEN
            -- Success - record movement
            INSERT INTO inventory_movements (
                product_id, variant_id, movement_type, quantity,
                reference_type, reference_id
            ) VALUES (
                p_product_id, p_variant_id,
                CASE WHEN p_quantity_change > 0 THEN 'in' ELSE 'out' END,
                ABS(p_quantity_change), p_reference_type, p_reference_id
            );
            LEAVE retry_loop;
        END IF;
        
        IF retry_count >= max_retries THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inventory update failed after retries';
        END IF;
        
        -- Brief delay before retry
        DO SLEEP(0.01);
        
    END LOOP retry_loop;
END//

-- Galera-safe counter increment
CREATE PROCEDURE increment_counter(
    IN p_counter_id VARCHAR(50),
    IN p_increment_value BIGINT
)
BEGIN
    DECLARE current_version INT;
    DECLARE retry_count INT DEFAULT 0;
    DECLARE max_retries INT DEFAULT 5;
    
    retry_loop: LOOP
        SET retry_count = retry_count + 1;
        
        SELECT version INTO current_version
        FROM counters
        WHERE id = p_counter_id;
        
        UPDATE counters
        SET counter_value = counter_value + p_increment_value,
            version = version + 1
        WHERE id = p_counter_id AND version = current_version;
        
        IF ROW_COUNT() > 0 THEN
            LEAVE retry_loop;
        END IF;
        
        IF retry_count >= max_retries THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Counter update failed after retries';
        END IF;
        
        DO SLEEP(0.001);
        
    END LOOP retry_loop;
END//

-- Distributed lock acquisition for Galera
CREATE FUNCTION acquire_distributed_lock(
    p_lock_name VARCHAR(100),
    p_locked_by VARCHAR(100),
    p_timeout_seconds INT
) RETURNS BOOLEAN
READS SQL DATA
MODIFIES SQL DATA
BEGIN
    DECLARE lock_acquired BOOLEAN DEFAULT FALSE;
    DECLARE expires_time TIMESTAMP(6);
    
    SET expires_time = TIMESTAMPADD(SECOND, p_timeout_seconds, NOW(6));
    
    -- Clean up expired locks first
    DELETE FROM distributed_locks 
    WHERE expires_at < NOW(6);
    
    -- Try to acquire lock
    INSERT IGNORE INTO distributed_locks (lock_name, locked_by, expires_at)
    VALUES (p_lock_name, p_locked_by, expires_time);
    
    IF ROW_COUNT() > 0 THEN
        SET lock_acquired = TRUE;
    END IF;
    
    RETURN lock_acquired;
END//

-- Release distributed lock
CREATE PROCEDURE release_distributed_lock(
    IN p_lock_name VARCHAR(100),
    IN p_locked_by VARCHAR(100)
)
BEGIN
    DELETE FROM distributed_locks
    WHERE lock_name = p_lock_name AND locked_by = p_locked_by;
END//

-- Galera-optimized order processing
CREATE PROCEDURE process_order_galera(IN p_order_id BIGINT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE item_product_id BIGINT;
    DECLARE item_variant_id BIGINT;
    DECLARE item_quantity INT;
    DECLARE lock_name VARCHAR(100);
    DECLARE lock_acquired BOOLEAN;
    
    DECLARE item_cursor CURSOR FOR 
        SELECT product_id, variant_id, quantity 
        FROM order_items 
        WHERE order_id = p_order_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Release any locks and rollback
        CALL release_distributed_lock(lock_name, CONNECTION_ID());
        ROLLBACK;
        RESIGNAL;
    END;
    
    SET lock_name = CONCAT('order_process_', p_order_id);
    SET lock_acquired = acquire_distributed_lock(lock_name, CONNECTION_ID(), 60);
    
    IF NOT lock_acquired THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unable to acquire processing lock';
    END IF;
    
    START TRANSACTION;
    
    OPEN item_cursor;
    
    item_loop: LOOP
        FETCH item_cursor INTO item_product_id, item_variant_id, item_quantity;
        IF done THEN
            LEAVE item_loop;
        END IF;
        
        -- Update inventory safely
        CALL update_inventory_safe(
            item_product_id, item_variant_id, -item_quantity,
            'order', p_order_id
        );
        
        -- Update sold count
        UPDATE products 
        SET sold_count = sold_count + item_quantity,
            version = version + 1
        WHERE id = item_product_id;
        
    END LOOP;
    
    CLOSE item_cursor;
    
    -- Update order status
    UPDATE orders 
    SET status = 'processing',
        version = version + 1
    WHERE id = p_order_id;
    
    -- Update counters
    CALL increment_counter('total_orders', 1);
    
    COMMIT;
    
    -- Release lock
    CALL release_distributed_lock(lock_name, CONNECTION_ID());
END//

DELIMITER ;

-- Galera-specific configuration recommendations
-- Add these to your MariaDB configuration:

/*
[galera]
wsrep_provider = /usr/lib/galera/libgalera_smm.so
wsrep_cluster_address = gcomm://node1,node2,node3
wsrep_node_name = node1
wsrep_node_address = 192.168.1.101
wsrep_sst_method = rsync
wsrep_cluster_name = ecommerce_cluster

# Optimizations for e-commerce workload
wsrep_slave_threads = 4
wsrep_certify_nonPK = 1
wsrep_max_ws_rows = 0
wsrep_max_ws_size = 2147483647
wsrep_debug = 0
wsrep_convert_LOCK_to_trx = 0
wsrep_retry_autocommit = 1
wsrep_auto_increment_control = 1
wsrep_drupal_282555_workaround = 0
wsrep_causal_reads = 0
wsrep_notify_cmd = 

[mysql]
binlog_format = ROW
default_storage_engine = InnoDB
innodb_locks_unsafe_for_binlog = 1
innodb_autoinc_lock_mode = 2
*/

-- Features optimized for Galera Cluster:
-- 1. BIGINT primary keys to avoid auto-increment conflicts
-- 2. Version columns for optimistic locking
-- 3. Node ID tracking for debugging
-- 4. Distributed locking mechanism
-- 5. Conflict-safe counter updates
-- 6. Retry logic in stored procedures
-- 7. Proper foreign key constraints
-- 8. Optimized for parallel replication
-- 9. Minimal write conflicts design
-- 10. Appropriate auto-increment offsets