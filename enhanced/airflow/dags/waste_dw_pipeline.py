"""
Waste Management Data Warehouse: daily load + refresh pipeline
=================================================================

Orchestrates the enhanced edition of the warehouse with Apache Airflow:

    create_objects → load_staging → transform_load → quality_gate
                                                         │
                                       ┌─────────────────┴─────────────────┐
                                       ▼                                   ▼
                              build_report_views                 refresh_max_waste_stats

Every step is idempotent (safe to re-run), and the quality gate stops the
run before any report or materialized view is refreshed with bad data.

Requirements
------------
* Airflow 2.x with the providers:
    apache-airflow-providers-postgres
    apache-airflow-providers-common-sql
* An Airflow connection named ``waste_dw_postgres`` pointing to the
  ``finalproject`` database.
* Environment variables (optional, defaults shown):
    WASTE_DW_SQL_DIR   = <repo>/enhanced/sql
    WASTE_DW_DATA_DIR  = <repo>/data
"""

from __future__ import annotations

import os
from datetime import datetime, timedelta
from pathlib import Path

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
CONN_ID = "waste_dw_postgres"

# When the DAG runs straight from the repo, paths resolve relative to it.
# In a real deployment, point the env vars to wherever the files live.
REPO_ROOT = Path(__file__).resolve().parents[3]
SQL_DIR = Path(os.getenv("WASTE_DW_SQL_DIR", REPO_ROOT / "enhanced" / "sql"))
DATA_DIR = Path(os.getenv("WASTE_DW_DATA_DIR", REPO_ROOT / "data"))

# CSV file → staging table
STAGING_FILES = {
    "DimDate.csv": "staging.dim_date_raw",
    "DimTruck.csv": "staging.dim_truck_raw",
    "DimStation.csv": "staging.dim_station_raw",
    "FactTrips.csv": "staging.fact_trips_raw",
}

default_args = {
    "owner": "santiago.burgos",
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}


# ---------------------------------------------------------------------------
# Python callables
# ---------------------------------------------------------------------------
def load_staging() -> None:
    """Empty the staging tables and bulk-load each CSV with COPY.

    COPY is PostgreSQL's fastest bulk-load path (the server-side equivalent of
    psql's \\copy). Everything runs in one transaction, so staging is either
    fully replaced or left untouched.
    """
    hook = PostgresHook(postgres_conn_id=CONN_ID)
    conn = hook.get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("TRUNCATE " + ", ".join(STAGING_FILES.values()) + ";")
            for file_name, table in STAGING_FILES.items():
                path = DATA_DIR / file_name
                if not path.exists():
                    raise FileNotFoundError(f"Source file not found: {path}")
                with open(path, encoding="utf-8") as f:
                    cur.copy_expert(f"COPY {table} FROM STDIN WITH (FORMAT csv, HEADER true)", f)
                cur.execute(f"SELECT COUNT(*) FROM {table};")
                print(f"Loaded {cur.fetchone()[0]:>7} rows into {table}")
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# DAG
# ---------------------------------------------------------------------------
with DAG(
    dag_id="waste_dw_pipeline",
    description="Load trip CSVs into the waste management star schema, validate, and refresh reports",
    default_args=default_args,
    start_date=datetime(2026, 1, 1),
    schedule="@daily",
    catchup=False,
    template_searchpath=[str(SQL_DIR)],
    tags=["data-warehouse", "postgres", "ibm-data-engineering"],
) as dag:

    # 1. Schemas and tables. All statements use IF NOT EXISTS.
    create_objects = SQLExecuteQueryOperator(
        task_id="create_objects",
        conn_id=CONN_ID,
        sql=["00_schemas.sql", "01_staging_tables.sql", "03_dw_tables.sql"],
    )

    # 2. Raw CSVs → staging
    load_staging_task = PythonOperator(
        task_id="load_staging",
        python_callable=load_staging,
    )

    # 3. Staging → warehouse (typed, cleaned, upserted, one transaction)
    transform_load = SQLExecuteQueryOperator(
        task_id="transform_load",
        conn_id=CONN_ID,
        sql="04_transform_load.sql",
        autocommit=True,  # the file manages its own BEGIN / COMMIT
    )

    # 4. Quality gate: raises (and fails this task) if any check FAILS
    quality_gate = SQLExecuteQueryOperator(
        task_id="quality_gate",
        conn_id=CONN_ID,
        sql="05_data_quality.sql",
        show_return_value_in_logs=True,
    )

    # 5a. Business report views (CREATE OR REPLACE)
    build_report_views = SQLExecuteQueryOperator(
        task_id="build_report_views",
        conn_id=CONN_ID,
        sql="06_report_views.sql",
    )

    # 5b. Materialized view: created on first run, refreshed concurrently after
    refresh_max_waste_stats = SQLExecuteQueryOperator(
        task_id="refresh_max_waste_stats",
        conn_id=CONN_ID,
        sql="08_materialized_view.sql",
    )

    create_objects >> load_staging_task >> transform_load >> quality_gate
    quality_gate >> [build_report_views, refresh_max_waste_stats]
