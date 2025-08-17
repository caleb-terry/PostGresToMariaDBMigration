-- Sample data for PostgreSQL E-Commerce Platform
-- This creates realistic e-commerce data with ~50,000 records

-- Insert users (customers, vendors, admins)
INSERT INTO users (email, username, password_hash, role, first_name, last_name, phone, date_of_birth, gender, preferences, settings, loyalty_points) VALUES
('admin@ecommerce.com', 'admin', '$2a$10$YS8Uw6L8kO.lN0RJKnCkVeQLxGZ4KqwvY6xb0rcD5QD9pKHamOWKe', 'admin', 'System', 'Administrator', '+1-555-0001', '1980-01-01', 'other', '{"notifications": true}', '{"theme": "dark"}', 0),
('vendor1@example.com', 'techstore', '$2a$10$YS8Uw6L8kO.lN0RJKnCkVeQLxGZ4KqwvY6xb0rcD5QD9pKHamOWKe', 'vendor', 'John', 'Smith', '+1-555-0002', '1975-05-15', 'male', '{"product_alerts": true}', '{"dashboard": "extended"}', 0),
('vendor2@example.com', 'fashionhub', '$2a$10$YS8Uw6L8kO.lN0RJKnCkVeQLxGZ4KqwvY6xb0rcD5QD9pKHamOWKe', 'vendor', 'Sarah', 'Johnson', '+1-555-0003', '1982-08-20', 'female', '{"seasonal_trends": true}', '{"inventory_alerts": true}', 0),
('vendor3@example.com', 'homeessentials', '$2a$10$YS8Uw6L8kO.lN0RJKnCkVeQLxGZ4KqwvY6xb0rcD5QD9pKHamOWKe', 'vendor', 'Mike', 'Davis', '+1-555-0004', '1978-03-10', 'male', '{"bulk_orders": true}', '{}', 0),
('customer1@example.com', 'john_doe', '$2a$10$YS8Uw6L8kO.lN0RJKnCkVeQLxGZ4KqwvY6xb0rcD5QD9pKHamOWKe', 'customer', 'John', 'Doe', '+1-555-1001', '1990-06-15', 'male', '{"email_offers": true, "sms_alerts": false}', '{"currency": "USD", "language": "en"}', 150),
('customer2@example.com', 'jane_smith', '$2a$10$YS8Uw6L8kO.lN0RJKnCkVeQLxGZ4KqwvY6xb0rcD5QD9pKHamOWKe', 'customer', 'Jane', 'Smith', '+1-555-1002', '1988-09-22', 'female', '{"email_offers": true, "sms_alerts": true}', '{"currency": "USD", "theme": "light"}', 320),
('customer3@example.com', 'bob_wilson', '$2a$10$YS8Uw6L8kO.lN0RJKnCkVeQLxGZ4KqwvY6xb0rcD5QD9pKHamOWKe', 'customer', 'Bob', 'Wilson', '+1-555-1003', '1992-12-03', 'male', '{"email_offers": false}', '{}', 75),
('customer4@example.com', 'alice_brown', '$2a$10$YS8Uw6L8kO.lN0RJKnCkVeQLxGZ4KqwvY6xb0rcD5QD9pKHamOWKe', 'customer', 'Alice', 'Brown', '+1-555-1004', '1985-04-18', 'female', '{"email_offers": true, "product_recommendations": true}', '{"wishlist_public": false}', 480),
('customer5@example.com', 'charlie_green', '$2a$10$YS8Uw6L8kO.lN0RJKnCkVeQLxGZ4KqwvY6xb0rcD5QD9pKHamOWKe', 'customer', 'Charlie', 'Green', '+1-555-1005', '1995-11-30', 'non-binary', '{"sustainability_focus": true}', '{}', 200);

-- Generate additional customers (for volume)
DO $$
DECLARE
    i INTEGER;
    email_addr TEXT;
    username_val TEXT;
    first_names TEXT[] := ARRAY['Alex', 'Taylor', 'Jordan', 'Casey', 'Morgan', 'Avery', 'Riley', 'Sage', 'Quinn', 'Rowan'];
    last_names TEXT[] := ARRAY['Anderson', 'Brown', 'Clark', 'Davis', 'Evans', 'Fisher', 'Garcia', 'Harris', 'Johnson', 'Miller'];
