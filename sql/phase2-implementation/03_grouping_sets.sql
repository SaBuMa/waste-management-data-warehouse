-- =====================================================================
-- Task 13 — GROUPING SETS
-- Total waste collected by station and truck type, plus subtotals
-- per station, per truck type, and a grand total — in one query.
-- NULL in a key column means "all" (a subtotal row), not missing data.
-- =====================================================================

SELECT
    f.Stationid,
    t.TruckType,
    SUM(f.Wastecollected) AS TotalWasteCollected
FROM FactTrips f
INNER JOIN DimTruck t ON f.Truckid = t.Truckid
GROUP BY GROUPING SETS (
    (f.Stationid, t.TruckType),   -- each station × truck type
    f.Stationid,                  -- subtotal per station
    t.TruckType,                  -- subtotal per truck type
    ()                            -- grand total
)
ORDER BY f.Stationid, t.TruckType;
