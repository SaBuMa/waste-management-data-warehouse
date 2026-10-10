-- =====================================================================
-- Enhanced edition · 02 — Load the CSVs into staging (psql script)
-- Run from the repository root. Staging is emptied first, so the step
-- can be re-run safely. (The Airflow DAG does the same with COPY.)
-- =====================================================================

TRUNCATE staging.dim_date_raw, staging.dim_truck_raw,
         staging.dim_station_raw, staging.fact_trips_raw;

\copy staging.dim_date_raw    FROM 'data/DimDate.csv'    CSV HEADER;
\copy staging.dim_truck_raw   FROM 'data/DimTruck.csv'   CSV HEADER;
\copy staging.dim_station_raw FROM 'data/DimStation.csv' CSV HEADER;
\copy staging.fact_trips_raw  FROM 'data/FactTrips.csv'  CSV HEADER;
