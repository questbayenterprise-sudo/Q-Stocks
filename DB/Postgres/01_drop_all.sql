-- ============================================================
-- BROILER SHOP: DROP ALL TABLES (One-time reset script)
-- Run this ONLY when you want a complete fresh start
-- ============================================================

-- 1. Drop Transactional Children (The most dependent tables)
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS stock_logs CASCADE;
DROP TABLE IF EXISTS customer_ledger CASCADE;

-- 2. Drop Transactions & Operational Data
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customer_payments CASCADE;
DROP TABLE IF EXISTS purchases CASCADE;
DROP TABLE IF EXISTS expenses CASCADE;
DROP TABLE IF EXISTS stocks CASCADE;
DROP TABLE IF EXISTS daily_rates CASCADE;

-- 3. Drop Mappings and Logs
DROP TABLE IF EXISTS shop_user_mapping CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS user_fcm_tokens CASCADE;
DROP TABLE IF EXISTS otp_log CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;

-- 4. Drop Master Entities (Parent Tables)
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS shops CASCADE;
DROP TABLE IF EXISTS expense_categories CASCADE;
DROP TABLE IF EXISTS payment_modes CASCADE;

-- 5. Drop Core Infrastructure
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS cities CASCADE;
DROP TABLE IF EXISTS tbl_general_settings CASCADE;

-- 6. Clean up extensions (Optional)
-- DROP EXTENSION IF EXISTS "pgcrypto";

-- ============================================================
-- DONE: All tables dropped. 
-- Database is now clean and ready for a fresh CREATE script.
-- ============================================================