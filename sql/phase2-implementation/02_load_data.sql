-- =====================================================================
-- Phase 2 — Load the CSV files
-- The project load was done with pgAdmin's Import/Export tool
-- (Format: csv · Header: on · Delimiter: ,).
-- Below is the equivalent psql script, run from the repository root.
-- Order matters: dimensions before the fact table (foreign keys).
-- =====================================================================

\copy DimDate    FROM 'data/DimDate.csv'    CSV HEADER;
\copy DimTruck   FROM 'data/DimTruck.csv'   CSV HEADER;
\copy DimStation FROM 'data/DimStation.csv' CSV HEADER;
\copy FactTrips  FROM 'data/FactTrips.csv'  CSV HEADER;

-- Expected row counts: 350 / 71 / 19 / 106,400
SELECT 'DimDate' AS table_name, COUNT(*) AS row_count FROM DimDate
UNION ALL SELECT 'DimTruck',   COUNT(*) FROM DimTruck
UNION ALL SELECT 'DimStation', COUNT(*) FROM DimStation
UNION ALL SELECT 'FactTrips',  COUNT(*) FROM FactTrips;
