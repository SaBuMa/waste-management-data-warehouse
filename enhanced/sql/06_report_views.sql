-- =====================================================================
-- Enhanced edition · 06 — Business report views
-- One view per report the company asked for in the scenario, so analysts
-- and BI tools can query them by name instead of rewriting joins.
-- =====================================================================

-- 1) Total waste per year per city
CREATE OR REPLACE VIEW dw.v_waste_by_year_city AS
SELECT d.calendar_year, s.city,
       SUM(f.waste_collected_tons) AS total_waste_tons
FROM dw.fact_trips f
JOIN dw.dim_date d    USING (date_key)
JOIN dw.dim_station s USING (station_id)
GROUP BY d.calendar_year, s.city;

-- 2) Total waste per month per city
CREATE OR REPLACE VIEW dw.v_waste_by_month_city AS
SELECT d.calendar_year, d.month_num, d.month_name, s.city,
       SUM(f.waste_collected_tons) AS total_waste_tons
FROM dw.fact_trips f
JOIN dw.dim_date d    USING (date_key)
JOIN dw.dim_station s USING (station_id)
GROUP BY d.calendar_year, d.month_num, d.month_name, s.city;

-- 3) Total waste per quarter per city
CREATE OR REPLACE VIEW dw.v_waste_by_quarter_city AS
SELECT d.calendar_year, d.quarter_name, s.city,
       SUM(f.waste_collected_tons) AS total_waste_tons
FROM dw.fact_trips f
JOIN dw.dim_date d    USING (date_key)
JOIN dw.dim_station s USING (station_id)
GROUP BY d.calendar_year, d.quarter_name, s.city;

-- 4) Total waste per year per truck type
CREATE OR REPLACE VIEW dw.v_waste_by_year_truck_type AS
SELECT d.calendar_year, t.truck_type,
       SUM(f.waste_collected_tons) AS total_waste_tons
FROM dw.fact_trips f
JOIN dw.dim_date d  USING (date_key)
JOIN dw.dim_truck t USING (truck_id)
GROUP BY d.calendar_year, t.truck_type;

-- 5) Total waste per truck type per city
CREATE OR REPLACE VIEW dw.v_waste_by_truck_type_city AS
SELECT t.truck_type, s.city,
       SUM(f.waste_collected_tons) AS total_waste_tons
FROM dw.fact_trips f
JOIN dw.dim_truck t   USING (truck_id)
JOIN dw.dim_station s USING (station_id)
GROUP BY t.truck_type, s.city;

-- 6) Total waste per truck type per station per city
CREATE OR REPLACE VIEW dw.v_waste_by_truck_type_station_city AS
SELECT t.truck_type, f.station_id, s.city,
       SUM(f.waste_collected_tons) AS total_waste_tons
FROM dw.fact_trips f
JOIN dw.dim_truck t   USING (truck_id)
JOIN dw.dim_station s USING (station_id)
GROUP BY t.truck_type, f.station_id, s.city;
