-- ============================================================
-- BROILER MGMT SYSTEM: POSTGRESQL INITIALIZATION
-- ============================================================

-- Enable pgcrypto for password hashing or UUIDs if needed
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. INFRASTRUCTURE & SETTINGS
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

-- 2. IDENTITY (Users & Roles)
CREATE TABLE IF NOT EXISTS roles (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name  VARCHAR(50) UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS users (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username        VARCHAR(100) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    phoneno         VARCHAR(20),
    password_hash   TEXT,
    address         TEXT,
    city            VARCHAR(100),
    image_url       TEXT,
    -- In Postgres, use BOOLEAN (True/False) instead of INTEGER (0/1)
    is_active       BOOLEAN DEFAULT TRUE, 
    -- Use TIMESTAMP instead of DATETIME
    retry_cnt_lmt       INTEGER DEFAULT 5, 
    retrycnt_updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- RECOMMENDATION: Add an index on role_id
-- Postgres automatically creates an index for the PRIMARY KEY (user_id, role_id).
-- But if you ever want to "find all users who are Admins", you need this index:
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON user_roles(role_id);

CREATE TABLE IF NOT EXISTS otp_log (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    userid          INTEGER REFERENCES users(id) ON DELETE CASCADE,
    phoneno         VARCHAR(15),
    otp             VARCHAR(6) NOT NULL,
    is_verified     BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at      TIMESTAMP NOT NULL,
    verified_at     TIMESTAMP
);

-- 3. SHOP & MASTERS
CREATE TABLE IF NOT EXISTS payment_modes (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE,
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS shops (
    id            INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    location      TEXT NOT NULL,
    city_id       INTEGER REFERENCES cities(id),
    contact_phone VARCHAR(20),
         description   TEXT,   
                  image_url TEXT,   

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

-- 4. PRODUCTS & INVENTORY
CREATE TABLE IF NOT EXISTS categories (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(50) UNIQUE NOT NULL,
    image_url  TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
    id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id    INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    name           VARCHAR(100) NOT NULL,
    uom            VARCHAR(10) DEFAULT 'KG',
    base_price     NUMERIC(10,2) NOT NULL,
    is_active      BOOLEAN DEFAULT TRUE,
    image_url      TEXT,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stocks (
    id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shop_id        INTEGER REFERENCES shops(id) ON DELETE CASCADE,
    product_id     INTEGER REFERENCES products(id) ON DELETE CASCADE,
    current_qty    NUMERIC(10,3) DEFAULT 0.000,
    min_stock_lvl  NUMERIC(10,3) DEFAULT 5.000,
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(shop_id, product_id)
);

CREATE TABLE IF NOT EXISTS stock_logs (
    id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stock_id       INTEGER REFERENCES stocks(id) ON DELETE CASCADE,
    change_qty     NUMERIC(10,3) NOT NULL,
    log_type       VARCHAR(20), -- 'IN', 'OUT', 'WASTE'
    remarks        TEXT,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. CUSTOMERS & LEDGER (Notebook)
CREATE TABLE IF NOT EXISTS customers (
    id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name           VARCHAR(100) NOT NULL,
    phone          VARCHAR(15) UNIQUE,
    address        TEXT,
        is_active BOOLEAN DEFAULT TRUE,
 
    opening_balance NUMERIC(10,2) DEFAULT 0,
    current_balance NUMERIC(10,2) DEFAULT 0,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_ref       VARCHAR(50) UNIQUE,
    shop_id         INTEGER REFERENCES shops(id),
    customer_id     INTEGER REFERENCES customers(id),
    user_id         INTEGER REFERENCES users(id),
    paymode_id      INTEGER REFERENCES payment_modes(id),
    total_amount    NUMERIC(10,2) NOT NULL,
    paid_amount     NUMERIC(10,2) DEFAULT 0,
    balance_due     NUMERIC(10,2) DEFAULT 0,
    status          VARCHAR(20) DEFAULT 'COMPLETED',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
    id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id       INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    product_id     INTEGER REFERENCES products(id),
    weight         NUMERIC(10,3) NOT NULL,
    rate           NUMERIC(10,2) NOT NULL,
    sub_total      NUMERIC(10,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS customer_ledger (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id     INTEGER NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    shop_id         INTEGER REFERENCES shops(id),
    order_id        INTEGER REFERENCES orders(id),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    weight          NUMERIC(10,3),
    rate            NUMERIC(10,2),
    debit_amount    NUMERIC(10,2) DEFAULT 0,
    credit_amount   NUMERIC(10,2) DEFAULT 0,
    running_balance NUMERIC(10,2) NOT NULL,
    paymode_id      INTEGER REFERENCES payment_modes(id),
    remarks         TEXT
);

-- 6. SUPPLIERS & EXPENSES
CREATE TABLE IF NOT EXISTS suppliers (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    phone           VARCHAR(15),
    address         TEXT,
    current_balance NUMERIC(10,2) DEFAULT 0,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS purchases (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_id     INTEGER REFERENCES suppliers(id),
    shop_id         INTEGER REFERENCES shops(id),
    total_qty       NUMERIC(10,3) NOT NULL,
    unit_price      NUMERIC(10,2) NOT NULL,
    total_amount    NUMERIC(10,2) NOT NULL,
    paid_amount     NUMERIC(10,2) DEFAULT 0,
    bill_image      TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS expense_categories (
    id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name    VARCHAR(50) NOT NULL
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

-- 7. INDEXES
CREATE INDEX idx_ledger_customer ON customer_ledger(customer_id);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_stocks_shop ON stocks(shop_id);

-- 8. INITIAL SEED DATA
INSERT INTO roles (role_name) VALUES ('admin'), ('owner'), ('manager'), ('staff');

INSERT INTO payment_modes (name) VALUES 
('Cash'), ('PhonePe'), ('G-Pay'), ('Paytm'), ('Bank Transfer'), ('Credit');

INSERT INTO categories (name) VALUES 
('Broiler Chicken'), ('Country Chicken'), ('Eggs'), ('Quail (Kaadai)');

INSERT INTO expense_categories (name) VALUES 
('Rent'), ('Salary'), ('Electricity'), ('Transport'), ('Feed'), ('Wastage');