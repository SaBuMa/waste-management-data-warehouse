-- =====================================================================
-- Enhanced edition · 01 — Staging tables
-- Columns mirror the CSV headers and are stored as TEXT, so a bad value
-- never breaks the load. Types are enforced later, in the transform step.
-- =====================================================================

CREATE TABLE IF NOT EXISTS staging.dim_date_raw (
    dateid      TEXT,
    date        TEXT,
    year        TEXT,
    quarter     TEXT,
    quartername TEXT,
    month       TEXT,
    monthname   TEXT,
    day         TEXT,
    weekday     TEXT,
    weekdayname TEXT
);

CREATE TABLE IF NOT EXISTS staging.dim_truck_raw (
    truckid   TEXT,
    trucktype TEXT
);

CREATE TABLE IF NOT EXISTS staging.dim_station_raw (
    stationid TEXT,
    city      TEXT
);

CREATE TABLE IF NOT EXISTS staging.fact_trips_raw (
    tripid         TEXT,
    dateid         TEXT,
    stationid      TEXT,
    truckid        TEXT,
    wastecollected TEXT
);
