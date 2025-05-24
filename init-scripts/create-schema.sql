-- PT XYZ Data Warehouse - Database Schema Creation Script
-- Created: 2025-05-24
-- Description: Creates dimensional model for PT XYZ mining data warehouse

USE PTXYZ_DataWarehouse;
GO

-- Create schemas for organization
CREATE SCHEMA dim;
GO
CREATE SCHEMA fact;
GO
CREATE SCHEMA staging;
GO

-- ======================
-- DIMENSION TABLES
-- ======================

-- Time Dimension
CREATE TABLE dim.DimTime (
    time_key INT IDENTITY(1,1) PRIMARY KEY,
    time_id INT NOT NULL,
    date DATE NOT NULL,
    day_of_month INT NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter INT NOT NULL,
    year INT NOT NULL,
    is_weekend BIT NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    created_by VARCHAR(50) DEFAULT 'System'
);

-- Site Dimension
CREATE TABLE dim.DimSite (
    site_key INT IDENTITY(1,1) PRIMARY KEY,
    site_id INT NOT NULL,
    site_name VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    created_at DATETIME2 DEFAULT GETDATE(),
    created_by VARCHAR(50) DEFAULT 'System'
);

-- Equipment Dimension
CREATE TABLE dim.DimEquipment (
    equipment_key INT IDENTITY(1,1) PRIMARY KEY,
    equipment_name VARCHAR(100) NOT NULL,
    equipment_type VARCHAR(50) NOT NULL,
    manufacture VARCHAR(50),
    model VARCHAR(50),
    capacity DECIMAL(10,2),
    purchase_date DATE,
    created_at DATETIME2 DEFAULT GETDATE(),
    created_by VARCHAR(50) DEFAULT 'System'
);

-- Material Dimension
CREATE TABLE dim.DimMaterial (
    material_key INT IDENTITY(1,1) PRIMARY KEY,
    material_id INT NOT NULL,
    material_name VARCHAR(100) NOT NULL,
    material_type VARCHAR(50) NOT NULL,
    unit_of_measure VARCHAR(20) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    created_by VARCHAR(50) DEFAULT 'System'
);

-- Employee Dimension
CREATE TABLE dim.DimEmployee (
    employee_key INT IDENTITY(1,1) PRIMARY KEY,
    employee_id INT NOT NULL,
    employee_name VARCHAR(100) NOT NULL,
    position VARCHAR(50),
    department VARCHAR(50),
    status VARCHAR(20),
    hire_date DATE,
    created_at DATETIME2 DEFAULT GETDATE(),
    created_by VARCHAR(50) DEFAULT 'System'
);

-- Shift Dimension
CREATE TABLE dim.DimShift (
    shift_key INT IDENTITY(1,1) PRIMARY KEY,
    shift_id INT NOT NULL,
    shift_name VARCHAR(50) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    created_by VARCHAR(50) DEFAULT 'System'
);

-- Project Dimension
CREATE TABLE dim.DimProject (
    project_key INT IDENTITY(1,1) PRIMARY KEY,
    project_id INT NOT NULL,
    project_name VARCHAR(100) NOT NULL,
    project_manager VARCHAR(100),
    status VARCHAR(20),
    start_date DATE,
    end_date DATE,
    created_at DATETIME2 DEFAULT GETDATE(),
    created_by VARCHAR(50) DEFAULT 'System'
);

-- Account Dimension
CREATE TABLE dim.DimAccount (
    account_key INT IDENTITY(1,1) PRIMARY KEY,
    account_id INT NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    account_type VARCHAR(50),
    budget_category VARCHAR(50),
    created_at DATETIME2 DEFAULT GETDATE(),
    created_by VARCHAR(50) DEFAULT 'System'
);

-- ======================
-- FACT TABLES
-- ======================

-- Equipment Usage Fact
CREATE TABLE fact.FactEquipmentUsage (
    usage_key INT IDENTITY(1,1) PRIMARY KEY,
    equipment_usage_id INT NOT NULL,
    time_key INT NOT NULL,
    site_key INT NOT NULL,
    equipment_key INT NOT NULL,
    operating_hours DECIMAL(8,2),
    downtime_hours DECIMAL(8,2),
    fuel_consumption DECIMAL(10,2),
    maintenance_cost DECIMAL(12,2),
    efficiency_ratio AS (CASE WHEN (operating_hours + downtime_hours) > 0 
                         THEN operating_hours / (operating_hours + downtime_hours) 
                         ELSE 0 END),
    created_at DATETIME2 DEFAULT GETDATE(),
    created_by VARCHAR(50) DEFAULT 'ETL',
    
    FOREIGN KEY (time_key) REFERENCES dim.DimTime(time_key),
    FOREIGN KEY (site_key) REFERENCES dim.DimSite(site_key),
    FOREIGN KEY (equipment_key) REFERENCES dim.DimEquipment(equipment_key)
);

-- Production Fact
CREATE TABLE fact.FactProduction (
    production_key INT IDENTITY(1,1) PRIMARY KEY,
    production_id INT NOT NULL,
    time_key INT NOT NULL,
    site_key INT NOT NULL,
    material_key INT NOT NULL,
    employee_key INT NOT NULL,
    shift_key INT NOT NULL,
    produced_volume DECIMAL(12,2),
    unit_cost DECIMAL(10,2),
    total_cost AS (produced_volume * unit_cost),
    material_quantity DECIMAL(12,2),
    created_at DATETIME2 DEFAULT GETDATE(),
    created_by VARCHAR(50) DEFAULT 'ETL',
    
    FOREIGN KEY (time_key) REFERENCES dim.DimTime(time_key),
    FOREIGN KEY (site_key) REFERENCES dim.DimSite(site_key),
    FOREIGN KEY (material_key) REFERENCES dim.DimMaterial(material_key),
    FOREIGN KEY (employee_key) REFERENCES dim.DimEmployee(employee_key),
    FOREIGN KEY (shift_key) REFERENCES dim.DimShift(shift_key)
);

