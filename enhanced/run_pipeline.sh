#!/usr/bin/env bash
# =====================================================================
# Runs the full enhanced pipeline with psql, in order, stopping at the
# first error. Run from the repository root:
#
#   bash enhanced/run_pipeline.sh
#
# Connection settings come from the standard libpq variables
# (PGHOST, PGPORT, PGUSER, PGPASSWORD). Database defaults to finalproject.
# =====================================================================
set -euo pipefail

DB="${PGDATABASE:-finalproject}"
SQL_DIR="enhanced/sql"

run() {
    echo "▶ $1"
    psql -X -q -v ON_ERROR_STOP=1 -d "$DB" -f "$SQL_DIR/$1"
}

run 00_schemas.sql
run 01_staging_tables.sql
run 02_load_staging.sql
run 03_dw_tables.sql
run 04_transform_load.sql
run 05_data_quality.sql        # stops here if any check FAILS
run 06_report_views.sql
run 08_materialized_view.sql

echo "✔ Pipeline finished. Explore results with: psql -d $DB -f $SQL_DIR/07_olap_queries.sql"
