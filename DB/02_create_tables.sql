-- ============================================================
-- Q-Sports: CREATE ALL TABLES + INDEXES + SEED DATA
-- Clean script — all ALTER columns are merged into CREATE TABLE
-- ============================================================

-- Enable UUID generation (PostgreSQL)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =========================
-- 1. Users table
-- =========================
CREATE TABLE IF NOT EXISTS users (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username        VARCHAR(100) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    phoneno         VARCHAR(15),
    address         VARCHAR,
    city            VARCHAR,
    latitude        DOUBLE PRECISION,
    longitude       DOUBLE PRECISION,
    bio             TEXT,
    image_url       TEXT,
    state_territory VARCHAR,
    acccode         TEXT NOT NULL,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    retry_cnt_lmt   INT DEFAULT 5,
    retrycnt_updated_on TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- 2. Roles table
-- =========================
CREATE TABLE IF NOT EXISTS roles (
    id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL
);

-- =========================
-- 3. User-Role mapping (many-to-many)
-- =========================
CREATE TABLE IF NOT EXISTS user_roles (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- =========================
-- 4. Sports table
-- =========================
CREATE TABLE IF NOT EXISTS sports (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- 5. Venues table
-- =========================
CREATE TABLE IF NOT EXISTS venues (
    id            INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    location      TEXT NOT NULL,
    price         NUMERIC(10,2) NOT NULL,
    capacity      INTEGER,
    description   TEXT,
    image_url     TEXT,
    contact_phone VARCHAR(20),
    contact_email VARCHAR(100),
    created_by    INTEGER,
    is_active     BOOLEAN DEFAULT TRUE,
    is_deleted    BOOLEAN DEFAULT FALSE,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- 6. Courts table (venue-sport mapping)
-- =========================
CREATE TABLE IF NOT EXISTS courts (
    id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    venue_id       INT REFERENCES venues(id) ON DELETE CASCADE,
    sport_id       INT REFERENCES sports(id),
    name           VARCHAR(50),
    price_per_hour NUMERIC(10,2) NOT NULL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- 7. Time slots table
-- =========================
CREATE TABLE IF NOT EXISTS time_slots (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    court_id   INT,
    start_time TIMESTAMP NOT NULL,
    end_time   TIMESTAMP NOT NULL,
    is_booked  BOOLEAN DEFAULT FALSE,
    venue_id   INT,
    price      NUMERIC(10,2)
);

-- =========================
-- 8. Bookings table (payment columns included)
-- =========================
CREATE TABLE IF NOT EXISTS bookings (
    id                  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_ref         VARCHAR(20) UNIQUE,
    user_id             INT REFERENCES users(id),
    court_id            INT,
    venue_id            INT REFERENCES venues(id),
    slot_id             INT REFERENCES time_slots(id),
    status              VARCHAR(20) DEFAULT 'CONFIRMED',
    sports_id           INT REFERENCES sports(id),
    is_payment_enabled  BOOLEAN DEFAULT FALSE,
    payment_url         TEXT,
    payment_status      VARCHAR(50) DEFAULT 'NA',
    transaction_id      VARCHAR(255),
    amount              NUMERIC(10,2) DEFAULT 0,
    payment_at          TIMESTAMP,
    booked_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- 9. Bookings mapping table
-- =========================
CREATE TABLE IF NOT EXISTS bookings_mapping (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_id INTEGER NOT NULL,
    start_time VARCHAR(20),
    end_time   VARCHAR(20),
    slot_id    INT,
    sports_id  INT,
    court_id   INT
);

-- =========================
-- 10. User settings table
-- =========================
CREATE TABLE IF NOT EXISTS user_settings (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    language_type VARCHAR(150) NOT NULL DEFAULT 'en',
    region     VARCHAR(150) NOT NULL DEFAULT 'IN',
    push_notify BOOLEAN DEFAULT TRUE,
    mail_upd   BOOLEAN DEFAULT TRUE,
    themes     TEXT NOT NULL DEFAULT 'light',
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    isdelete   INTEGER DEFAULT 0
);

-- =========================
-- 11. OTP log table
-- =========================
CREATE TABLE IF NOT EXISTS otp_log (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    userid      BIGINT REFERENCES users(id) ON DELETE CASCADE,
    emailid     VARCHAR(150) NOT NULL,
    phoneno     VARCHAR(15),
    otp         VARCHAR(6) NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    is_resend   BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at  TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 minutes'),
    verified_at TIMESTAMP NULL,
    resend_at   TIMESTAMP NULL
);

-- Indexes for OTP lookup
CREATE INDEX IF NOT EXISTS idx_otp_email ON otp_log(emailid);
CREATE INDEX IF NOT EXISTS idx_otp_userid ON otp_log(userid);

-- =========================
-- 12. User-Venue mapping table
-- =========================
CREATE TABLE IF NOT EXISTS user_venue_mapping (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    INTEGER NOT NULL,
    venue_id   INTEGER NOT NULL,
    is_active  BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- 13. Cities table (with lat/lng)
-- =========================
CREATE TABLE IF NOT EXISTS cities (
    id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name      VARCHAR(150) NOT NULL,
    state     VARCHAR(150) NOT NULL DEFAULT 'Tamil Nadu',
    latitude  DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_active BOOLEAN DEFAULT TRUE
);

-- =========================
-- 14. General settings table
-- =========================
CREATE TABLE IF NOT EXISTS tbl_general_settings (
    enable_verify_otp BOOLEAN DEFAULT TRUE,
    enable_skip_login BOOLEAN DEFAULT TRUE,
    retry_count_limit INT DEFAULT 3,
    enable_payment    BOOLEAN DEFAULT FALSE
);

-- =========================
-- 15. User FCM tokens table (one user, multiple devices)
-- =========================
CREATE TABLE IF NOT EXISTS user_fcm_tokens (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token   TEXT NOT NULL,
    device_id   VARCHAR(255),
    device_name VARCHAR(255),
    platform    VARCHAR(20) DEFAULT 'android',
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, fcm_token)
);


-- =========================
-- 16. Conversations table
-- =========================
CREATE TABLE IF NOT EXISTS conversations (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user1_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user2_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    venue_id    INTEGER REFERENCES venues(id) ON DELETE SET NULL,
    booking_id  INTEGER REFERENCES bookings(id) ON DELETE SET NULL,
    context     VARCHAR(50) DEFAULT 'general',  -- general, booking, support
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Unique index using COALESCE (PostgreSQL doesn't allow COALESCE in UNIQUE constraint)
CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_unique
    ON conversations (user1_id, user2_id, COALESCE(venue_id, 0), COALESCE(booking_id, 0));

CREATE INDEX IF NOT EXISTS idx_conversations_user1 ON conversations(user1_id);
CREATE INDEX IF NOT EXISTS idx_conversations_user2 ON conversations(user2_id);

-- =========================
-- 17. Messages table
-- =========================
CREATE TABLE IF NOT EXISTS messages (
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    conversation_id INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message         TEXT NOT NULL,
    message_type    VARCHAR(20) DEFAULT 'text',  -- text, image, file
    is_read         BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(conversation_id, created_at DESC);

-- =========================
-- 18. Venue Likes table
-- =========================
CREATE TABLE IF NOT EXISTS venue_likes (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    venue_id   INTEGER NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, venue_id)
);

CREATE INDEX IF NOT EXISTS idx_venue_likes_user ON venue_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_venue_likes_venue ON venue_likes(venue_id);

-- ============================================================
-- DONE: All tables and indexes created
-- Now run 03_seed_data.sql for master/config data
-- ============================================================
-- =========================
-- 19. Notifications table
-- =========================
CREATE TABLE IF NOT EXISTS notifications (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type        VARCHAR(50) NOT NULL DEFAULT 'booking',
    title       VARCHAR(255) NOT NULL,
    body        TEXT,
    data        JSONB DEFAULT '{}',
    is_read     BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(user_id, is_read);

ALTER TABLE bookings_mapping DROP CONSTRAINT IF EXISTS bookings_mapping_slot_id_fkey;

ALTER TABLE bookings_mapping ADD COLUMN IF NOT EXISTS sports_id INT;
ALTER TABLE bookings_mapping ADD COLUMN IF NOT EXISTS court_id INT;
