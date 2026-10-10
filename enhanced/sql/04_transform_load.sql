-- =====================================================================
-- Enhanced edition · 04 — Transform staging → warehouse
--   • casts TEXT to proper types and trims stray spaces
--   • DERIVES every calendar attribute from the date itself, which fixes
--     the shifted weekday names found in the source DimDate.csv
--   • upserts (INSERT … ON CONFLICT), so re-running is safe and corrections
--     in the source overwrite old values instead of duplicating rows
--   • runs as one transaction: all tables load, or none do
-- =====================================================================

BEGIN;

-- Dimensions first (the fact table references them) --------------------

INSERT INTO dw.dim_date (date_key, full_date, calendar_year, quarter_num,
                         quarter_name, month_num, month_name, day_of_month,
                         iso_weekday, weekday_name, is_weekend)
SELECT
    src.dateid::INT,
    d,
    EXTRACT(YEAR    FROM d),
    EXTRACT(QUARTER FROM d),
    'Q' || EXTRACT(QUARTER FROM d),
    EXTRACT(MONTH   FROM d),
    TRIM(TO_CHAR(d, 'Month')),
    EXTRACT(DAY     FROM d),
    EXTRACT(ISODOW  FROM d),
    TRIM(TO_CHAR(d, 'Day')),
    EXTRACT(ISODOW  FROM d) IN (6, 7)
FROM staging.dim_date_raw AS src
CROSS JOIN LATERAL (SELECT src.date::DATE AS d) AS x
ON CONFLICT (date_key) DO UPDATE SET
    full_date     = EXCLUDED.full_date,
    calendar_year = EXCLUDED.calendar_year,
    quarter_num   = EXCLUDED.quarter_num,
    quarter_name  = EXCLUDED.quarter_name,
    month_num     = EXCLUDED.month_num,
    month_name    = EXCLUDED.month_name,
    day_of_month  = EXCLUDED.day_of_month,
    iso_weekday   = EXCLUDED.iso_weekday,
    weekday_name  = EXCLUDED.weekday_name,
    is_weekend    = EXCLUDED.is_weekend;

INSERT INTO dw.dim_truck (truck_id, truck_type)
SELECT truckid::INT, TRIM(trucktype)
FROM staging.dim_truck_raw
ON CONFLICT (truck_id) DO UPDATE SET truck_type = EXCLUDED.truck_type;

INSERT INTO dw.dim_station (station_id, city)
SELECT stationid::INT, TRIM(city)
FROM staging.dim_station_raw
ON CONFLICT (station_id) DO UPDATE SET city = EXCLUDED.city;

-- Fact ------------------------------------------------------------------

INSERT INTO dw.fact_trips (trip_id, date_key, station_id, truck_id,
                           waste_collected_tons)
SELECT tripid::INT, dateid::INT, stationid::INT, truckid::INT,
       wastecollected::NUMERIC(10,2)
FROM staging.fact_trips_raw
ON CONFLICT (trip_id) DO UPDATE SET
    date_key             = EXCLUDED.date_key,
    station_id           = EXCLUDED.station_id,
    truck_id             = EXCLUDED.truck_id,
    waste_collected_tons = EXCLUDED.waste_collected_tons;

COMMIT;

-- Keep planner statistics current after a bulk load
ANALYZE dw.dim_date, dw.dim_truck, dw.dim_station, dw.fact_trips;
