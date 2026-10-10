-- =====================================================================
-- Task 15 — CUBE
-- Average waste collected for every combination of Year, City and
-- Station (2³ = 8 groupings). Each subtotal average is computed from
-- the raw trips, not by averaging averages.
-- =====================================================================

SELECT
    d.Year,
    s.City,
    f.Stationid,
    AVG(f.Wastecollected) AS AverageWasteCollected
FROM FactTrips f
INNER JOIN DimDate d    ON f.Dateid    = d.Dateid
INNER JOIN DimStation s ON f.Stationid = s.Stationid
GROUP BY CUBE (d.Year, s.City, f.Stationid)
ORDER BY d.Year, s.City, f.Stationid;
