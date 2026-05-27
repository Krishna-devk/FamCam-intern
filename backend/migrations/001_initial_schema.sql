-- ============================================================
-- TABLE: services
-- Source of truth for service metadata. duration_minutes is
-- the authoritative duration — never hardcode this value.
-- ============================================================
CREATE TABLE IF NOT EXISTS services (
    id               SERIAL PRIMARY KEY,
    name             VARCHAR(100)  NOT NULL,
    description      TEXT,
    duration_minutes INT           NOT NULL CHECK (duration_minutes % 15 = 0),
    price_cents      INT           NOT NULL CHECK (price_cents > 0),
    created_at       TIMESTAMPTZ   DEFAULT NOW()
);

-- ============================================================
-- TABLE: users
-- Unified identity table for both patients and caregivers.
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(100)  NOT NULL,
    email      VARCHAR(255)  UNIQUE NOT NULL,
    role       VARCHAR(20)   NOT NULL CHECK (role IN ('PATIENT', 'CAREGIVER')),
    created_at TIMESTAMPTZ   DEFAULT NOW()
);

-- ============================================================
-- TABLE: caregiver_services
-- Maps which caregivers are qualified to perform which services.
-- Used for availability checks and slot generation.
-- ============================================================
CREATE TABLE IF NOT EXISTS caregiver_services (
    caregiver_id INT NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    service_id   INT NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    PRIMARY KEY (caregiver_id, service_id)
);

-- ============================================================
-- TABLE: bookings
-- Ledger of all confirmed bookings. end_time is stored (not
-- computed) for efficient index-based range queries.
-- status: 'CONFIRMED' | 'CANCELLED'
-- ============================================================
CREATE TABLE IF NOT EXISTS bookings (
    id           SERIAL PRIMARY KEY,
    patient_id   INT          NOT NULL REFERENCES users(id)    ON DELETE RESTRICT,
    caregiver_id INT          NOT NULL REFERENCES users(id)    ON DELETE RESTRICT,
    service_id   INT          NOT NULL REFERENCES services(id) ON DELETE RESTRICT,
    booking_date DATE         NOT NULL,
    start_time   TIME         NOT NULL,
    end_time     TIME         NOT NULL,
    price_cents  INT          NOT NULL,
    status       VARCHAR(20)  NOT NULL DEFAULT 'CONFIRMED'
                              CHECK (status IN ('CONFIRMED', 'CANCELLED')),
    created_at   TIMESTAMPTZ  DEFAULT NOW(),

    -- Derived constraint: end must be after start
    CONSTRAINT chk_time_order CHECK (end_time > start_time),
    -- start_time must be 15-min aligned
    CONSTRAINT chk_start_aligned CHECK (
        EXTRACT(MINUTE FROM start_time)::INT % 15 = 0
    )
);

-- ============================================================
-- INDICES — Optimized for the two conflict-check query patterns
-- ============================================================

-- Index 1: Caregiver conflict lookup
-- Query: "find all active bookings for caregiver X on date D"
CREATE INDEX IF NOT EXISTS idx_bookings_caregiver_date
    ON bookings (caregiver_id, booking_date, status)
    WHERE status = 'CONFIRMED';

-- Index 2: Patient conflict lookup
-- Query: "find all active bookings for patient X on date D"
CREATE INDEX IF NOT EXISTS idx_bookings_patient_date
    ON bookings (patient_id, booking_date, status)
    WHERE status = 'CONFIRMED';

-- Index 3: General date-range scan for slot availability
CREATE INDEX IF NOT EXISTS idx_bookings_date_times
    ON bookings (booking_date, start_time, end_time)
    WHERE status = 'CONFIRMED';
