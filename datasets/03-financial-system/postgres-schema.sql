-- PostgreSQL Schema for Financial System
-- This demonstrates the most advanced PostgreSQL features for enterprise financial applications

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "btree_gist";
CREATE EXTENSION IF NOT EXISTS "hstore";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Custom types for financial domain
CREATE TYPE account_type AS ENUM ('checking', 'savings', 'credit', 'loan', 'investment', 'business');
CREATE TYPE transaction_type AS ENUM ('debit', 'credit', 'transfer', 'fee', 'interest', 'dividend', 'penalty');
CREATE TYPE transaction_status AS ENUM ('pending', 'processing', 'completed', 'failed', 'cancelled', 'reversed');
CREATE TYPE currency_code AS ENUM ('USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY');
CREATE TYPE risk_level AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE compliance_status AS ENUM ('compliant', 'under_review', 'non_compliant', 'exempt');

-- Domains for financial data validation
CREATE DOMAIN money_amount AS NUMERIC(15,2) CHECK (VALUE >= -999999999999.99 AND VALUE <= 999999999999.99);
CREATE DOMAIN interest_rate AS NUMERIC(5,4) CHECK (VALUE >= 0 AND VALUE <= 1);
CREATE DOMAIN percentage AS NUMERIC(5,2) CHECK (VALUE >= 0 AND VALUE <= 100);
CREATE DOMAIN routing_number AS VARCHAR(9) CHECK (VALUE ~ '^[0-9]{9}$');
CREATE DOMAIN account_number AS VARCHAR(20) CHECK (VALUE ~ '^[0-9A-Z]+$');

-- Financial institutions
CREATE TABLE financial_institutions (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    legal_name VARCHAR(300) NOT NULL,
    institution_type VARCHAR(50) NOT NULL, -- 'bank', 'credit_union', 'investment_firm'
    routing_number routing_number UNIQUE,
    swift_code VARCHAR(11),
    federal_reserve_id VARCHAR(20),
    regulatory_authority VARCHAR(100),
    license_number VARCHAR(50),
    headquarters_address JSONB NOT NULL,
    operational_countries TEXT[],
    established_date DATE,
    assets_under_management money_amount,
    tier INTEGER CHECK (tier >= 1 AND tier <= 4), -- Basel III tier classification
    is_active BOOLEAN DEFAULT true,
    compliance_rating VARCHAR(10),
    last_audit_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Customers with enhanced KYC data
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    customer_number VARCHAR(20) UNIQUE NOT NULL,
    ssn_hash VARCHAR(64), -- Hashed SSN for privacy
    tax_id VARCHAR(20),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    date_of_birth DATE NOT NULL,
    nationality VARCHAR(3), -- ISO country code
    citizenship VARCHAR(3), -- ISO country code
    gender VARCHAR(10),
    marital_status VARCHAR(20),
    employment_status VARCHAR(50),
    annual_income money_amount,
    net_worth money_amount,
    risk_profile risk_level DEFAULT 'medium',
    kyc_status compliance_status DEFAULT 'under_review',
    kyc_completed_date DATE,
    kyc_expires_date DATE,
    pep_status BOOLEAN DEFAULT false, -- Politically Exposed Person
    sanctions_check_date DATE,
    sanctions_status compliance_status DEFAULT 'compliant',
    credit_score INTEGER CHECK (credit_score >= 300 AND credit_score <= 850),
    primary_phone VARCHAR(20),
    primary_email VARCHAR(255),
    preferred_language VARCHAR(10) DEFAULT 'en',
    communication_preferences JSONB DEFAULT '{}',
    identity_documents JSONB DEFAULT '[]', -- Array of document info
    addresses JSONB DEFAULT '[]', -- Array of addresses with history
    emergency_contact JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- Full-text search
    search_vector tsvector
);

