-- ============================================================
-- BROILER MGMT SYSTEM: SQLITE INITIALIZATION SCRIPT
-- ============================================================

-- 1. INFRASTRUCTURE
CREATE TABLE IF NOT EXISTS tbl_general_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    shop_name TEXT DEFAULT 'Broiler Management System',
    currency_symbol TEXT DEFAULT '₹',
    enable_otp INTEGER DEFAULT 0, 
    low_stock_limit REAL DEFAULT 5.000,
    decimal_places INTEGER DEFAULT 2,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    state TEXT DEFAULT 'Tamil Nadu',
    latitude REAL,
    longitude REAL,
    is_active INTEGER DEFAULT 1
);

-- 2. IDENTITY
CREATE TABLE IF NOT EXISTS roles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    role_name TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phoneno TEXT,
    password_hash TEXT,
    address TEXT,
    city TEXT,
    image_url TEXT,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id INTEGER NOT NULL,
    role_id INTEGER NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS otp_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userid INTEGER,
    phoneno TEXT,
    otp TEXT NOT NULL,
    is_verified INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME,
    FOREIGN KEY (userid) REFERENCES users(id) ON DELETE CASCADE
);

-- 3. SHOP & MASTERS
CREATE TABLE IF NOT EXISTS payment_modes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS shops (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    location TEXT NOT NULL,
    description TEXT,             
    image_url TEXT,               
    is_active INTEGER DEFAULT 1,
    created_by INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS shop_user_mapping (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    shop_id INTEGER NOT NULL,
    is_active INTEGER DEFAULT 1,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE
);

-- 4. PRODUCTS & INVENTORY
CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    image_url TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER,
    name TEXT NOT NULL,
    uom TEXT DEFAULT 'KG',
    base_price REAL NOT NULL,
    is_active INTEGER DEFAULT 1,
    image_url TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS stocks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    shop_id INTEGER,
    product_id INTEGER,
    current_qty REAL DEFAULT 0.000,
    min_stock_lvl REAL DEFAULT 5.000,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS stock_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    stock_id INTEGER,
    change_qty REAL NOT NULL,
    log_type TEXT, -- IN, OUT, WASTE
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (stock_id) REFERENCES stocks(id)
);

-- 5. CUSTOMERS & LEDGER
CREATE TABLE IF NOT EXISTS customers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    phone TEXT UNIQUE,
    address TEXT,
    opening_balance REAL DEFAULT 0,
    current_balance REAL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_ref TEXT UNIQUE,
    shop_id INTEGER,
    customer_id INTEGER,
    user_id INTEGER,
    paymode_id INTEGER,
    total_amount REAL NOT NULL,
    paid_amount REAL DEFAULT 0,
    balance_due REAL DEFAULT 0,
    status TEXT DEFAULT 'COMPLETED', -- <--- ENSURE THIS LINE IS HERE
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER,
    product_id INTEGER,
    weight REAL NOT NULL,
    rate REAL NOT NULL,
    sub_total REAL NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE TABLE IF NOT EXISTS customer_ledger (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id INTEGER NOT NULL,
    shop_id INTEGER NOT NULL,
    order_id INTEGER,
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    weight REAL,
    rate REAL,
    debit_amount REAL DEFAULT 0,
    credit_amount REAL DEFAULT 0,
    running_balance REAL NOT NULL,
    paymode_id INTEGER,
    remarks TEXT,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    FOREIGN KEY (shop_id) REFERENCES shops(id),
    FOREIGN KEY (paymode_id) REFERENCES payment_modes(id)
);

-- 6. SUPPLIERS & EXPENSES
CREATE TABLE IF NOT EXISTS suppliers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    current_balance REAL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS purchases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    supplier_id INTEGER,
    shop_id INTEGER,
    total_qty REAL NOT NULL,
    unit_price REAL NOT NULL,
    total_amount REAL NOT NULL,
    paid_amount REAL DEFAULT 0,
    bill_image TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
    FOREIGN KEY (shop_id) REFERENCES shops(id)
);

CREATE TABLE IF NOT EXISTS daily_rates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    shop_id INTEGER,
    product_id INTEGER,
    today_rate REAL NOT NULL,
    effective_date DATE DEFAULT CURRENT_DATE,
    UNIQUE(shop_id, product_id, effective_date),
    FOREIGN KEY (shop_id) REFERENCES shops(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE TABLE IF NOT EXISTS expense_categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS expenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    shop_id INTEGER,
    category_id INTEGER,
    amount REAL NOT NULL,
    expense_date DATE DEFAULT CURRENT_DATE,
    remarks TEXT,
    created_by INTEGER,
    FOREIGN KEY (shop_id) REFERENCES shops(id),
    FOREIGN KEY (category_id) REFERENCES expense_categories(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
);

-- 7. SEED DATA
INSERT INTO roles (role_name) VALUES ('admin'), ('owner'), ('staff');
INSERT INTO payment_modes (name) VALUES ('Cash'), ('PhonePe'), ('Google Pay'), ('Paytm'), ('Bank Transfer'), ('Credit');
INSERT INTO categories (name) VALUES ('Broiler Chicken'), ('Country Chicken'), ('Eggs'), ('Quail (Kaadai)'), ('Masala');
INSERT INTO expense_categories (name) VALUES ('Rent'), ('Staff Salary'), ('Electricity'), ('Transport'), ('Bird Feed'), ('Wastage');
INSERT INTO tbl_general_settings (shop_name) VALUES ('Arun Broiler & Eggs');

-- 1. Insert the User
INSERT INTO users (username, email, phoneno, is_active) 
VALUES ('Subhash Admin', 'subhashbalajims@gmail.com', '9876543210', 1);

-- 2. Map the User to the Admin Role
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id 
FROM users u, roles r 
WHERE u.email = 'subhashbalajims@gmail.com' AND r.role_name = 'admin';

-- 8. PRODUCT SEED DATA
-- Linked to Category 1 (Broiler Chicken)
INSERT INTO products (name, category_id, uom, base_price, is_active) 
VALUES ('Full Chicken (With Skin)', 1, 'KG', 140.0, 1);

INSERT INTO products (name, category_id, uom, base_price, is_active) 
VALUES ('Skinless Chicken', 1, 'KG', 160.0, 1);

-- Linked to Category 2 (Country Chicken)
INSERT INTO products (name, category_id, uom, base_price, is_active) 
VALUES ('Nattu Kozhi (Whole)', 2, 'KG', 350.0, 1);

-- Linked to Category 3 (Eggs)
INSERT INTO products (name, category_id, uom, base_price, is_active) 
VALUES ('Farm Fresh Eggs', 3, 'Piece', 6.5, 1);


-- 9. SHOP SEED DATA (So you have a default shop to test)
INSERT INTO shops (name, location, description, is_active, created_by)
VALUES ('Main Branch', 'Mannargudi', 'Primary retail outlet', 1, 1);

-- Auto-map Admin to the Default Shop
INSERT INTO shop_user_mapping (user_id, shop_id, is_active) VALUES (1, 1, 1);


-- 10. CUSTOMER SEED DATA (For the Sales Dropdown)
INSERT INTO customers (name, phone, address, current_balance) 
VALUES ('Walk-in Customer', '0000000000', 'Counter Sale', 0.0);