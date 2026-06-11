-- ============================================================
-- Q-Sports: DROP ALL TABLES (One-time reset script)
-- Run this ONLY when you want a complete fresh start
-- ============================================================

-- Drop in reverse dependency order (children first, parents last)
DROP TABLE IF EXISTS bookings_mapping CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS time_slots CASCADE;
DROP TABLE IF EXISTS courts CASCADE;
DROP TABLE IF EXISTS otp_log CASCADE;
DROP TABLE IF EXISTS user_fcm_tokens CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS user_venue_mapping CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS tbl_general_settings CASCADE;
DROP TABLE IF EXISTS cities CASCADE;
DROP TABLE IF EXISTS sports CASCADE;
DROP TABLE IF EXISTS venues CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Done: All tables dropped. Now run 02_create_tables.sql