BEGIN
    FOR i IN 1..1000 LOOP
        email_addr := 'user' || i || '@example.com';
        username_val := 'user' || i;
        
        INSERT INTO users (email, username, password_hash, role, first_name, last_name, phone, preferences, loyalty_points) 
        VALUES (
            email_addr,
            username_val,
            '$2a$10$YS8Uw6L8kO.lN0RJKnCkVeQLxGZ4KqwvY6xb0rcD5QD9pKHamOWKe',
            'customer',
            first_names[1 + (i % 10)],
            last_names[1 + (i % 10)],
            '+1-555-' || LPAD(i::TEXT, 4, '0'),
            '{"email_offers": ' || (CASE WHEN i % 2 = 0 THEN 'true' ELSE 'false' END) || '}',
            (random() * 500)::INTEGER
        );
    END LOOP;
END $$;

-- Insert vendors
INSERT INTO vendors (user_id, business_name, business_type, business_registration, tax_id, description, commission_rate, is_verified, total_sales, rating) VALUES
(2, 'TechStore Pro', 'Electronics Retailer', 'REG-001-2020', 'TAX-001', 'Premium electronics and gadgets for tech enthusiasts', 8.5, true, 125000.00, 4.7),
(3, 'Fashion Hub', 'Clothing Retailer', 'REG-002-2019', 'TAX-002', 'Trendy fashion for all ages and styles', 12.0, true, 89000.00, 4.3),
(4, 'Home Essentials', 'Home & Garden', 'REG-003-2021', 'TAX-003', 'Everything you need for your home and garden', 10.0, true, 67000.00, 4.5);

-- Insert categories with hierarchy
INSERT INTO categories (name, slug, description, parent_id, level, path) VALUES
('Electronics', 'electronics', 'Electronic devices and accessories', NULL, 0, '1'),
('Computers', 'computers', 'Desktop and laptop computers', 1, 1, '1.2'),
('Laptops', 'laptops', 'Portable computers', 2, 2, '1.2.3'),
('Desktop PCs', 'desktop-pcs', 'Desktop computers and workstations', 2, 2, '1.2.4'),
('Mobile Devices', 'mobile-devices', 'Smartphones and tablets', 1, 1, '1.5'),
('Smartphones', 'smartphones', 'Mobile phones', 5, 2, '1.5.6'),
('Tablets', 'tablets', 'Tablet computers', 5, 2, '1.5.7'),
('Audio', 'audio', 'Audio equipment and accessories', 1, 1, '1.8'),
('Headphones', 'headphones', 'Over-ear and in-ear headphones', 8, 2, '1.8.9'),
('Speakers', 'speakers', 'Bluetooth and wired speakers', 8, 2, '1.8.10'),

('Fashion', 'fashion', 'Clothing and accessories', NULL, 0, '11'),
('Men''s Clothing', 'mens-clothing', 'Clothing for men', 11, 1, '11.12'),
('Women''s Clothing', 'womens-clothing', 'Clothing for women', 11, 1, '11.13'),
('Shoes', 'shoes', 'Footwear for all', 11, 1, '11.14'),
('Accessories', 'accessories', 'Fashion accessories', 11, 1, '11.15'),

('Home & Garden', 'home-garden', 'Home improvement and garden supplies', NULL, 0, '16'),
('Furniture', 'furniture', 'Indoor and outdoor furniture', 16, 1, '16.17'),
('Kitchen', 'kitchen', 'Kitchen appliances and tools', 16, 1, '16.18'),
('Garden', 'garden', 'Gardening tools and supplies', 16, 1, '16.19'),
('Decor', 'decor', 'Home decoration items', 16, 1, '16.20');