-- Accounts with comprehensive tracking
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    institution_id INTEGER NOT NULL REFERENCES financial_institutions(id),
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    account_number account_number UNIQUE NOT NULL,
    account_type account_type NOT NULL,
    account_name VARCHAR(200),
    currency currency_code DEFAULT 'USD',
    balance money_amount DEFAULT 0.00,
    available_balance money_amount DEFAULT 0.00,
    pending_balance money_amount DEFAULT 0.00,
    overdraft_limit money_amount DEFAULT 0.00,
    credit_limit money_amount,
    minimum_balance money_amount DEFAULT 0.00,
    interest_rate interest_rate DEFAULT 0.0000,
    fee_schedule JSONB DEFAULT '{}',
    account_status VARCHAR(20) DEFAULT 'active', -- 'active', 'frozen', 'closed', 'dormant'
    opened_date DATE NOT NULL DEFAULT CURRENT_DATE,
    closed_date DATE,
    last_activity_date DATE,
    statement_cycle INTEGER DEFAULT 30, -- days
    last_statement_date DATE,
    routing_number routing_number,
    iban VARCHAR(34), -- International Bank Account Number
    branch_code VARCHAR(20),
    product_code VARCHAR(50),
    relationship_manager_id INTEGER,
    risk_rating risk_level DEFAULT 'low',
    compliance_flags TEXT[],
    monitoring_flags TEXT[],
    regulatory_reporting JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Transactions with comprehensive audit trail
CREATE TABLE transactions (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    from_account_id INTEGER REFERENCES accounts(id),
    to_account_id INTEGER REFERENCES accounts(id),
    transaction_type transaction_type NOT NULL,
    amount money_amount NOT NULL,
    currency currency_code NOT NULL DEFAULT 'USD',
    exchange_rate NUMERIC(12,6) DEFAULT 1.000000,
    base_amount money_amount, -- Amount in base currency
    fee_amount money_amount DEFAULT 0.00,
    description TEXT NOT NULL,
    reference_number VARCHAR(50) UNIQUE,
    external_reference VARCHAR(100),
    merchant_info JSONB,
    location_info JSONB, -- ATM/branch location, GPS coordinates
    channel VARCHAR(50), -- 'online', 'mobile', 'atm', 'branch', 'phone'
    device_info JSONB,
    ip_address INET,
    status transaction_status DEFAULT 'pending',
    posted_date DATE,
    value_date DATE, -- When funds become available
    authorization_code VARCHAR(20),
    batch_id VARCHAR(50),
    settlement_date DATE,
    reconciliation_status VARCHAR(20) DEFAULT 'pending',
    reversal_reason TEXT,
    reversed_transaction_id BIGINT REFERENCES transactions(id),
    parent_transaction_id BIGINT REFERENCES transactions(id), -- For related transactions
    risk_score NUMERIC(5,2),
    fraud_flags TEXT[],
    compliance_flags TEXT[],
    regulatory_codes TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE,
    -- Check constraints
    CONSTRAINT valid_transaction_accounts CHECK (
        (transaction_type IN ('debit', 'fee', 'interest') AND from_account_id IS NOT NULL) OR
        (transaction_type IN ('credit', 'dividend') AND to_account_id IS NOT NULL) OR
        (transaction_type = 'transfer' AND from_account_id IS NOT NULL AND to_account_id IS NOT NULL)
    ),
    CONSTRAINT positive_amount CHECK (amount > 0),
    CONSTRAINT valid_dates CHECK (posted_date IS NULL OR value_date IS NULL OR value_date >= posted_date)
);

-- Account balances with temporal tracking
CREATE TABLE account_balances (
    id BIGSERIAL PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES accounts(id),
    balance_date DATE NOT NULL,
    opening_balance money_amount NOT NULL,
    closing_balance money_amount NOT NULL,
    available_balance money_amount NOT NULL,
    pending_credits money_amount DEFAULT 0.00,
    pending_debits money_amount DEFAULT 0.00,
    interest_accrued money_amount DEFAULT 0.00,
    fees_charged money_amount DEFAULT 0.00,
    transaction_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(account_id, balance_date)
);

