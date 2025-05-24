-- Fix Optimization Views with Correct Column Names
-- PT XYZ Data Warehouse Performance Optimization
-- Date: 2025-05-24

USE PTXYZ_DataWarehouse;
GO

PRINT '🔧 Fixing Optimization Views with Correct Column Names...';
PRINT ' ';

-- Drop existing views that had errors
IF OBJECT_ID('dbo.vw_EquipmentPerformanceSummary', 'V') IS NOT NULL
    DROP VIEW dbo.vw_EquipmentPerformanceSummary;

IF OBJECT_ID('dbo.vw_ProductionSummary', 'V') IS NOT NULL
    DROP VIEW dbo.vw_ProductionSummary;

IF OBJECT_ID('dbo.vw_FinancialSummary', 'V') IS NOT NULL
    DROP VIEW dbo.vw_FinancialSummary;

IF OBJECT_ID('dbo.vw_SitePerformanceOverview', 'V') IS NOT NULL
    DROP VIEW dbo.vw_SitePerformanceOverview;

-- 1. Equipment Performance Summary View (Fixed)
CREATE VIEW dbo.vw_EquipmentPerformanceSummary AS
SELECT 
    dt.year,
    dt.month,
    dt.month_name,
    ds.site_name,
    ds.region,
    de.equipment_name,
    de.equipment_type,
    de.capacity,
    COUNT(*) as usage_count,
    SUM(feu.operating_hours) as total_operating_hours,
    SUM(feu.downtime_hours) as total_downtime_hours,
    AVG(feu.efficiency_ratio) as avg_efficiency,
    SUM(feu.fuel_consumption) as total_fuel_consumption,
    SUM(feu.maintenance_cost) as total_maintenance_cost,
    CASE 
        WHEN SUM(feu.operating_hours + feu.downtime_hours) > 0 
        THEN (SUM(feu.operating_hours) * 100.0) / SUM(feu.operating_hours + feu.downtime_hours)
        ELSE 0 
    END as utilization_percentage
FROM fact.FactEquipmentUsage feu
JOIN dim.DimTime dt ON feu.time_key = dt.time_key
JOIN dim.DimSite ds ON feu.site_key = ds.site_key
JOIN dim.DimEquipment de ON feu.equipment_key = de.equipment_key
GROUP BY 
    dt.year, dt.month, dt.month_name,
    ds.site_name, ds.region,
    de.equipment_name, de.equipment_type, de.capacity;
GO

PRINT '✅ Created vw_EquipmentPerformanceSummary view';

-- 2. Production Summary View (Fixed)
CREATE VIEW dbo.vw_ProductionSummary AS
SELECT 
    dt.year,
    dt.month,
    dt.month_name,
    dt.quarter,
    ds.site_name,
    ds.region,
    dm.material_name,
    dm.material_type,
    dm.unit_of_measure,
    COUNT(*) as production_count,
    SUM(fp.produced_volume) as total_produced_volume,
    AVG(fp.unit_cost) as avg_unit_cost,
    SUM(fp.total_cost) as total_production_cost,
    SUM(fp.material_quantity) as total_material_used,
    AVG(fp.produced_volume) as avg_production_efficiency
FROM fact.FactProduction fp
JOIN dim.DimTime dt ON fp.time_key = dt.time_key
JOIN dim.DimSite ds ON fp.site_key = ds.site_key
JOIN dim.DimMaterial dm ON fp.material_key = dm.material_key
GROUP BY 
    dt.year, dt.month, dt.month_name, dt.quarter,
    ds.site_name, ds.region,
    dm.material_name, dm.material_type, dm.unit_of_measure;
GO

PRINT '✅ Created vw_ProductionSummary view';

-- 3. Financial Summary View (Fixed)
CREATE VIEW dbo.vw_FinancialSummary AS
SELECT 
    dt.year,
    dt.month,
    dt.month_name,
    dt.quarter,
    ds.site_name,
    da.account_name,
    da.account_type,
    da.budget_category,
    COUNT(*) as transaction_count,
    SUM(fft.budgeted_cost) as total_budgeted_cost,
    SUM(fft.actual_cost) as total_actual_cost,
    SUM(fft.variance_amount) as total_variance_amount,
    AVG(fft.variance_percentage) as avg_variance_percentage,
    SUM(fft.account_cost) as total_account_cost
