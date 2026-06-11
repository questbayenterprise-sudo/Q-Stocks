-- ============================================================
-- Q-Sports: SEED DATA (One-time master/config inserts)
-- Run AFTER 02_create_tables.sql
-- ============================================================

-- =========================
-- Roles
-- =========================
INSERT INTO roles (role_name)
SELECT v.role_name
FROM (VALUES ('admin'), ('user'), ('manager'), ('vendor'), ('owner')) AS v(role_name)
WHERE NOT EXISTS (SELECT 1 FROM roles r WHERE r.role_name = v.role_name);

-- =========================
-- Sports
-- =========================
INSERT INTO sports (name)
SELECT v.name
FROM (VALUES
    ('Football'), ('Cricket'), ('Badminton'), ('Tennis'),
    ('Basketball'), ('Volleyball'), ('Hockey'), ('Table Tennis'),
    ('Swimming'), ('Squash'), ('Kabaddi'), ('Carrom'), ('Chess')
) AS v(name)
WHERE NOT EXISTS (SELECT 1 FROM sports s WHERE s.name = v.name);

-- =========================
-- Tamil Nadu Cities (with lat/lng)
-- =========================
INSERT INTO cities (name, state, latitude, longitude)
SELECT v.name, 'Tamil Nadu', v.lat, v.lng
FROM (VALUES
    ('Ariyalur',        10.8449, 78.6625),
    ('Chengalpattu',    12.4996, 80.0000),
    ('Chennai',         13.0827, 80.2707),
    ('Coimbatore',      11.0168, 76.9558),
    ('Cuddalore',       11.7480, 79.7714),
    ('Dharmapuri',      12.1165, 78.1674),
    ('Dindigul',        10.3624, 77.9695),
    ('Erode',           11.3410, 77.7172),
    ('Hosur',           12.7409, 78.0520),
    ('Kallakurichi',    11.9416, 79.4864),
    ('Kanchipuram',     12.6819, 79.9888),
    ('Karur',           10.9574, 78.0818),
    ('Krishnagiri',     12.5266, 78.2150),
    ('Kumbakonam',      10.9601, 79.3845),
    ('Madurai',          9.9252, 78.1198),
    ('Mayiladuthurai',  10.9091, 79.3145),
    ('Nagapattinam',    10.7867, 79.8424),
    ('Namakkal',        11.2189, 78.1680),
    ('Nagercoil',        8.1833, 77.4119),
    ('Ooty',            11.4102, 76.6950),
    ('Perambalur',      11.2403, 78.8861),
    ('Pudukkottai',     10.3624, 78.8001),
    ('Ramanathapuram',   9.3639, 79.1325),
    ('Ranipet',         12.9675, 79.1555),
    ('Salem',           11.6643, 78.1460),
    ('Sivaganga',        9.8477, 78.4836),
    ('Tenkasi',          8.9550, 77.3654),
    ('Thanjavur',       10.7870, 79.1378),
    ('Theni',           10.0104, 77.4768),
    ('Thoothukudi',      8.7642, 78.1348),
    ('Tiruchirappalli', 10.7905, 78.7047),
    ('Tirunelveli',      8.7139, 77.7567),
    ('Tirupathur',      12.4048, 79.3212),
    ('Tiruppur',        11.1085, 77.3411),
    ('Tiruvallur',      13.1067, 80.0967),
    ('Tiruvannamalai',  12.0735, 79.0745),
    ('Tiruvarur',       10.7654, 79.6367),
    ('Vellore',         12.9165, 79.1325),
    ('Viluppuram',      11.8569, 79.7465),
    ('Virudhunagar',     9.5981, 77.9624)
) AS v(name, lat, lng)
WHERE NOT EXISTS (SELECT 1 FROM cities c WHERE c.name = v.name AND c.state = 'Tamil Nadu');

-- =========================
-- General Settings (default config)
-- =========================
INSERT INTO tbl_general_settings (enable_verify_otp, enable_skip_login, retry_count_limit, enable_payment)
SELECT true, true, 5, false
WHERE NOT EXISTS (SELECT 1 FROM tbl_general_settings);

-- ============================================================
-- DONE: All seed data inserted
-- ============================================================
