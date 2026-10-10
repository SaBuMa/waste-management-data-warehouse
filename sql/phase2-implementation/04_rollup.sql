-- =====================================================================
-- Task 14 — ROLLUP
-- Total waste collected along the hierarchy Year → City → Station.
-- ROLLUP removes columns right to left:
--   (Year, City, Station) → (Year, City) → (Year) → () grand total
-- Note: with DESC, PostgreSQL sorts NULLs first, so the grand total
-- row appears at the top of the result.
-- =====================================================================

SELECT
    d.Year,
    s.City,
    f.Stationid,
    SUM(f.Wastecollected) AS TotalWasteCollected
FROM FactTrips f
JOIN DimDate d    ON f.Dateid    = d.Dateid
JOIN DimStation s ON f.Stationid = s.Stationid
GROUP BY ROLLUP (d.Year, s.City, f.Stationid)
ORDER BY
    d.Year DESC,
    s.City,
    f.Stationid;
