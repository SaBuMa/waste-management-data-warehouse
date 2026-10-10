-- =====================================================================
-- Enhanced edition · 03 — Warehouse tables (dw schema)
-- Improvements over the core version:
--   • consistent snake_case names, no keyword-like column names
--     (date → full_date, year → calendar_year, day → day_of_month)
--   • NOT NULL everywhere a value is required
--   • CHECK constraints that reject impossible values
--   • is_weekend flag for weekday/weekend reporting
--   • indexes on the fact table's foreign keys (faster joins)
-- =====================================================================

CREATE TABLE IF NOT EXISTS dw.dim_date (
    date_key      INT          PRIMARY KEY,
    full_date     DATE         NOT NULL UNIQUE,
    calendar_year SMALLINT     NOT NULL,
    quarter_num   SMALLINT     NOT NULL CHECK (quarter_num BETWEEN 1 AND 4),
    quarter_name  CHAR(2)      NOT NULL,
    month_num     SMALLINT     NOT NULL CHECK (month_num BETWEEN 1 AND 12),
    month_name    VARCHAR(9)   NOT NULL,
    day_of_month  SMALLINT     NOT NULL CHECK (day_of_month BETWEEN 1 AND 31),
    iso_weekday   SMALLINT     NOT NULL CHECK (iso_weekday BETWEEN 1 AND 7),  -- 1 = Monday
    weekday_name  VARCHAR(9)   NOT NULL,
    is_weekend    BOOLEAN      NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.dim_truck (
    truck_id   INT         PRIMARY KEY,
    truck_type VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.dim_station (
    station_id INT          PRIMARY KEY,
    city       VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.fact_trips (
    trip_id              INT           PRIMARY KEY,
    date_key             INT           NOT NULL REFERENCES dw.dim_date (date_key),
    station_id           INT           NOT NULL REFERENCES dw.dim_station (station_id),
    truck_id             INT           NOT NULL REFERENCES dw.dim_truck (truck_id),
    waste_collected_tons NUMERIC(10,2) NOT NULL CHECK (waste_collected_tons > 0)
);

-- PostgreSQL does not index foreign keys automatically
CREATE INDEX IF NOT EXISTS ix_fact_trips_date_key   ON dw.fact_trips (date_key);
CREATE INDEX IF NOT EXISTS ix_fact_trips_station_id ON dw.fact_trips (station_id);
CREATE INDEX IF NOT EXISTS ix_fact_trips_truck_id   ON dw.fact_trips (truck_id);
