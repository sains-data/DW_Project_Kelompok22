-- ================================================================
-- PT XYZ Data Warehouse - Performance Optimization Scripts
-- ================================================================
-- This script creates indexes and optimizations for better query performance

USE PTXYZ_DataWarehouse;
GO

PRINT '🚀 Starting Performance Optimization...';
PRINT '';

-- ================================================================
-- 1. DIMENSION TABLE INDEXES
-- ================================================================

PRINT '📊 Creating Dimension Table Indexes...';

-- DimTime indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DimTime_Date')
BEGIN
    CREATE INDEX IX_DimTime_Date ON dim.DimTime (date);
    PRINT '✅ Created IX_DimTime_Date index';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DimTime_YearMonth')
BEGIN
    CREATE INDEX IX_DimTime_YearMonth ON dim.DimTime (year, month);
    PRINT '✅ Created IX_DimTime_YearMonth index';
END

-- DimSite indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DimSite_Name')
BEGIN
    CREATE INDEX IX_DimSite_Name ON dim.DimSite (site_name);
    PRINT '✅ Created IX_DimSite_Name index';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DimSite_Type')
BEGIN
    CREATE INDEX IX_DimSite_Type ON dim.DimSite (site_type);
    PRINT '✅ Created IX_DimSite_Type index';
END

-- DimEquipment indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DimEquipment_Type')
BEGIN
    CREATE INDEX IX_DimEquipment_Type ON dim.DimEquipment (equipment_type);
    PRINT '✅ Created IX_DimEquipment_Type index';
END

-- DimMaterial indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DimMaterial_Type')
BEGIN
    CREATE INDEX IX_DimMaterial_Type ON dim.DimMaterial (material_type);
    PRINT '✅ Created IX_DimMaterial_Type index';
END

-- DimEmployee indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DimEmployee_Role')
BEGIN
    CREATE INDEX IX_DimEmployee_Role ON dim.DimEmployee (role);
    PRINT '✅ Created IX_DimEmployee_Role index';
END

-- DimProject indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DimProject_Status')
BEGIN
    CREATE INDEX IX_DimProject_Status ON dim.DimProject (project_status);
    PRINT '✅ Created IX_DimProject_Status index';
END

-- DimAccount indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DimAccount_Type')
BEGIN
    CREATE INDEX IX_DimAccount_Type ON dim.DimAccount (account_type);
    PRINT '✅ Created IX_DimAccount_Type index';
END

PRINT '';

-- ================================================================
-- 2. FACT TABLE INDEXES
-- ================================================================

PRINT '🎯 Creating Fact Table Indexes...';

-- FactEquipmentUsage indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FactEquipmentUsage_TimeKey')
BEGIN
    CREATE INDEX IX_FactEquipmentUsage_TimeKey ON fact.FactEquipmentUsage (time_key);
    PRINT '✅ Created IX_FactEquipmentUsage_TimeKey index';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FactEquipmentUsage_SiteKey')
BEGIN
    CREATE INDEX IX_FactEquipmentUsage_SiteKey ON fact.FactEquipmentUsage (site_key);
    PRINT '✅ Created IX_FactEquipmentUsage_SiteKey index';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FactEquipmentUsage_EquipmentKey')
BEGIN
    CREATE INDEX IX_FactEquipmentUsage_EquipmentKey ON fact.FactEquipmentUsage (equipment_key);
    PRINT '✅ Created IX_FactEquipmentUsage_EquipmentKey index';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FactEquipmentUsage_Composite')
BEGIN
    CREATE INDEX IX_FactEquipmentUsage_Composite ON fact.FactEquipmentUsage (time_key, site_key, equipment_key);
    PRINT '✅ Created IX_FactEquipmentUsage_Composite index';
END

-- FactProduction indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FactProduction_TimeKey')
BEGIN
    CREATE INDEX IX_FactProduction_TimeKey ON fact.FactProduction (time_key);
    PRINT '✅ Created IX_FactProduction_TimeKey index';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FactProduction_SiteKey')
BEGIN
    CREATE INDEX IX_FactProduction_SiteKey ON fact.FactProduction (site_key);
    PRINT '✅ Created IX_FactProduction_SiteKey index';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FactProduction_MaterialKey')
BEGIN
    CREATE INDEX IX_FactProduction_MaterialKey ON fact.FactProduction (material_key);
    PRINT '✅ Created IX_FactProduction_MaterialKey index';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FactProduction_Composite')
BEGIN
    CREATE INDEX IX_FactProduction_Composite ON fact.FactProduction (time_key, site_key, material_key);
    PRINT '✅ Created IX_FactProduction_Composite index';
END

