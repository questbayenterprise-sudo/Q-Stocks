
-- ============================================================
-- 8. SEED DATA (INITIAL SETUP)
-- ============================================================

-- Roles
INSERT INTO roles (role_name) VALUES ('admin'), ('owner'), ('staff');

-- Payment Modes
INSERT INTO payment_modes (name) VALUES 
('Cash'), ('PhonePe'), ('Google Pay'), ('Paytm'), ('Bank Transfer'), ('Credit');

-- Categories
INSERT INTO categories (name) VALUES 
('Broiler Chicken'), ('Country Chicken'), ('Eggs'), ('Quail (Kaadai)'), ('Masala');

-- Cities (TN Sample)
INSERT INTO cities (name, state) VALUES 
('Chennai', 'Tamil Nadu'), ('Coimbatore', 'Tamil Nadu'), ('Madurai', 'Tamil Nadu');

-- General Settings
INSERT INTO tbl_general_settings (shop_name) VALUES ('Arun Broiler & Eggs');

-- Seed Data for Expenses
INSERT INTO expense_categories (name) VALUES 
('Rent'), ('Staff Salary'), ('Electricity'), ('Transport'), ('Bird Feed'), ('Wastage/Other');