-- Insert brands
INSERT INTO brands (name, slug, description) VALUES
('Apple', 'apple', 'Innovative technology products'),
('Samsung', 'samsung', 'Leading electronics manufacturer'),
('Dell', 'dell', 'Computer technology solutions'),
('HP', 'hp', 'Personal computing and printing'),
('Sony', 'sony', 'Entertainment and electronics'),
('Nike', 'nike', 'Athletic footwear and apparel'),
('Adidas', 'adidas', 'Sports clothing and accessories'),
('IKEA', 'ikea', 'Modern furniture and home goods'),
('KitchenAid', 'kitchenaid', 'Premium kitchen appliances'),
('Generic', 'generic', 'Quality products at great prices');

-- Insert products with complex data
INSERT INTO products (vendor_id, category_id, brand_id, sku, name, slug, description, short_description, specifications, features, tags, status, base_price, sale_price, weight, dimensions, stock_quantity, rating, review_count, view_count) VALUES
(1, 3, 1, 'APPLE-MBP-M2-13', 'MacBook Pro 13" M2 Chip', 'macbook-pro-13-m2', 'The new MacBook Pro with M2 chip delivers exceptional performance and battery life.', 'MacBook Pro 13" with M2 chip, 8GB RAM, 256GB SSD', '{"processor": "Apple M2", "ram": "8GB", "storage": "256GB SSD", "display": "13.3 inch Retina", "battery": "Up to 20 hours"}', ARRAY['M2 chip', 'Retina display', 'Touch Bar', 'Magic Keyboard'], ARRAY['laptop', 'apple', 'macbook', 'professional'], 'active', 1299.00, NULL, 1400, '{"length": 30.41, "width": 21.24, "height": 1.56}', 25, 4.8, 156, 2847),

(1, 6, 2, 'SAMSUNG-S23-ULTRA', 'Samsung Galaxy S23 Ultra', 'samsung-galaxy-s23-ultra', 'Premium smartphone with advanced camera system and S Pen.', 'Galaxy S23 Ultra with 256GB storage and S Pen', '{"display": "6.8 inch Dynamic AMOLED", "storage": "256GB", "ram": "12GB", "camera": "200MP main", "battery": "5000mAh"}', ARRAY['S Pen included', '200MP camera', '5G ready', 'Water resistant'], ARRAY['smartphone', 'samsung', 'android', '5g'], 'active', 1199.99, 999.99, 234, '{"length": 16.39, "width": 7.81, "height": 0.89}', 45, 4.6, 203, 3254),

(1, 9, 3, 'DELL-XPS-13-2023', 'Dell XPS 13 Laptop', 'dell-xps-13-2023', 'Ultra-portable laptop with stunning InfinityEdge display.', 'Dell XPS 13 with Intel i7, 16GB RAM, 512GB SSD', '{"processor": "Intel Core i7-1360P", "ram": "16GB", "storage": "512GB SSD", "display": "13.4 inch FHD+", "weight": "2.59 lbs"}', ARRAY['InfinityEdge display', 'Premium materials', 'Fast charging', 'Thunderbolt 4'], ARRAY['laptop', 'dell', 'ultrabook', 'business'], 'active', 1399.99, NULL, 1170, '{"length": 29.57, "width": 19.86, "height": 1.58}', 18, 4.5, 89, 1876),

(2, 12, 6, 'NIKE-AIR-MAX-270', 'Nike Air Max 270', 'nike-air-max-270-black', 'Comfortable running shoes with Max Air cushioning.', 'Nike Air Max 270 in Black/White colorway', '{"material": "Mesh and synthetic", "sole": "Rubber", "cushioning": "Max Air", "closure": "Lace-up"}', ARRAY['Max Air cushioning', 'Breathable mesh', 'Durable outsole', 'Iconic design'], ARRAY['shoes', 'nike', 'running', 'casual'], 'active', 150.00, 120.00, 850, '{"length": 32, "width": 12, "height": 11}', 120, 4.4, 312, 4567),

