-- =====================================================================
-- Phase 2 — Final star schema (Tasks 9–12)
-- Database : FinalProject (PostgreSQL) — created in pgAdmin
-- Purpose  : Tables defined to match the CSV files provided by the
--            company after the change in data collection.
-- Order    : dimensions first, fact last (the fact references them)
-- =====================================================================

-- If running from psql instead of pgAdmin:
-- CREATE DATABASE FinalProject;
-- \c finalproject

-- ---------------------------------------------------------------------
-- Dimension: DimDate — one row per day, calendar attributes pre-split
-- ---------------------------------------------------------------------
CREATE TABLE DimDate (
    dateid      INT PRIMARY KEY,
    date        DATE NOT NULL,
    Year        INT NOT NULL,
    Quarter     INT NOT NULL,
    QuarterName VARCHAR(2) NOT NULL,
    Month       INT NOT NULL,
    Monthname   VARCHAR(255) NOT NULL,
    Day         INT NOT NULL,
    Weekday     INT NOT NULL,
    WeekdayName VARCHAR(255) NOT NULL
);

-- ---------------------------------------------------------------------
-- Dimension: DimTruck — truck and its type (Volvo / Scania)
-- ---------------------------------------------------------------------
CREATE TABLE DimTruck (
    Truckid   INT PRIMARY KEY,
    TruckType VARCHAR(255) NOT NULL
);

-- ---------------------------------------------------------------------
-- Dimension: DimStation — collection station and its city
-- ---------------------------------------------------------------------
CREATE TABLE DimStation (
    Stationid INT PRIMARY KEY,
    City      VARCHAR(255) NOT NULL
);

-- ---------------------------------------------------------------------
-- Fact: FactTrips — one row per collection trip
-- ---------------------------------------------------------------------
CREATE TABLE FactTrips (
    Tripid         INT PRIMARY KEY,
    Dateid         INT NOT NULL,
    Stationid      INT NOT NULL,
    Truckid        INT NOT NULL,
    Wastecollected DECIMAL(10,2) NOT NULL,   -- tons, two decimals
    FOREIGN KEY (Dateid)    REFERENCES DimDate(Dateid),
    FOREIGN KEY (Truckid)   REFERENCES DimTruck(Truckid),
    FOREIGN KEY (Stationid) REFERENCES DimStation(Stationid)
);