FROM fact.FactFinancialTransaction fft
JOIN dim.DimTime dt ON fft.time_key = dt.time_key
JOIN dim.DimSite ds ON fft.site_key = ds.site_key
JOIN dim.DimAccount da ON fft.account_key = da.account_key
GROUP BY 
    dt.year, dt.month, dt.month_name, dt.quarter,
    ds.site_name,
    da.account_name, da.account_type, da.budget_category;
GO

PRINT '✅ Created vw_FinancialSummary view';

-- 4. Site Performance Overview (Fixed)
CREATE VIEW dbo.vw_SitePerformanceOverview AS
SELECT 
    ds.site_name,
    ds.region,
    dt.year,
    dt.month,
    -- Production metrics
    COALESCE(SUM(fp.produced_volume), 0) as total_production_volume,
    COALESCE(AVG(fp.unit_cost), 0) as avg_production_cost,
    -- Financial metrics
    COALESCE(SUM(fft.actual_cost), 0) as total_actual_cost,
    COALESCE(SUM(fft.budgeted_cost), 0) as total_budgeted_cost,
    COALESCE(SUM(fft.variance_amount), 0) as total_variance,
    -- Equipment metrics
    COALESCE(SUM(feu.operating_hours), 0) as total_operating_hours,
    COALESCE(SUM(feu.downtime_hours), 0) as total_downtime_hours,
    COALESCE(SUM(feu.maintenance_cost), 0) as total_maintenance_cost,
    -- Calculate efficiency
    CASE 
        WHEN SUM(feu.operating_hours + feu.downtime_hours) > 0 
        THEN (SUM(feu.operating_hours) * 100.0) / SUM(feu.operating_hours + feu.downtime_hours)
        ELSE 0 
    END as overall_efficiency
FROM dim.DimSite ds
CROSS JOIN dim.DimTime dt
LEFT JOIN fact.FactProduction fp ON ds.site_key = fp.site_key AND dt.time_key = fp.time_key
LEFT JOIN fact.FactFinancialTransaction fft ON ds.site_key = fft.site_key AND dt.time_key = fft.time_key
LEFT JOIN fact.FactEquipmentUsage feu ON ds.site_key = feu.site_key AND dt.time_key = feu.time_key
GROUP BY 
    ds.site_name, ds.region, dt.year, dt.month
HAVING 
    COALESCE(SUM(fp.produced_volume), 0) > 0 
    OR COALESCE(SUM(fft.actual_cost), 0) > 0 
    OR COALESCE(SUM(feu.operating_hours), 0) > 0;
GO

PRINT '✅ Created vw_SitePerformanceOverview view';

-- Update statistics for the new views
UPDATE STATISTICS dbo.vw_EquipmentPerformanceSummary;
UPDATE STATISTICS dbo.vw_ProductionSummary;
UPDATE STATISTICS dbo.vw_FinancialSummary;
UPDATE STATISTICS dbo.vw_SitePerformanceOverview;

PRINT ' ';
PRINT '🎯 Performance Views Fix Summary:';
PRINT '=====================================';
PRINT ' ';

-- Count the views
SELECT 
    'Dashboard Views Created: ' + CAST(COUNT(*) AS VARCHAR(10)) as summary
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_NAME LIKE 'vw_%';

PRINT ' ';
PRINT '✅ Performance view fixes completed successfully!';
PRINT ' ';
PRINT '🔥 Benefits:';
PRINT '   • Fixed column name errors';
PRINT '   • Optimized dashboard queries';
PRINT '   • Improved JOIN operations';
PRINT '   • Better aggregation performance';
PRINT '   • Ready for dashboard integration';
PRINT ' ';
PRINT '📊 Use the corrected optimized views for dashboard queries:';
PRINT '   • dbo.vw_EquipmentPerformanceSummary';
PRINT '   • dbo.vw_ProductionSummary';
PRINT '   • dbo.vw_FinancialSummary';
PRINT '   • dbo.vw_SitePerformanceOverview';