(2, 13, 7, 'ADIDAS-WOMENS-TEE', 'Adidas Women''s Training T-Shirt', 'adidas-womens-training-tee', 'Moisture-wicking t-shirt perfect for workouts.', 'Comfortable training t-shirt with Climalite technology', '{"material": "100% Polyester", "technology": "Climalite", "fit": "Regular", "care": "Machine washable"}', ARRAY['Moisture-wicking', 'Quick-dry', 'Comfortable fit', 'Breathable fabric'], ARRAY['clothing', 'adidas', 'women', 'fitness'], 'active', 35.00, NULL, 180, '{"length": 65, "width": 50, "height": 2}', 200, 4.2, 87, 1234),

(3, 17, 8, 'IKEA-HEMNES-DRESSER', 'HEMNES 8-drawer dresser', 'ikea-hemnes-8-drawer-dresser', 'Spacious dresser with 8 drawers in white stain.', 'Classic dresser with ample storage space', '{"material": "Solid pine", "color": "White stain", "dimensions": "160x96x50 cm", "drawers": 8}', ARRAY['Solid wood', 'Smooth-running drawers', 'Classic design', 'Easy assembly'], ARRAY['furniture', 'dresser', 'bedroom', 'storage'], 'active', 299.99, NULL, 45000, '{"length": 160, "width": 50, "height": 96}', 8, 4.3, 156, 2341),

(3, 18, 9, 'KITCHENAID-MIXER-5QT', 'KitchenAid 5-Qt Stand Mixer', 'kitchenaid-artisan-5qt-mixer', 'Professional-grade stand mixer for home baking.', 'Artisan Series 5-Quart Stand Mixer in Empire Red', '{"capacity": "5 quarts", "motor": "325 watts", "speeds": 10, "attachments": "Included"}', ARRAY['10 speeds', 'Tilt-head design', 'Dishwasher-safe bowl', 'Multiple attachments'], ARRAY['kitchen', 'mixer', 'baking', 'appliance'], 'active', 449.99, 399.99, 10886, '{"length": 36, "width": 22, "height": 35}', 15, 4.7, 234, 3456);

-- Generate more products for volume
DO $$
DECLARE
    i INTEGER;
    vendor_id_val INTEGER;
    category_id_val INTEGER;
    brand_id_val INTEGER;
    base_price_val DECIMAL;
    product_names TEXT[] := ARRAY[
        'Wireless Earbuds Pro', 'Smart Fitness Watch', 'Portable Charger', 'Bluetooth Speaker',
        'Gaming Mouse', 'Mechanical Keyboard', 'USB-C Hub', '4K Webcam',
        'Casual T-Shirt', 'Denim Jeans', 'Hooded Sweatshirt', 'Running Shorts',
        'Coffee Maker', 'Blender Pro', 'Air Fryer', 'Vacuum Cleaner'
    ];
BEGIN
    FOR i IN 1..500 LOOP
        vendor_id_val := 1 + (i % 3);
        category_id_val := 3 + (i % 17);
        brand_id_val := CASE WHEN i % 5 = 0 THEN NULL ELSE 1 + (i % 10) END;
        base_price_val := (random() * 500 + 20)::DECIMAL(10,2);
        
        INSERT INTO products (vendor_id, category_id, brand_id, sku, name, slug, description, short_description, status, base_price, stock_quantity, rating, review_count, view_count, tags, features) 
        VALUES (
            vendor_id_val,
            category_id_val,
            brand_id_val,
            'SKU-' || LPAD(i::TEXT, 6, '0'),
            product_names[1 + (i % array_length(product_names, 1))] || ' ' || i,
            'product-' || i,
            'High-quality product designed for everyday use and maximum satisfaction.',
            'Quality product #' || i,
            'active',
            base_price_val,
            (random() * 100 + 1)::INTEGER,
            (random() * 2 + 3)::DECIMAL(3,2),
            (random() * 50 + 5)::INTEGER,
            (random() * 1000 + 100)::INTEGER,
            ARRAY['product', 'quality', 'popular'],
            ARRAY['High quality', 'Durable', 'Great value']
        );
    END LOOP;
END $$;