-- FactFinancialTransaction indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FactFinancialTransaction_TimeKey')
BEGIN
    CREATE INDEX IX_FactFinancialTransaction_TimeKey ON fact.FactFinancialTransaction (time_key);
    PRINT '✅ Created IX_FactFinancialTransaction_TimeKey index';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FactFinancialTransaction_SiteKey')
BEGIN
    CREATE INDEX IX_FactFinancialTransaction_SiteKey ON fact.FactFinancialTransaction (site_key);
    PRINT '✅ Created IX_FactFinancialTransaction_SiteKey index';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FactFinancialTransaction_AccountKey')
BEGIN
    CREATE INDEX IX_FactFinancialTransaction_AccountKey ON fact.FactFinancialTransaction (account_key);
    PRINT '✅ Created IX_FactFinancialTransaction_AccountKey index';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FactFinancialTransaction_Composite')
BEGIN
    CREATE INDEX IX_FactFinancialTransaction_Composite ON fact.FactFinancialTransaction (time_key, site_key, account_key);
    PRINT '✅ Created IX_FactFinancialTransaction_Composite index';
END

PRINT '';

-- ================================================================
-- 3. STAGING TABLE INDEXES
-- ================================================================

PRINT '📥 Creating Staging Table Indexes...';

-- Staging.EquipmentUsage indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_StagingEquipmentUsage_Date')
BEGIN
    CREATE INDEX IX_StagingEquipmentUsage_Date ON staging.EquipmentUsage (usage_date);
    PRINT '✅ Created IX_StagingEquipmentUsage_Date index';
END

-- Staging.Production indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_StagingProduction_Date')
BEGIN
    CREATE INDEX IX_StagingProduction_Date ON staging.Production (production_date);
    PRINT '✅ Created IX_StagingProduction_Date index';
END

-- Staging.FinancialTransaction indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_StagingFinancialTransaction_Date')
BEGIN
    CREATE INDEX IX_StagingFinancialTransaction_Date ON staging.FinancialTransaction (transaction_date);
    PRINT '✅ Created IX_StagingFinancialTransaction_Date index';
END

PRINT '';

-- ================================================================
-- 4. UPDATE STATISTICS
-- ================================================================

PRINT '📈 Updating Statistics...';

-- Update statistics for all tables
UPDATE STATISTICS dim.DimTime;
UPDATE STATISTICS dim.DimSite;
UPDATE STATISTICS dim.DimEquipment;
UPDATE STATISTICS dim.DimMaterial;
UPDATE STATISTICS dim.DimEmployee;
UPDATE STATISTICS dim.DimProject;
UPDATE STATISTICS dim.DimAccount;

UPDATE STATISTICS fact.FactEquipmentUsage;
UPDATE STATISTICS fact.FactProduction;
UPDATE STATISTICS fact.FactFinancialTransaction;

UPDATE STATISTICS staging.EquipmentUsage;
UPDATE STATISTICS staging.Production;
UPDATE STATISTICS staging.FinancialTransaction;

PRINT '✅ Statistics updated for all tables';
PRINT '';

-- ================================================================
-- 5. CREATE OPTIMIZED VIEWS FOR DASHBOARDS
-- ================================================================

PRINT '📊 Creating Optimized Dashboard Views...';

-- Equipment Performance Summary View
IF OBJECT_ID('dbo.vw_EquipmentPerformanceSummary', 'V') IS NOT NULL
    DROP VIEW dbo.vw_EquipmentPerformanceSummary;
GO

CREATE VIEW dbo.vw_EquipmentPerformanceSummary AS
SELECT 
    t.year,
    t.month,
    t.month_name,
    s.site_name,
    s.site_type,
    e.equipment_type,
    e.model,
    COUNT(*) as usage_sessions,
    SUM(f.operating_hours) as total_operating_hours,
    AVG(f.operating_hours) as avg_operating_hours,
    SUM(f.fuel_consumption) as total_fuel_consumption,
    AVG(f.fuel_consumption) as avg_fuel_consumption,
    SUM(f.maintenance_hours) as total_maintenance_hours,
    AVG(f.maintenance_hours) as avg_maintenance_hours
FROM fact.FactEquipmentUsage f
INNER JOIN dim.DimTime t ON f.time_key = t.time_key
INNER JOIN dim.DimSite s ON f.site_key = s.site_key
INNER JOIN dim.DimEquipment e ON f.equipment_key = e.equipment_key
GROUP BY t.year, t.month, t.month_name, s.site_name, s.site_type, e.equipment_type, e.model;
GO

PRINT '✅ Created vw_EquipmentPerformanceSummary view';

-- Production Summary View
IF OBJECT_ID('dbo.vw_ProductionSummary', 'V') IS NOT NULL
    DROP VIEW dbo.vw_ProductionSummary;
GO

