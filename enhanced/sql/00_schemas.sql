-- =====================================================================
-- Enhanced edition · 00 — Schemas
-- Two layers keep raw input separate from the clean warehouse:
--   staging → exact copy of the source CSVs (untrusted)
--   dw      → typed, validated star schema used for reporting
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dw;