-- Insert product variants
INSERT INTO product_variants (product_id, sku, attributes, price_adjustment, stock_quantity) VALUES
(4, 'NIKE-AIR-MAX-270-8', '{"size": "8", "color": "Black/White"}', 0.00, 15),
(4, 'NIKE-AIR-MAX-270-9', '{"size": "9", "color": "Black/White"}', 0.00, 20),
(4, 'NIKE-AIR-MAX-270-10', '{"size": "10", "color": "Black/White"}', 0.00, 25),
(4, 'NIKE-AIR-MAX-270-11', '{"size": "11", "color": "Black/White"}', 0.00, 18),
(5, 'ADIDAS-TEE-S', '{"size": "S", "color": "Black"}', 0.00, 50),
(5, 'ADIDAS-TEE-M', '{"size": "M", "color": "Black"}', 0.00, 75),
(5, 'ADIDAS-TEE-L', '{"size": "L", "color": "Black"}', 0.00, 60),
(5, 'ADIDAS-TEE-XL', '{"size": "XL", "color": "Black"}', 0.00, 45);

-- Insert customer addresses
INSERT INTO addresses (user_id, type, first_name, last_name, address_line1, city, state, postal_code, country, is_default) VALUES
(5, 'shipping', 'John', 'Doe', '123 Main Street', 'New York', 'NY', '10001', 'US', true),
(5, 'billing', 'John', 'Doe', '123 Main Street', 'New York', 'NY', '10001', 'US', true),
(6, 'shipping', 'Jane', 'Smith', '456 Oak Avenue', 'Los Angeles', 'CA', '90210', 'US', true),
(7, 'shipping', 'Bob', 'Wilson', '789 Pine Road', 'Chicago', 'IL', '60601', 'US', true),
(8, 'shipping', 'Alice', 'Brown', '321 Elm Street', 'Houston', 'TX', '77001', 'US', true);

-- Insert shopping carts
INSERT INTO carts (user_id, subtotal, tax_amount, total_amount) VALUES
(5, 1449.99, 116.00, 1565.99),
(6, 270.00, 21.60, 291.60),
(7, 449.99, 36.00, 485.99);

-- Insert cart items
INSERT INTO cart_items (cart_id, product_id, variant_id, quantity, unit_price, total_price) VALUES
(1, 1, NULL, 1, 1299.00, 1299.00),
(1, 4, 1, 1, 150.00, 150.00),
(2, 4, 2, 1, 150.00, 150.00),
(2, 5, 6, 2, 35.00, 70.00),
(2, 7, NULL, 1, 449.99, 449.99);

-- Insert coupons
INSERT INTO coupons (code, name, description, type, value, minimum_amount, usage_limit, valid_until) VALUES
('WELCOME10', 'Welcome Discount', '10% off your first order', 'percentage', 10.00, 50.00, 1000, '2024-12-31 23:59:59'),
('SUMMER25', 'Summer Sale', '$25 off orders over $100', 'fixed_amount', 25.00, 100.00, 500, '2024-08-31 23:59:59'),
('FREESHIP', 'Free Shipping', 'Free shipping on any order', 'free_shipping', 0.00, 0.00, NULL, '2024-12-31 23:59:59'),
('TECH15', 'Tech Discount', '15% off electronics', 'percentage', 15.00, 200.00, 200, '2024-09-30 23:59:59');