-- Interest rates with temporal validity
CREATE TABLE interest_rates (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    institution_id INTEGER NOT NULL REFERENCES financial_institutions(id),
    product_type VARCHAR(50) NOT NULL,
    account_type account_type NOT NULL,
    tier_min_balance money_amount DEFAULT 0.00,
    tier_max_balance money_amount,
    interest_rate interest_rate NOT NULL,
    apy percentage, -- Annual Percentage Yield
    compounding_frequency VARCHAR(20) DEFAULT 'monthly', -- 'daily', 'monthly', 'quarterly', 'annually'
    effective_date DATE NOT NULL,
    expiry_date DATE,
    is_promotional BOOLEAN DEFAULT false,
    promotional_period INTEGER, -- days
    conditions JSONB DEFAULT '{}',
    regulatory_approval_ref VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER
);

-- Loans and credit facilities
CREATE TABLE loans (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    institution_id INTEGER NOT NULL REFERENCES financial_institutions(id),
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    account_id INTEGER REFERENCES accounts(id),
    loan_number VARCHAR(30) UNIQUE NOT NULL,
    loan_type VARCHAR(50) NOT NULL, -- 'personal', 'mortgage', 'auto', 'business', 'line_of_credit'
    principal_amount money_amount NOT NULL,
    outstanding_balance money_amount NOT NULL,
    interest_rate interest_rate NOT NULL,
    term_months INTEGER,
    payment_frequency VARCHAR(20) DEFAULT 'monthly',
    payment_amount money_amount,
    next_payment_date DATE,
    maturity_date DATE,
    collateral_info JSONB,
    loan_purpose TEXT,
    credit_score_at_origination INTEGER,
    debt_to_income_ratio percentage,
    loan_to_value_ratio percentage,
    origination_date DATE NOT NULL,
    first_payment_date DATE,
    last_payment_date DATE,
    payments_made INTEGER DEFAULT 0,
    payments_remaining INTEGER,
    total_interest_paid money_amount DEFAULT 0.00,
    late_payment_count INTEGER DEFAULT 0,
    delinquency_status VARCHAR(20) DEFAULT 'current', -- 'current', '30_days', '60_days', '90_days', 'default'
    charge_off_date DATE,
    recovery_amount money_amount DEFAULT 0.00,
    loan_status VARCHAR(20) DEFAULT 'active', -- 'active', 'paid_off', 'charged_off', 'refinanced'
    underwriter_id INTEGER,
    approval_date DATE,
    risk_grade VARCHAR(10),
    regulatory_classification VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Investment portfolios
CREATE TABLE portfolios (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    account_id INTEGER REFERENCES accounts(id),
    portfolio_name VARCHAR(200) NOT NULL,
    portfolio_type VARCHAR(50), -- 'individual', 'joint', 'ira', '401k', 'trust'
    investment_objective VARCHAR(100),
    risk_tolerance risk_level DEFAULT 'medium',
    time_horizon_years INTEGER,
    total_value money_amount DEFAULT 0.00,
    cash_balance money_amount DEFAULT 0.00,
    invested_amount money_amount DEFAULT 0.00,
    unrealized_gain_loss money_amount DEFAULT 0.00,
    realized_gain_loss money_amount DEFAULT 0.00,
    dividend_income money_amount DEFAULT 0.00,
    management_fee_rate percentage DEFAULT 0.00,
    performance_benchmark VARCHAR(50),
    inception_date DATE NOT NULL,
    last_rebalance_date DATE,
    auto_rebalance BOOLEAN DEFAULT false,
    tax_lot_method VARCHAR(20) DEFAULT 'fifo', -- 'fifo', 'lifo', 'specific_id'
    portfolio_manager_id INTEGER,
    custodian_info JSONB,
    regulatory_account_type VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Securities master data
CREATE TABLE securities (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    symbol VARCHAR(20) UNIQUE NOT NULL,
    cusip VARCHAR(9) UNIQUE,
    isin VARCHAR(12) UNIQUE,
    sedol VARCHAR(7),
    security_name VARCHAR(200) NOT NULL,
    security_type VARCHAR(50) NOT NULL, -- 'stock', 'bond', 'etf', 'mutual_fund', 'option', 'future'
    asset_class VARCHAR(50), -- 'equity', 'fixed_income', 'commodity', 'currency', 'alternative'
    sector VARCHAR(100),
    industry VARCHAR(100),
    exchange VARCHAR(50),
    currency currency_code DEFAULT 'USD',
    country VARCHAR(3), -- ISO country code
    issuer_name VARCHAR(200),
    issue_date DATE,
    maturity_date DATE,
    coupon_rate percentage,
    par_value money_amount,
    dividend_frequency VARCHAR(20),
    last_dividend_amount money_amount,
    ex_dividend_date DATE,
    price_multiplier INTEGER DEFAULT 1,
    trading_status VARCHAR(20) DEFAULT 'active',
    delisting_date DATE,
    corporate_actions JSONB DEFAULT '[]',
    fundamentals JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Portfolio holdings
CREATE TABLE holdings (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    portfolio_id INTEGER NOT NULL REFERENCES portfolios(id),
    security_id INTEGER NOT NULL REFERENCES securities(id),
    quantity NUMERIC(15,6) NOT NULL,
    average_cost money_amount NOT NULL,
    current_price money_amount,
    market_value money_amount,
    unrealized_gain_loss money_amount,
    cost_basis money_amount,
    purchase_date DATE,
    last_price_update TIMESTAMP WITH TIME ZONE,
    allocation_percentage percentage,
    target_allocation percentage,
    rebalance_threshold percentage DEFAULT 5.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(portfolio_id, security_id)
);

-- Market data with time series
CREATE TABLE market_data (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id),
    price_date DATE NOT NULL,
    open_price money_amount,
    high_price money_amount,
    low_price money_amount,
    close_price money_amount NOT NULL,
    adjusted_close money_amount,
    volume BIGINT DEFAULT 0,
    vwap money_amount, -- Volume Weighted Average Price
    bid_price money_amount,
    ask_price money_amount,
    spread money_amount,
    market_cap BIGINT,
    pe_ratio NUMERIC(8,2),
    dividend_yield percentage,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(security_id, price_date)
);

-- Regulatory reporting
CREATE TABLE regulatory_reports (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    institution_id INTEGER NOT NULL REFERENCES financial_institutions(id),
    report_type VARCHAR(50) NOT NULL, -- 'ctr', 'sar', 'ofac', 'cra', 'call_report'
    reporting_period_start DATE NOT NULL,
    reporting_period_end DATE NOT NULL,
    report_data JSONB NOT NULL,
    regulatory_authority VARCHAR(100) NOT NULL,
    submission_deadline DATE NOT NULL,
    submitted_date DATE,
    submission_status VARCHAR(20) DEFAULT 'draft', -- 'draft', 'submitted', 'accepted', 'rejected'
    submission_reference VARCHAR(100),
    reviewer_id INTEGER,
    review_notes TEXT,
    amendments JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- AML/KYC monitoring
CREATE TABLE aml_alerts (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    customer_id INTEGER REFERENCES customers(id),
    account_id INTEGER REFERENCES accounts(id),
    transaction_id BIGINT REFERENCES transactions(id),
    alert_type VARCHAR(50) NOT NULL, -- 'unusual_activity', 'large_cash', 'structuring', 'sanctions_match'
    risk_score NUMERIC(5,2) NOT NULL,
    severity VARCHAR(20) NOT NULL, -- 'low', 'medium', 'high', 'critical'
    description TEXT NOT NULL,
    detection_rules JSONB,
    supporting_data JSONB,
    status VARCHAR(20) DEFAULT 'open', -- 'open', 'investigating', 'closed', 'escalated'
    assigned_to INTEGER,
    investigation_notes TEXT,
    resolution VARCHAR(50),
    closure_reason TEXT,
    escalated_to VARCHAR(100),
    regulatory_filing_required BOOLEAN DEFAULT false,
    sar_filed_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Audit trail
CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    operation VARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    record_id BIGINT NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_by INTEGER,
    change_reason TEXT,
    session_id VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    application VARCHAR(100),
    transaction_id BIGINT,
    compliance_required BOOLEAN DEFAULT false,
    retention_period INTEGER DEFAULT 2555, -- days (7 years)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create partitioned tables for time series data
CREATE TABLE transactions_2024 PARTITION OF transactions
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE transactions_2025 PARTITION OF transactions
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- Create indexes for performance
CREATE INDEX idx_customers_ssn_hash ON customers(ssn_hash);
CREATE INDEX idx_customers_kyc_status ON customers(kyc_status);
CREATE INDEX idx_customers_risk_profile ON customers(risk_profile);
CREATE INDEX idx_customers_search_vector ON customers USING GIN(search_vector);

CREATE INDEX idx_accounts_customer ON accounts(customer_id);
CREATE INDEX idx_accounts_institution ON accounts(institution_id);
CREATE INDEX idx_accounts_type_status ON accounts(account_type, account_status);
CREATE INDEX idx_accounts_balance ON accounts(balance);

CREATE INDEX idx_transactions_from_account ON transactions(from_account_id);
CREATE INDEX idx_transactions_to_account ON transactions(to_account_id);
CREATE INDEX idx_transactions_created_at ON transactions(created_at);
CREATE INDEX idx_transactions_amount ON transactions(amount);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_type ON transactions(transaction_type);
CREATE INDEX idx_transactions_reference ON transactions(reference_number);

CREATE INDEX idx_market_data_security_date ON market_data(security_id, price_date DESC);
CREATE INDEX idx_market_data_date ON market_data(price_date DESC);

CREATE INDEX idx_aml_alerts_customer ON aml_alerts(customer_id);
CREATE INDEX idx_aml_alerts_severity_status ON aml_alerts(severity, status);
CREATE INDEX idx_aml_alerts_created_at ON aml_alerts(created_at DESC);

-- GIN indexes for JSONB fields
CREATE INDEX idx_customers_addresses ON customers USING GIN(addresses);
CREATE INDEX idx_accounts_fee_schedule ON accounts USING GIN(fee_schedule);
CREATE INDEX idx_transactions_merchant_info ON transactions USING GIN(merchant_info);

-- Advanced functions for financial calculations

-- Calculate compound interest
CREATE OR REPLACE FUNCTION calculate_compound_interest(
    principal money_amount,
    annual_rate interest_rate,
    compounding_periods INTEGER,
    years INTEGER
) RETURNS money_amount AS $$
BEGIN
    RETURN principal * POWER(1 + annual_rate / compounding_periods, compounding_periods * years);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Calculate loan payment amount
CREATE OR REPLACE FUNCTION calculate_loan_payment(
    principal money_amount,
    annual_rate interest_rate,
    term_months INTEGER
) RETURNS money_amount AS $$
DECLARE
    monthly_rate NUMERIC;
BEGIN
    IF annual_rate = 0 THEN
        RETURN principal / term_months;
    END IF;
    
    monthly_rate := annual_rate / 12;
    RETURN principal * (monthly_rate * POWER(1 + monthly_rate, term_months)) / 
           (POWER(1 + monthly_rate, term_months) - 1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Update customer search vector
CREATE OR REPLACE FUNCTION update_customer_search_vector() RETURNS trigger AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.first_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.last_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.customer_number, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.primary_email, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(NEW.tax_id, '')), 'D');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger_function() RETURNS trigger AS $$
DECLARE
    audit_row audit_log%ROWTYPE;
BEGIN
    audit_row.table_name := TG_TABLE_NAME;
    audit_row.operation := TG_OP;
    audit_row.changed_by := current_setting('app.current_user_id', true)::INTEGER;
    audit_row.session_id := current_setting('app.session_id', true);
    
    IF TG_OP = 'DELETE' THEN
        audit_row.record_id := OLD.id;
        audit_row.old_values := row_to_json(OLD);
        INSERT INTO audit_log SELECT audit_row.*;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        audit_row.record_id := NEW.id;
        audit_row.old_values := row_to_json(OLD);
        audit_row.new_values := row_to_json(NEW);
        INSERT INTO audit_log SELECT audit_row.*;
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        audit_row.record_id := NEW.id;
        audit_row.new_values := row_to_json(NEW);
        INSERT INTO audit_log SELECT audit_row.*;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER update_customer_search_vector_trigger
    BEFORE INSERT OR UPDATE OF first_name, last_name, customer_number, primary_email, tax_id
    ON customers FOR EACH ROW
    EXECUTE FUNCTION update_customer_search_vector();

-- Audit triggers for critical tables
CREATE TRIGGER customers_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON customers
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER accounts_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON accounts
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER transactions_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON transactions
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Views for common financial reports

-- Customer portfolio summary
CREATE VIEW customer_portfolio_summary AS
SELECT 
    c.id as customer_id,
    c.customer_number,
    c.first_name || ' ' || c.last_name as customer_name,
    COUNT(DISTINCT a.id) as account_count,
    COUNT(DISTINCT p.id) as portfolio_count,
    SUM(a.balance) as total_deposits,
    SUM(p.total_value) as total_investments,
    SUM(a.balance) + COALESCE(SUM(p.total_value), 0) as total_assets,
    COALESCE(SUM(l.outstanding_balance), 0) as total_liabilities,
    (SUM(a.balance) + COALESCE(SUM(p.total_value), 0)) - COALESCE(SUM(l.outstanding_balance), 0) as net_worth
FROM customers c
LEFT JOIN accounts a ON c.id = a.customer_id AND a.account_status = 'active'
LEFT JOIN portfolios p ON c.id = p.customer_id
LEFT JOIN loans l ON c.id = l.customer_id AND l.loan_status = 'active'
WHERE c.is_active = true
GROUP BY c.id, c.customer_number, c.first_name, c.last_name;

-- Daily transaction summary
CREATE VIEW daily_transaction_summary AS
SELECT 
    DATE(created_at) as transaction_date,
    transaction_type,
    currency,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount,
    AVG(amount) as average_amount,
    MIN(amount) as min_amount,
    MAX(amount) as max_amount
FROM transactions
WHERE status = 'completed'
GROUP BY DATE(created_at), transaction_type, currency
ORDER BY transaction_date DESC, transaction_type;

-- Risk monitoring view
CREATE VIEW high_risk_customers AS
SELECT 
    c.*,
    COUNT(aa.id) as alert_count,
    MAX(aa.risk_score) as max_risk_score,
    STRING_AGG(DISTINCT aa.alert_type, ', ') as alert_types
FROM customers c
JOIN aml_alerts aa ON c.id = aa.customer_id
WHERE aa.status IN ('open', 'investigating')
  AND aa.severity IN ('high', 'critical')
GROUP BY c.id
HAVING COUNT(aa.id) > 0
ORDER BY max_risk_score DESC, alert_count DESC;

-- This schema demonstrates the most advanced PostgreSQL features:
-- 1. Complex custom types and domains for financial data
-- 2. Extensive JSONB usage for flexible financial data
-- 3. Temporal data modeling with partitioning
-- 4. Advanced audit logging and compliance tracking
-- 5. Financial calculation functions
-- 6. Comprehensive indexing strategies
-- 7. Risk monitoring and regulatory reporting
-- 8. Full-text search for customer data
-- 9. Time series market data
-- 10. Complex constraint validation