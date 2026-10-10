# ⚡ Enhanced Edition

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Apache Airflow](https://img.shields.io/badge/Apache%20Airflow-017CEE?style=for-the-badge&logo=apacheairflow&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)

The [core project](../README.md) builds the warehouse exactly as the IBM course specifies. This edition rebuilds it the way a production pipeline would: **layered, validated, idempotent, and orchestrated**.

It uses the same source CSVs and produces the same totals (3,987,925.34 tons across 106,400 trips), but it can now be re-run safely, it rejects bad loads, it corrects a defect in the source data, and it refreshes its reports on a schedule.

---

## 📑 Contents

- [What Changed](#-what-changed)
- [Pipeline Architecture](#-pipeline-architecture)
- [Files](#-files)
- [Data Quality Gate](#-data-quality-gate)
- [Report-Ready Output](#-report-ready-output)
- [Orchestration with Airflow](#-orchestration-with-airflow)
- [How to Run](#-how-to-run)

---

## 🔄 What Changed

| Area | Core version | Enhanced edition |
|---|---|---|
| **Layers** | CSVs loaded straight into the final tables | `staging` schema (raw TEXT) → `dw` schema (typed, clean) |
| **Naming** | Mixed case; columns named `date`, `Year`, `Day` | Consistent `snake_case`; `full_date`, `calendar_year`, `day_of_month` |
| **Constraints** | Primary and foreign keys | Plus `NOT NULL` everywhere and `CHECK` rules (e.g. `quarter_num BETWEEN 1 AND 4`, `waste_collected_tons > 0`) |
| **Date attributes** | Copied from the source file, **including wrong weekdays** | **Derived from the date itself**, which fixes all 350 shifted weekday names |
| **Date dimension** | Weekday as text only | Adds `is_weekend` for weekday vs weekend reporting |
| **Re-runs** | Reloading fails on duplicate keys | Upserts (`INSERT … ON CONFLICT`): safe to re-run, corrections overwrite |
| **Atomicity** | Each table loaded separately | Warehouse load runs in **one transaction**: all or nothing |
| **Validation** | Manual checks | Automated **quality gate** that stops the pipeline on failure |
| **Performance** | No secondary indexes | Indexes on the fact table's foreign keys; `ANALYZE` after load |
| **Subtotal rows** | `NULL` in key columns | Labeled (`All stations`) with `GROUPING()`, plus a `level` column |
| **Ordering** | `DESC` put the grand total first | `NULLS LAST`: details first, totals after |
| **Averages** | `37.3756500672947510` | `ROUND(…, 2)` → `37.38`, plus a trip count |
| **Business reports** | Ad-hoc queries | Six named views, one per report the company requested |
| **Materialized view** | Plain refresh (locks readers) | Unique index → `REFRESH … CONCURRENTLY` (readers never blocked) |
| **Orchestration** | Manual, in pgAdmin | Airflow DAG and a one-command Bash runner |

---

## 🏗️ Pipeline Architecture

```
  data/*.csv
      │  COPY
      ▼
┌───────────────┐   cast · trim · derive   ┌───────────────┐
│    staging    │   dates · upsert in one  │      dw       │
│ (raw, TEXT)   ├────── transaction ──────▶│ star schema   │
└───────────────┘                          └───────┬───────┘
                                                   │
                                         ┌─────────▼─────────┐
                                         │   quality gate    │──✖ FAIL → stop
                                         └─────────┬─────────┘
                                          PASS     │
                               ┌───────────────────┴───────────────────┐
                               ▼                                       ▼
                      report views (6)                  mv_max_waste_stats
                                                        (refresh concurrently)
```

**Why a staging layer?** Think of it as a loading dock. Deliveries are unpacked and inspected there before anything goes onto the store shelves. A malformed value can land in staging (everything is `TEXT`) without breaking the load, and the transform step decides what reaches the warehouse.

---

## 📂 Files

```
enhanced/
├── README.md
├── run_pipeline.sh                  # runs the whole pipeline with psql
├── sql/
│   ├── 00_schemas.sql               # staging + dw schemas
│   ├── 01_staging_tables.sql        # raw tables mirroring the CSVs
│   ├── 02_load_staging.sql          # \copy CSVs → staging (psql)
│   ├── 03_dw_tables.sql             # star schema with constraints + indexes
│   ├── 04_transform_load.sql        # staging → dw, derived dates, upserts
│   ├── 05_data_quality.sql          # quality checks view + gate
│   ├── 06_report_views.sql          # six business report views
│   ├── 07_olap_queries.sql          # labeled GROUPING SETS / ROLLUP / CUBE
│   └── 08_materialized_view.sql     # mv + unique index + concurrent refresh
└── airflow/
    └── dags/
        └── waste_dw_pipeline.py     # Airflow orchestration
```

---

## 🛡️ Data Quality Gate

`dw.v_data_quality` runs six checks after every load. Result on the provided data:

| Check | Status | Detail |
|---|---|---|
| fact row count matches staging | ✅ PASS | staging = 106,400, dw = 106,400 |
| waste total matches staging | ✅ PASS | 3,987,925.34 = 3,987,925.34 |
| no duplicate trip ids in source | ✅ PASS | 0 duplicates |
| date dimension has no gaps | ✅ PASS | 350 days loaded, 350 expected |
| warehouse weekday names are correct | ✅ PASS | 0 mismatches |
| source weekday names are correct | ⚠️ WARN | 350 rows wrong in DimDate.csv (corrected during transform) |

- **FAIL** means the load itself is wrong. The gate raises an error, the pipeline stops, and reports keep their last good data.
- **WARN** flags a problem in the *source* that the pipeline already handled. It is reported, not blocked.

The gate was tested by deleting one trip from the warehouse. Both totals checks switched to FAIL, and the gate raised:

```
ERROR:  Data quality gate failed: fact row count matches staging; waste total matches staging
```

**About the weekday fix:** with the source labels, every weekday report shows the previous day's tonnage (the "Monday" total is really Sunday's). Deriving `weekday_name`, `iso_weekday` and `is_weekend` from `full_date` removes the dependency on upstream labels entirely. See [../docs/DATA_QUALITY.md](../docs/DATA_QUALITY.md) for the original finding.

---

## 📊 Report-Ready Output

**GROUPING SETS** with labels instead of `NULL` (excerpt):

| station | truck_type | level | total_waste_tons |
|---|---|---|---:|
| 19 | Scania | detail | 248,915.75 |
| 19 | Volvo | detail | 83,901.03 |
| 19 | All truck types | station subtotal | 332,816.78 |
| All stations | Scania | truck type subtotal | 2,079,167.04 |
| All stations | Volvo | truck type subtotal | 1,908,758.30 |
| All stations | All truck types | **grand total** | **3,987,925.34** |

`GROUPING()` is used instead of `IS NULL`, so a genuine `NULL` in the data could never be mistaken for a subtotal row.

**Business report views**, one per requirement in the scenario:

| View | Report |
|---|---|
| `dw.v_waste_by_year_city` | Total waste per year per city |
| `dw.v_waste_by_month_city` | Total waste per month per city |
| `dw.v_waste_by_quarter_city` | Total waste per quarter per city |
| `dw.v_waste_by_year_truck_type` | Total waste per year per truck type |
| `dw.v_waste_by_truck_type_city` | Total waste per truck type per city |
| `dw.v_waste_by_truck_type_station_city` | Total waste per truck type per station per city |

```sql
SELECT * FROM dw.v_waste_by_quarter_city ORDER BY calendar_year, quarter_name, city;
```

---

## 🌀 Orchestration with Airflow

[`waste_dw_pipeline.py`](airflow/dags/waste_dw_pipeline.py) runs the pipeline daily:

```
create_objects → load_staging → transform_load → quality_gate ─┬─▶ build_report_views
                                                               └─▶ refresh_max_waste_stats
```

| Task | Operator | What it does |
|---|---|---|
| `create_objects` | SQLExecuteQueryOperator | Schemas and tables (`IF NOT EXISTS`) |
| `load_staging` | PythonOperator | Truncates staging and bulk-loads each CSV with `COPY` in one transaction |
| `transform_load` | SQLExecuteQueryOperator | Staging → warehouse upsert |
| `quality_gate` | SQLExecuteQueryOperator | Fails the task (and the run) if any check fails |
| `build_report_views` | SQLExecuteQueryOperator | Recreates the six report views |
| `refresh_max_waste_stats` | SQLExecuteQueryOperator | Concurrent refresh of the materialized view |

The two final tasks only run after the gate passes, so dashboards never see a bad load.

**Setup:** Airflow 2.x with `apache-airflow-providers-postgres` and `apache-airflow-providers-common-sql`, and a connection `waste_dw_postgres` pointing to the `finalproject` database. Optionally set `WASTE_DW_SQL_DIR` and `WASTE_DW_DATA_DIR` if the files are not read from the repository.

> **Testing note:** every SQL file the DAG executes was run against PostgreSQL 16 with the real data. The DAG file was checked for syntax, task wiring and file paths, but it has not yet been executed inside an Airflow instance.

---

## ▶️ How to Run

From the repository root:

```bash
# 1. Create the database (once)
psql -U postgres -c "CREATE DATABASE FinalProject;"

# 2. Run the whole pipeline (safe to repeat)
PGUSER=postgres bash enhanced/run_pipeline.sh

# 3. Explore the results
psql -U postgres -d finalproject -f enhanced/sql/07_olap_queries.sql
psql -U postgres -d finalproject -c "SELECT * FROM dw.v_data_quality;"
```

The enhanced edition lives in its own `staging` and `dw` schemas, so it can share the `finalproject` database with the core tables without conflicts.
