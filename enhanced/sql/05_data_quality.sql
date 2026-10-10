-- =====================================================================
-- Enhanced edition · 05 — Data quality checks + quality gate
-- dw.v_data_quality lists every check with PASS / FAIL / WARN.
--   FAIL → the load is wrong and must not be published
--   WARN → a problem in the SOURCE that the pipeline already handled
-- The DO block at the end is the "gate": it raises an error if any check
-- fails, which stops the pipeline (and fails the Airflow task).
-- =====================================================================

CREATE OR REPLACE VIEW dw.v_data_quality AS
WITH c AS (
    SELECT
        (SELECT COUNT(*) FROM staging.fact_trips_raw)                        AS stg_trips,
        (SELECT COUNT(*) FROM dw.fact_trips)                                 AS dw_trips,
        (SELECT COALESCE(SUM(wastecollected::NUMERIC), 0)
           FROM staging.fact_trips_raw)                                      AS stg_total,
        (SELECT COALESCE(SUM(waste_collected_tons), 0) FROM dw.fact_trips)   AS dw_total,
        (SELECT COUNT(*) - COUNT(DISTINCT tripid)
           FROM staging.fact_trips_raw)                                      AS dup_trip_ids,
        (SELECT COUNT(*) FROM dw.dim_date
          WHERE weekday_name <> TRIM(TO_CHAR(full_date, 'Day')))             AS dw_bad_weekdays,
        (SELECT COUNT(*) FROM staging.dim_date_raw
          WHERE TRIM(weekdayname) <> TRIM(TO_CHAR(date::DATE, 'Day')))       AS src_bad_weekdays,
        (SELECT COUNT(*) FROM dw.dim_date)                                   AS dw_dates,
        (SELECT MAX(full_date) - MIN(full_date) + 1 FROM dw.dim_date)        AS expected_dates
)
SELECT check_name, status, detail FROM c,
LATERAL (VALUES
    ('fact row count matches staging',
     CASE WHEN dw_trips = stg_trips THEN 'PASS' ELSE 'FAIL' END,
     format('staging=%s, dw=%s', stg_trips, dw_trips)),

    ('waste total matches staging',
     CASE WHEN dw_total = stg_total THEN 'PASS' ELSE 'FAIL' END,
     format('staging=%s, dw=%s', stg_total, dw_total)),

    ('no duplicate trip ids in source',
     CASE WHEN dup_trip_ids = 0 THEN 'PASS' ELSE 'FAIL' END,
     format('%s duplicates', dup_trip_ids)),

    ('date dimension has no gaps',
     CASE WHEN dw_dates = expected_dates THEN 'PASS' ELSE 'FAIL' END,
     format('%s days loaded, %s expected', dw_dates, expected_dates)),

    ('warehouse weekday names are correct',
     CASE WHEN dw_bad_weekdays = 0 THEN 'PASS' ELSE 'FAIL' END,
     format('%s mismatches', dw_bad_weekdays)),

    ('source weekday names are correct',
     CASE WHEN src_bad_weekdays = 0 THEN 'PASS' ELSE 'WARN' END,
     format('%s rows wrong in DimDate.csv (corrected during transform)',
            src_bad_weekdays))
) AS v(check_name, status, detail);

-- Show the report
SELECT * FROM dw.v_data_quality;

-- Quality gate: stop if anything failed
DO $$
DECLARE failed TEXT;
BEGIN
    SELECT string_agg(check_name, '; ') INTO failed
    FROM dw.v_data_quality WHERE status = 'FAIL';

    IF failed IS NOT NULL THEN
        RAISE EXCEPTION 'Data quality gate failed: %', failed;
    END IF;
END $$;
