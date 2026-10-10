-- =====================================================================
-- Enhanced edition · 07 — GROUPING SETS / ROLLUP / CUBE, report-ready
-- Improvements over the core version:
--   • GROUPING() + labels: subtotal rows say "All stations" instead of NULL
--     (GROUPING() is used rather than IS NULL, so a real NULL in the data
--     could never be mistaken for a subtotal)
--   • a level column that names each row type
--   • ROUND() on averages, NULLS LAST so totals come after the details
-- =====================================================================

-- GROUPING SETS: total waste by station and truck type ------------------
SELECT
    CASE WHEN GROUPING(f.station_id) = 1 THEN 'All stations'
         ELSE f.station_id::TEXT END                         AS station,
    CASE WHEN GROUPING(t.truck_type) = 1 THEN 'All truck types'
         ELSE t.truck_type END                               AS truck_type,
    CASE GROUPING(f.station_id, t.truck_type)
         WHEN 0 THEN 'detail'
         WHEN 1 THEN 'station subtotal'
         WHEN 2 THEN 'truck type subtotal'
         ELSE        'grand total' END                       AS level,
    SUM(f.waste_collected_tons)                              AS total_waste_tons
FROM dw.fact_trips f
JOIN dw.dim_truck t USING (truck_id)
GROUP BY GROUPING SETS ((f.station_id, t.truck_type), f.station_id, t.truck_type, ())
ORDER BY GROUPING(f.station_id), f.station_id,
         GROUPING(t.truck_type), t.truck_type;

-- ROLLUP: total waste along Year → City → Station -----------------------
SELECT
    CASE WHEN GROUPING(d.calendar_year) = 1 THEN 'All years'
         ELSE d.calendar_year::TEXT END                      AS year,
    CASE WHEN GROUPING(s.city) = 1 THEN 'All cities'
         ELSE s.city END                                     AS city,
    CASE WHEN GROUPING(f.station_id) = 1 THEN 'All stations'
         ELSE f.station_id::TEXT END                         AS station,
    SUM(f.waste_collected_tons)                              AS total_waste_tons
FROM dw.fact_trips f
JOIN dw.dim_date d    USING (date_key)
JOIN dw.dim_station s USING (station_id)
GROUP BY ROLLUP (d.calendar_year, s.city, f.station_id)
ORDER BY d.calendar_year DESC NULLS LAST,
         s.city NULLS LAST,
         f.station_id NULLS LAST;

-- CUBE: average waste per trip for every Year/City/Station combination --
SELECT
    CASE WHEN GROUPING(d.calendar_year) = 1 THEN 'All years'
         ELSE d.calendar_year::TEXT END                      AS year,
    CASE WHEN GROUPING(s.city) = 1 THEN 'All cities'
         ELSE s.city END                                     AS city,
    CASE WHEN GROUPING(f.station_id) = 1 THEN 'All stations'
         ELSE f.station_id::TEXT END                         AS station,
    ROUND(AVG(f.waste_collected_tons), 2)                    AS avg_waste_tons,
    COUNT(*)                                                 AS trips
FROM dw.fact_trips f
JOIN dw.dim_date d    USING (date_key)
JOIN dw.dim_station s USING (station_id)
GROUP BY CUBE (d.calendar_year, s.city, f.station_id)
ORDER BY d.calendar_year NULLS LAST,
         s.city NULLS LAST,
         f.station_id NULLS LAST;
