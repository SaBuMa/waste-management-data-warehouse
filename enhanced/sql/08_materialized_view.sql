-- =====================================================================
-- Enhanced edition · 08 — Materialized view, refreshable without locking
-- A UNIQUE index lets PostgreSQL refresh the view CONCURRENTLY, so
-- dashboards can keep reading it while new data is being applied.
-- =====================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS dw.mv_max_waste_stats AS
SELECT
    s.city,
    f.station_id,
    t.truck_type,
    MAX(f.waste_collected_tons) AS max_waste_tons,
    COUNT(*)                    AS trips
FROM dw.fact_trips f
JOIN dw.dim_station s USING (station_id)
JOIN dw.dim_truck t   USING (truck_id)
GROUP BY s.city, f.station_id, t.truck_type
WITH DATA;

CREATE UNIQUE INDEX IF NOT EXISTS ux_mv_max_waste_stats
    ON dw.mv_max_waste_stats (city, station_id, truck_type);

-- Run after every load (this is the final task of the Airflow DAG):
REFRESH MATERIALIZED VIEW CONCURRENTLY dw.mv_max_waste_stats;