CREATE VIEW dbo.vw_ProductionSummary AS
SELECT 
    t.year,
    t.month,
    t.month_name,
    s.site_name,
    s.location,
    m.material_type,
    m.material_name,
    COUNT(*) as production_sessions,
    SUM(f.tonnage_produced) as total_tonnage_produced,
    AVG(f.tonnage_produced) as avg_tonnage_produced,
    AVG(f.quality_score) as avg_quality_score,
    SUM(f.tonnage_produced * f.quality_score) / SUM(f.tonnage_produced) as weighted_quality_score
FROM fact.FactProduction f
INNER JOIN dim.DimTime t ON f.time_key = t.time_key
INNER JOIN dim.DimSite s ON f.site_key = s.site_key
INNER JOIN dim.DimMaterial m ON f.material_key = m.material_key
GROUP BY t.year, t.month, t.month_name, s.site_name, s.location, m.material_type, m.material_name;
GO

PRINT '✅ Created vw_ProductionSummary view';

-- Financial Summary View
IF OBJECT_ID('dbo.vw_FinancialSummary', 'V') IS NOT NULL
    DROP VIEW dbo.vw_FinancialSummary;
GO

CREATE VIEW dbo.vw_FinancialSummary AS
SELECT 
    t.year,
    t.quarter,
    t.month,
    t.month_name,
    s.site_name,
    a.account_type,
    a.account_name,
    COUNT(*) as transaction_count,
    SUM(f.transaction_amount) as total_amount,
    AVG(f.transaction_amount) as avg_transaction_amount,
    MIN(f.transaction_amount) as min_transaction_amount,
    MAX(f.transaction_amount) as max_transaction_amount
FROM fact.FactFinancialTransaction f
INNER JOIN dim.DimTime t ON f.time_key = t.time_key
INNER JOIN dim.DimSite s ON f.site_key = s.site_key
INNER JOIN dim.DimAccount a ON f.account_key = a.account_key
GROUP BY t.year, t.quarter, t.month, t.month_name, s.site_name, a.account_type, a.account_name;
GO

PRINT '✅ Created vw_FinancialSummary view';

-- Site Performance Overview
IF OBJECT_ID('dbo.vw_SitePerformanceOverview', 'V') IS NOT NULL
    DROP VIEW dbo.vw_SitePerformanceOverview;
GO

CREATE VIEW dbo.vw_SitePerformanceOverview AS
SELECT 
    s.site_name,
    s.location,
    s.site_type,
    COUNT(DISTINCT eu.equipment_key) as unique_equipment_count,
    SUM(p.tonnage_produced) as total_production,
    AVG(p.quality_score) as avg_quality_score,
    SUM(ft.transaction_amount) as total_revenue,
    COUNT(DISTINCT ft.account_key) as active_accounts,
    SUM(eu.operating_hours) as total_operating_hours,
    SUM(eu.fuel_consumption) as total_fuel_consumption
FROM dim.DimSite s
LEFT JOIN fact.FactEquipmentUsage eu ON s.site_key = eu.site_key
LEFT JOIN fact.FactProduction p ON s.site_key = p.site_key
LEFT JOIN fact.FactFinancialTransaction ft ON s.site_key = ft.site_key
GROUP BY s.site_name, s.location, s.site_type;
GO

PRINT '✅ Created vw_SitePerformanceOverview view';

PRINT '';

-- ================================================================
-- 6. PERFORMANCE SUMMARY
-- ================================================================

PRINT '📊 Performance Optimization Summary:';
PRINT '=====================================';
PRINT '';

-- Count indexes created
SELECT 
    'Total Indexes Created: ' + CAST(COUNT(*) AS VARCHAR(10)) as summary
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name IN ('dim', 'fact', 'staging') 
AND i.type > 0;  -- Exclude heaps

-- Count views created
SELECT 
    'Dashboard Views Created: ' + CAST(COUNT(*) AS VARCHAR(10)) as summary
FROM sys.views v
INNER JOIN sys.schemas s ON v.schema_id = s.schema_id
WHERE v.name LIKE 'vw_%';

PRINT '';
PRINT '✅ Performance optimization completed successfully!';
PRINT '';
PRINT '🚀 Benefits:';
PRINT '   • Faster dashboard queries';
PRINT '   • Improved ETL performance';
PRINT '   • Optimized JOIN operations';
PRINT '   • Better aggregation performance';
PRINT '   • Reduced query execution time';
PRINT '';
PRINT '📊 Use the new optimized views for dashboard queries:';
PRINT '   • dbo.vw_EquipmentPerformanceSummary';
PRINT '   • dbo.vw_ProductionSummary';
PRINT '   • dbo.vw_FinancialSummary';
PRINT '   • dbo.vw_SitePerformanceOverview';

GO
