-- =====================================================================
-- Phase 1 — Initial star schema design (Tasks 1–8)
-- Database : Project (PostgreSQL)
-- Purpose  : First design based on the sample data supplied by the
--            company (trip, waste type, tons, zone, city, date).
-- Note     : This design was later replaced (see phase2-implementation)
--            when the company changed the data it could collect.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Dimension: MyDimDate (day granularity → year / month / day / weekday)
-- ---------------------------------------------------------------------
CREATE TABLE MyDimDate (
    dateid      INT PRIMARY KEY,
    year        INT,
    month       INT,
    monthname   VARCHAR(20),
    day         INT,
    weekday     INT,
    weekdayname VARCHAR(20)
);

-- ---------------------------------------------------------------------
-- Dimension: MyDimWaste (descriptive only — the tonnage is a measure
-- and therefore lives in the fact table)
-- ---------------------------------------------------------------------
CREATE TABLE MyDimWaste (
    wasteid   INT PRIMARY KEY,
    wastetype VARCHAR(20)
);

-- ---------------------------------------------------------------------
-- Dimension: MyDimZone (zone + city together: "South" alone is
-- ambiguous, "South, Sao Paulo" identifies a place)
-- ---------------------------------------------------------------------
CREATE TABLE MyDimZone (
    zoneid         INT PRIMARY KEY,
    collectionzone VARCHAR(20),
    city           VARCHAR(100)
);

-- ---------------------------------------------------------------------
-- Fact: MyFactTrips (foreign keys + the measure)
-- ---------------------------------------------------------------------
CREATE TABLE MyFactTrips (
    tripnumber  INT PRIMARY KEY,
    dateid      INT REFERENCES MyDimDate(dateid),
    wasteid     INT REFERENCES MyDimWaste(wasteid),
    zoneid      INT REFERENCES MyDimZone(zoneid),
    wasteamount DECIMAL(10,2)   -- tons, e.g. 45.23 (INT would round it)
);