-- Financial Transaction Fact
CREATE TABLE fact.FactFinancialTransaction (
    transaction_key INT IDENTITY(1,1) PRIMARY KEY,
    transaction_id INT NOT NULL,
    time_key INT NOT NULL,
    site_key INT NOT NULL,
    project_key INT NOT NULL,
    account_key INT NOT NULL,
    budgeted_cost DECIMAL(12,2),
    actual_cost DECIMAL(12,2),
    variance_amount AS (budgeted_cost - actual_cost),
    variance_percentage AS (CASE WHEN budgeted_cost > 0 
                           THEN ((budgeted_cost - actual_cost) / budgeted_cost) * 100 
                           ELSE 0 END),
    variance_status VARCHAR(20),
    account_cost DECIMAL(12,2),
    created_at DATETIME2 DEFAULT GETDATE(),
    created_by VARCHAR(50) DEFAULT 'ETL',
    
    FOREIGN KEY (time_key) REFERENCES dim.DimTime(time_key),
    FOREIGN KEY (site_key) REFERENCES dim.DimSite(site_key),
    FOREIGN KEY (project_key) REFERENCES dim.DimProject(project_key),
    FOREIGN KEY (account_key) REFERENCES dim.DimAccount(account_key)
);

-- ======================
-- STAGING TABLES
-- ======================

-- Staging table for Equipment Usage
CREATE TABLE staging.EquipmentUsage (
    equipment_usage_id INT,
    time_id INT,
    date DATE,
    day INT,
    day_name VARCHAR(20),
    month INT,
    year INT,
    site_name VARCHAR(100),
    region VARCHAR(50),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    equipment_name VARCHAR(100),
    equipment_type VARCHAR(50),
    manufacture VARCHAR(50),
    model VARCHAR(50),
    capacity DECIMAL(10,2),
    purchase_date DATE,
    operating_hours DECIMAL(8,2),
    downtime_hours DECIMAL(8,2),
    fuel_consumption DECIMAL(10,2),
    maintenance_cost DECIMAL(12,2),
    created_at DATETIME2,
    created_by VARCHAR(50)
);

-- Staging table for Production
CREATE TABLE staging.Production (
    production_id INT,
    time_id INT,
    site_id INT,
    material_id INT,
    employee_id INT,
    shift_id INT,
    produced_volume DECIMAL(12,2),
    unit_cost DECIMAL(10,2),
    date DATE,
    day INT,
    month INT,
    year INT,
    day_name VARCHAR(20),
    site_name VARCHAR(100),
    region VARCHAR(50),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    material_name VARCHAR(100),
    material_type VARCHAR(50),
    unit_of_measure VARCHAR(20),
    quantity DECIMAL(12,2),
    employee_name VARCHAR(100),
    position VARCHAR(50),
    department VARCHAR(50),
    status VARCHAR(20),
    hire_date DATE,
    shift_name VARCHAR(50),
    start_time TIME,
    end_time TIME
);

-- Staging table for Financial Transactions
CREATE TABLE staging.FinancialTransaction (
    id INT,
    time_id INT,
    site_id INT,
    project_id INT,
    account_id INT,
    variance VARCHAR(20),
    budgeted_cost DECIMAL(12,2),
    actual_cost DECIMAL(12,2),
    created_at DATETIME2,
    created_by VARCHAR(50),
    date DATE,
    day INT,
    day_name VARCHAR(20),
    month INT,
    year INT,
    site_name VARCHAR(100),
    region VARCHAR(50),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    project_name VARCHAR(100),
    project_manager VARCHAR(100),
    status VARCHAR(20),
    start_date DATE,
    end_date DATE,
    account_name VARCHAR(100),
    account_type VARCHAR(50),
    budget_category VARCHAR(50),
    cost DECIMAL(12,2)
);

-- ======================
-- INDEXES FOR PERFORMANCE
-- ======================

-- Time dimension indexes
CREATE INDEX IX_DimTime_Date ON dim.DimTime(date);
CREATE INDEX IX_DimTime_Year_Month ON dim.DimTime(year, month);

-- Site dimension indexes
CREATE INDEX IX_DimSite_Region ON dim.DimSite(region);
CREATE INDEX IX_DimSite_Name ON dim.DimSite(site_name);

-- Fact table indexes
CREATE INDEX IX_FactEquipmentUsage_Time ON fact.FactEquipmentUsage(time_key);
CREATE INDEX IX_FactEquipmentUsage_Site ON fact.FactEquipmentUsage(site_key);
CREATE INDEX IX_FactEquipmentUsage_Equipment ON fact.FactEquipmentUsage(equipment_key);

CREATE INDEX IX_FactProduction_Time ON fact.FactProduction(time_key);
CREATE INDEX IX_FactProduction_Site ON fact.FactProduction(site_key);
CREATE INDEX IX_FactProduction_Material ON fact.FactProduction(material_key);

CREATE INDEX IX_FactFinancialTransaction_Time ON fact.FactFinancialTransaction(time_key);
CREATE INDEX IX_FactFinancialTransaction_Site ON fact.FactFinancialTransaction(site_key);
CREATE INDEX IX_FactFinancialTransaction_Project ON fact.FactFinancialTransaction(project_key);

PRINT 'PT XYZ Data Warehouse schema created successfully!';
