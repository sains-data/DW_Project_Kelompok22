
-- ====================================
-- 1. DATABASE DAN STAGING
-- ====================================
CREATE DATABASE DW_PTXYZ;
GO

USE DW_PTXYZ;
GO

-- Tabel Staging untuk data produksi
CREATE TABLE staging_production (
    production_date DATE,
    site NVARCHAR(100),
    material NVARCHAR(100),
    material_type NVARCHAR(50),
    unit NVARCHAR(20),
    operator NVARCHAR(100),
    shift NVARCHAR(20),
    volume FLOAT,
    target FLOAT
);
GO

-- ====================================
-- 2. TABEL FAKTA DAN DIMENSI
-- ====================================

-- Dimensi Waktu
CREATE TABLE dim_time (
    time_key INT PRIMARY KEY,
    full_date DATE,
    day INT,
    month INT,
    year INT,
    day_name NVARCHAR(20)
);

-- Dimensi Material
CREATE TABLE dim_material (
    material_key INT IDENTITY(1,1) PRIMARY KEY,
    material_name NVARCHAR(100),
    material_type NVARCHAR(50),
    unit_of_measure NVARCHAR(20)
);

-- Tabel Fakta Produksi
CREATE TABLE fact_production (
    production_id INT IDENTITY(1,1) PRIMARY KEY,
    time_key INT FOREIGN KEY REFERENCES dim_time(time_key),
    material_key INT FOREIGN KEY REFERENCES dim_material(material_key),
    site NVARCHAR(100),
    employee NVARCHAR(100),
    shift NVARCHAR(50),
    volume_produced FLOAT,
    production_target FLOAT
);
GO

-- ====================================
-- 3. LOAD DATA (ETL SEDERHANA)
-- ====================================

-- Load ke dim_time
INSERT INTO dim_time (time_key, full_date, day, month, year, day_name)
SELECT DISTINCT
    CONVERT(INT, FORMAT(production_date, 'yyyyMMdd')),
    production_date,
    DAY(production_date),
    MONTH(production_date),
    YEAR(production_date),
    DATENAME(WEEKDAY, production_date)
FROM staging_production;

-- Load ke dim_material
INSERT INTO dim_material (material_name, material_type, unit_of_measure)
SELECT DISTINCT material, material_type, unit
FROM staging_production;

-- Load ke fact_production
INSERT INTO fact_production (
    time_key, material_key, site, employee, shift, volume_produced, production_target
)
SELECT 
    CONVERT(INT, FORMAT(S.production_date, 'yyyyMMdd')),
    M.material_key,
    S.site,
    S.operator,
    S.shift,
    S.volume,
    S.target
FROM staging_production S
JOIN dim_material M ON S.material = M.material_name;
GO

-- ====================================
-- 4. QUERY ANALYTIC
-- ====================================

-- Top 5 Material berdasarkan Produksi
SELECT TOP 5 M.material_name, SUM(F.volume_produced) AS total_volume
FROM fact_production F
JOIN dim_material M ON F.material_key = M.material_key
GROUP BY M.material_name
ORDER BY total_volume DESC;

-- Produksi Harian
SELECT T.full_date, SUM(F.volume_produced) AS daily_total
FROM fact_production F
JOIN dim_time T ON F.time_key = T.time_key
GROUP BY T.full_date
ORDER BY T.full_date;
