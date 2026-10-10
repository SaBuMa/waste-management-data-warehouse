-- =====================================================================
-- Supplementary — Data validation checks (not part of the graded tasks)
-- Quick checks that the load and the joins are trustworthy.
-- =====================================================================

-- 1) Grand total from the fact table alone.
--    Must equal the grand-total row of the GROUPING SETS / ROLLUP
--    queries; if it differs, a join lost or duplicated rows.
SELECT SUM(Wastecollected) AS fact_grand_total FROM FactTrips;

-- 2) Orphan check: trips pointing to a missing dimension row.
--    (Foreign keys already prevent this; kept as an explicit test.)
SELECT COUNT(*) AS orphan_trips
FROM FactTrips f
LEFT JOIN DimStation s ON f.Stationid = s.Stationid
LEFT JOIN DimTruck   t ON f.Truckid   = t.Truckid
LEFT JOIN DimDate    d ON f.Dateid    = d.Dateid
WHERE s.Stationid IS NULL OR t.Truckid IS NULL OR d.dateid IS NULL;

-- 3) Weekday consistency in the source DimDate file.
--    Compares the provided WeekdayName with the real calendar day.
--    See docs/DATA_QUALITY.md for the finding.
SELECT COUNT(*) AS mismatched_weekdays
FROM DimDate
WHERE TRIM(TO_CHAR(date, 'Day')) <> WeekdayName;

SELECT dateid, date,
       WeekdayName                AS weekday_in_file,
       TRIM(TO_CHAR(date, 'Day')) AS actual_weekday
FROM DimDate
ORDER BY dateid
LIMIT 5;
