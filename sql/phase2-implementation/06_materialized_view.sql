-- =====================================================================
-- Task 16 — Materialized view: max_waste_stats
-- Maximum waste collected in a single trip by city, station and
-- truck type. Results are stored, so reads are instant; refresh the
-- view after new trips are loaded.
-- =====================================================================

CREATE MATERIALIZED VIEW max_waste_stats AS
SELECT
    s.City,
    f.Stationid,
    t.TruckType,
    MAX(f.Wastecollected) AS MaxWasteCollected
FROM FactTrips f
JOIN DimStation s ON f.Stationid = s.Stationid
JOIN DimTruck t   ON f.Truckid   = t.Truckid
GROUP BY
    s.City,
    f.Stationid,
    t.TruckType
WITH DATA;

-- Read the stored results
SELECT * FROM max_waste_stats ORDER BY City, Stationid, TruckType;

-- After loading new data:
-- REFRESH MATERIALIZED VIEW max_waste_stats;