-- Generate orders and order items
DO $$
DECLARE
    i INTEGER;
    order_id_val INTEGER;
    user_id_val INTEGER;
    order_number_val VARCHAR(20);
    total_val DECIMAL(10,2);
    status_options order_status[] := ARRAY['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
    payment_status_options payment_status[] := ARRAY['pending', 'completed', 'failed'];
BEGIN
    FOR i IN 1..1000 LOOP
        user_id_val := CASE WHEN i % 10 = 0 THEN NULL ELSE 5 + (i % 1000) END;
        order_number_val := 'ORD-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(i::TEXT, 6, '0');
        total_val := (random() * 500 + 25)::DECIMAL(10,2);
        
        INSERT INTO orders (
            order_number, user_id, status, payment_status, subtotal, tax_amount, 
            total_amount, billing_address, shipping_address, created_at
        ) VALUES (
            order_number_val,
            user_id_val,
            status_options[1 + (random() * array_length(status_options, 1))::INTEGER],
            payment_status_options[1 + (random() * array_length(payment_status_options, 1))::INTEGER],
            total_val,
            (total_val * 0.08)::DECIMAL(10,2),
            (total_val * 1.08)::DECIMAL(10,2),
            '{"first_name": "Customer", "last_name": "Name", "address_line1": "123 Street", "city": "City", "state": "ST", "postal_code": "12345", "country": "US"}',
            '{"first_name": "Customer", "last_name": "Name", "address_line1": "123 Street", "city": "City", "state": "ST", "postal_code": "12345", "country": "US"}',
            NOW() - (random() * INTERVAL '90 days')
        ) RETURNING id INTO order_id_val;
        
        -- Insert 1-5 order items per order
        FOR j IN 1..(1 + random() * 4)::INTEGER LOOP
            INSERT INTO order_items (
                order_id, product_id, vendor_id, product_snapshot, quantity, unit_price, total_price
            ) VALUES (
                order_id_val,
                1 + (random() * 507)::INTEGER,
                1 + (random() * 3)::INTEGER,
                '{"name": "Product Name", "sku": "SKU-123", "price": 99.99}',
                1 + (random() * 3)::INTEGER,
                (random() * 200 + 10)::DECIMAL(10,2),
                (random() * 200 + 10)::DECIMAL(10,2)
            );
        END LOOP;
    END LOOP;
END $$;

-- Insert product reviews
INSERT INTO reviews (product_id, user_id, rating, title, content, verified_purchase, helpful_votes) VALUES
(1, 5, 5, 'Amazing laptop!', 'The MacBook Pro M2 is incredibly fast and the battery life is outstanding. Perfect for my development work.', true, 23),
(1, 6, 4, 'Great performance', 'Love the speed and display quality. Only wish it had more ports.', true, 12),
(2, 7, 5, 'Best phone ever', 'The camera quality is unbelievable and the S Pen is so useful for taking notes.', true, 45),
(2, 8, 4, 'Solid upgrade', 'Coming from S21, this is a nice improvement. Battery life could be better.', true, 8),
(4, 5, 4, 'Comfortable shoes', 'Great for daily wear and running. True to size and very comfortable.', true, 15),
(4, 9, 5, 'Love these!', 'Bought them for my workouts and they are perfect. Great cushioning.', true, 22);

-- Generate more reviews for volume
DO $$
DECLARE
    i INTEGER;
    product_id_val INTEGER;
    user_id_val INTEGER;
    rating_val INTEGER;
    titles TEXT[] := ARRAY['Great product', 'Love it', 'Good value', 'Recommended', 'Excellent quality', 'Perfect', 'Amazing', 'Satisfied'];
    contents TEXT[] := ARRAY[
        'Really happy with this purchase. Good quality and fast shipping.',
        'Exactly what I was looking for. Would buy again.',
        'Great value for money. Highly recommended.',
        'Product arrived quickly and works perfectly.',
        'Excellent quality and great customer service.'
    ];
BEGIN
    FOR i IN 1..2000 LOOP
        product_id_val := 1 + (random() * 507)::INTEGER;
        user_id_val := 5 + (random() * 1000)::INTEGER;
        rating_val := 3 + (random() * 3)::INTEGER; -- Ratings between 3-5
        
        INSERT INTO reviews (product_id, user_id, rating, title, content, verified_purchase, helpful_votes, created_at) 
        VALUES (
            product_id_val,
            user_id_val,
            rating_val,
            titles[1 + (random() * array_length(titles, 1))::INTEGER],
            contents[1 + (random() * array_length(contents, 1))::INTEGER],
            random() < 0.7, -- 70% verified purchases
            (random() * 50)::INTEGER,
            NOW() - (random() * INTERVAL '180 days')
        ) ON CONFLICT (product_id, user_id) DO NOTHING;
    END LOOP;
END $$;

-- Insert wishlists
INSERT INTO wishlists (user_id, name, description) VALUES
(5, 'My Wishlist', 'Items I want to buy later'),
(6, 'Birthday Wishlist', 'Things I want for my birthday'),
(8, 'Home Improvement', 'Items for renovating my house');

-- Insert wishlist items
INSERT INTO wishlist_items (wishlist_id, product_id) VALUES
(1, 2), (1, 7), (1, 6),
(2, 1), (2, 4), 
(3, 6), (3, 7);

-- Insert price history
INSERT INTO price_history (product_id, old_price, new_price, change_type, created_at) VALUES
(2, 1199.99, 999.99, 'sale_start', NOW() - INTERVAL '7 days'),
(4, 150.00, 120.00, 'sale_start', NOW() - INTERVAL '14 days'),
(7, 449.99, 399.99, 'sale_start', NOW() - INTERVAL '3 days');

-- Insert search queries for analytics
INSERT INTO search_queries (user_id, session_id, query, results_count, clicked_product_id, created_at) VALUES
(5, 'session_001', 'macbook pro', 5, 1, NOW() - INTERVAL '1 hour'),
(6, 'session_002', 'nike shoes', 12, 4, NOW() - INTERVAL '2 hours'),
(7, 'session_003', 'kitchen mixer', 3, 7, NOW() - INTERVAL '30 minutes'),
(NULL, 'session_004', 'smartphone samsung', 8, 2, NOW() - INTERVAL '45 minutes');

-- Generate more search queries for analytics
DO $$
DECLARE
    i INTEGER;
    queries TEXT[] := ARRAY[
        'laptop', 'smartphone', 'headphones', 'shoes', 'clothing', 'furniture',
        'kitchen', 'electronics', 'fashion', 'home decor', 'apple', 'samsung',
        'nike', 'gaming', 'wireless', 'bluetooth', 'sale', 'discount'
    ];
BEGIN
    FOR i IN 1..5000 LOOP
        INSERT INTO search_queries (
            user_id, session_id, query, results_count, created_at
        ) VALUES (
            CASE WHEN random() < 0.7 THEN 5 + (random() * 1000)::INTEGER ELSE NULL END,
            'session_' || LPAD(i::TEXT, 6, '0'),
            queries[1 + (random() * array_length(queries, 1))::INTEGER],
            (random() * 50 + 1)::INTEGER,
            NOW() - (random() * INTERVAL '30 days')
        );
    END LOOP;
END $$;

-- Update user totals and last login
UPDATE users SET 
    last_login = NOW() - (random() * INTERVAL '7 days'),
    total_spent = (
        SELECT COALESCE(SUM(o.total_amount), 0)
        FROM orders o 
        WHERE o.user_id = users.id AND o.payment_status = 'completed'
    )
WHERE role = 'customer';

-- Update vendor totals
UPDATE vendors SET 
    total_sales = (
        SELECT COALESCE(SUM(oi.total_price), 0)
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.id
        WHERE oi.vendor_id = vendors.id AND o.payment_status = 'completed'
    );

-- Update product ratings
DO $$
DECLARE
    product_record RECORD;
BEGIN
    FOR product_record IN SELECT id FROM products LOOP
        PERFORM update_product_rating(product_record.id);
    END LOOP;
END $$;

-- Insert inventory movements
INSERT INTO inventory_movements (product_id, movement_type, quantity, reference_type, notes, created_by) VALUES
(1, 'in', 50, 'restock', 'Initial inventory', 2),
(2, 'in', 100, 'restock', 'Monthly restock', 2),
(3, 'in', 30, 'restock', 'New shipment', 2),
(4, 'in', 200, 'restock', 'Seasonal inventory', 3),
(1, 'out', 5, 'order', 'Sales orders', NULL),
(2, 'out', 15, 'order', 'Sales orders', NULL);

-- This data provides:
-- - 1000+ users (customers, vendors, admins)
-- - 500+ products across multiple categories
-- - 1000+ orders with realistic order items
-- - 2000+ product reviews
-- - Comprehensive e-commerce relationships
-- - Realistic pricing and inventory data
-- - Search analytics data
-- - Price history tracking
-- - Shopping cart and wishlist data