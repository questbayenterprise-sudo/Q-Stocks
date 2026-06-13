-- ============================================================
-- 1. DATABASE CREATION
-- ============================================================
-- Note: Run CREATE DATABASE separately if your environment requires it.
-- CREATE DATABASE broiler_mgmt_system;
-- \c broiler_mgmt_system;

-- Enable UUID and Crypto extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 2. INFRASTRUCTURE & SETTINGS
-- ============================================================

CREATE TABLE IF NOT EXISTS tbl_general_settings (
    id                INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shop_name         VARCHAR(100) DEFAULT 'Broiler Management System',
    currency_symbol   VARCHAR(5) DEFAULT '₹',
    enable_otp        BOOLEAN DEFAULT TRUE,
    low_stock_limit   NUMERIC(10,3) DEFAULT 5.000,
    decimal_places    INTEGER DEFAULT 2,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cities (
    id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name      VARCHAR(150) NOT NULL,
    state     VARCHAR(150) DEFAULT 'Tamil Nadu',
    latitude  DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_active BOOLEAN DEFAULT TRUE
);

-- ============================================================
-- 3. IDENTITY & ACCESS MANAGEMENT (Users, Roles, OTP)
-- ============================================================

CREATE TABLE IF NOT EXISTS roles (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name  VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username        VARCHAR(100) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    phoneno         VARCHAR(15),
    password_hash   TEXT, -- For login
    address         VARCHAR,
    city            VARCHAR,
    image_url       TEXT,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS otp_log (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    userid          INTEGER REFERENCES users(id) ON DELETE CASCADE,
    phoneno         VARCHAR(15),
    otp             VARCHAR(6) NOT NULL,
    is_verified     BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at      TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '10 minutes')
);

CREATE TABLE IF NOT EXISTS user_fcm_tokens (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token   TEXT NOT NULL,
    device_id   VARCHAR(255),
    platform    VARCHAR(20) DEFAULT 'android',
    UNIQUE(user_id, fcm_token)
);

-- ============================================================
-- 4. SHOP & MASTER DATA
-- ============================================================

CREATE TABLE IF NOT EXISTS payment_modes (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE, -- Cash, PhonePe, G-Pay, Credit/Debit Card
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS shops (
    id            INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    location      TEXT NOT NULL,
    city_id       INTEGER REFERENCES cities(id),
    contact_phone VARCHAR(20),
    is_active     BOOLEAN DEFAULT TRUE,
    created_by    INTEGER REFERENCES users(id),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS shop_user_mapping (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    shop_id    INTEGER NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    is_active  BOOLEAN DEFAULT TRUE
);

-- ============================================================
-- 5. PRODUCT & INVENTORY MANAGEMENT
-- ============================================================

CREATE TABLE IF NOT EXISTS categories (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(50) UNIQUE NOT NULL, -- Broiler, Country Chicken, Eggs
    image_url  TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
    id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id    INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    name           VARCHAR(100) NOT NULL,
    uom            VARCHAR(10) DEFAULT 'KG', -- Unit of Measure (KG, Pcs, Tray)
    base_price     NUMERIC(10,2) NOT NULL,
    is_active      BOOLEAN DEFAULT TRUE,
    image_url      TEXT,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Real-time stock for each shop
CREATE TABLE IF NOT EXISTS stocks (
    id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shop_id        INTEGER REFERENCES shops(id) ON DELETE CASCADE,
    product_id     INTEGER REFERENCES products(id) ON DELETE CASCADE,
    current_qty    NUMERIC(10,3) DEFAULT 0.000, -- 3 decimals for Grams
    min_stock_lvl  NUMERIC(10,3) DEFAULT 5.000,
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- History of stock movements (Sales, Purchases, Wastage)
CREATE TABLE IF NOT EXISTS stock_logs (
    id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stock_id       INTEGER REFERENCES stocks(id),
    change_qty     NUMERIC(10,3) NOT NULL,
    log_type       VARCHAR(20), -- 'IN' (Purchase), 'OUT' (Sale), 'WASTE' (Death/Damage)
    remarks        TEXT,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 6. CUSTOMERS & LEDGER (THE "NOTEBOOK" SYSTEM)
-- ============================================================

CREATE TABLE IF NOT EXISTS customers (
    id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name           VARCHAR(100) NOT NULL,
    phone          VARCHAR(15) UNIQUE,
    address        TEXT,
    opening_balance NUMERIC(10,2) DEFAULT 0,
    current_balance NUMERIC(10,2) DEFAULT 0, -- Balance as of today
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_ref       VARCHAR(20) UNIQUE,
    shop_id         INTEGER REFERENCES shops(id),
    customer_id     INTEGER REFERENCES customers(id),
    user_id         INTEGER REFERENCES users(id), -- Billed by
    paymode_id      INTEGER REFERENCES payment_modes(id),
    total_amount    NUMERIC(10,2) NOT NULL,
    paid_amount     NUMERIC(10,2) DEFAULT 0,
    balance_due     NUMERIC(10,2) DEFAULT 0,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
    id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id       INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    product_id     INTEGER REFERENCES products(id),
    weight         NUMERIC(10,3) NOT NULL, -- The 'Weight' col from sketch
    rate           NUMERIC(10,2) NOT NULL, -- The 'Rate' col from sketch
    sub_total      NUMERIC(10,2) NOT NULL  -- The 'Amount' col (Weight * Rate)
);

-- THE CUSTOMER LEDGER (Notebook History)
CREATE TABLE IF NOT EXISTS customer_ledger (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id     INTEGER NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    shop_id         INTEGER NOT NULL REFERENCES shops(id),
    order_id        INTEGER REFERENCES orders(id), -- Optional: Link to sale
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    weight          NUMERIC(10,3), -- Hand-written ledger compatibility
    rate            NUMERIC(10,2), -- Hand-written ledger compatibility
    debit_amount    NUMERIC(10,2) DEFAULT 0, -- Purchases
    credit_amount   NUMERIC(10,2) DEFAULT 0, -- Payments
    running_balance NUMERIC(10,2) NOT NULL,  -- Calculation: Prev + Debit - Credit
    paymode_id      INTEGER REFERENCES payment_modes(id),
    remarks         TEXT
);

-- ============================================================
-- 7. ENGAGEMENT & LOGS
-- ============================================================

CREATE TABLE IF NOT EXISTS notifications (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title       VARCHAR(255) NOT NULL,
    body        TEXT,
    is_read     BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Indexes for performance
CREATE INDEX idx_ledger_customer ON customer_ledger(customer_id);
CREATE INDEX idx_stocks_product ON stocks(product_id, shop_id);
CREATE INDEX idx_orders_customer ON orders(customer_id);
-- ============================================================
-- 9. SUPPLIER MANAGEMENT (The "Inward" side)
-- ============================================================

CREATE TABLE IF NOT EXISTS suppliers (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    phone           VARCHAR(15),
    address         TEXT,
    current_balance NUMERIC(10,2) DEFAULT 0, -- Money you owe the supplier
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS purchases (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_id     INTEGER REFERENCES suppliers(id),
    shop_id         INTEGER REFERENCES shops(id),
    total_qty       NUMERIC(10,3) NOT NULL, -- Total KG bought
    unit_price      NUMERIC(10,2) NOT NULL, -- Rate at which you bought
    total_amount    NUMERIC(10,2) NOT NULL,
    paid_amount     NUMERIC(10,2) DEFAULT 0,
    bill_image      TEXT, -- Photo of the supplier's bill
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 10. DAILY PRICE MASTER
-- ============================================================

CREATE TABLE IF NOT EXISTS daily_rates (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shop_id         INTEGER REFERENCES shops(id),
    product_id      INTEGER REFERENCES products(id),
    today_rate      NUMERIC(10,2) NOT NULL,
    effective_date  DATE DEFAULT CURRENT_DATE,
    UNIQUE(shop_id, product_id, effective_date)
);

-- ============================================================
-- 11. SHOP EXPENSES (For Profit/Loss Calculation)
-- ============================================================

CREATE TABLE IF NOT EXISTS expense_categories (
    id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name    VARCHAR(50) NOT NULL -- Rent, Salary, Feed, Electricity, Transport
);

CREATE TABLE IF NOT EXISTS expenses (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shop_id         INTEGER REFERENCES shops(id),
    category_id     INTEGER REFERENCES expense_categories(id),
    amount          NUMERIC(10,2) NOT NULL,
    expense_date    DATE DEFAULT CURRENT_DATE,
    remarks         TEXT,
    created_by      INTEGER REFERENCES users(id)
);
