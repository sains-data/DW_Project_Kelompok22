-- Test and Create Missing Analytics Views
-- PT XYZ Data Warehouse - Analytics Views Fix
-- Date: 2025-05-24

USE PTXYZ_DataWarehouse;
GO

PRINT '🔍 Testing Current Analytics Views and Creating Missing Ones';
PRINT '==========================================================';

-- Test existing executive dashboard view
PRINT '';
PRINT '1. Testing Executive Dashboard View...';
BEGIN TRY
    SELECT COUNT(*) as RecordCount FROM analytics.vw_ExecutiveDashboard;
    PRINT '✅ Executive Dashboard View - SUCCESS';
END TRY
BEGIN CATCH
    PRINT '❌ Executive Dashboard View - ERROR: ' + ERROR_MESSAGE();
END CATCH

-- Create Real-Time Operations View
PRINT '';
PRINT '2. Creating Real-Time Operations View...';
IF OBJECT_ID('analytics.vw_RealTimeOperations', 'V') IS NOT NULL
    DROP VIEW analytics.vw_RealTimeOperations;
GO

CREATE VIEW analytics.vw_RealTimeOperations AS
SELECT 
    -- Current day metrics
    CAST(GETDATE() as DATE) as report_date,
    
    -- Equipment Status
    COUNT(DISTINCT feu.equipment_key) as active_equipment_count,
    SUM(feu.operating_hours) as total_operating_hours_today,
    SUM(feu.downtime_hours) as total_downtime_hours_today,
    AVG(feu.efficiency_ratio) as avg_efficiency_today,
    
    -- Production Status
    COUNT(DISTINCT fp.production_key) as active_production_lines,
    SUM(fp.produced_volume) as total_production_today,
    AVG(fp.unit_cost) as avg_unit_cost_today,
    
    -- Financial Status
    COUNT(DISTINCT fft.transaction_key) as transaction_count_today,
    SUM(fft.actual_cost) as total_spending_today,
    SUM(fft.budgeted_cost) as total_budget_today,
    
    -- Site Activity
    COUNT(DISTINCT ds.site_key) as active_sites_today

FROM dim.DimTime dt
LEFT JOIN fact.FactEquipmentUsage feu ON dt.time_key = feu.time_key
LEFT JOIN fact.FactProduction fp ON dt.time_key = fp.time_key  
LEFT JOIN fact.FactFinancialTransaction fft ON dt.time_key = fft.time_key
LEFT JOIN dim.DimSite ds ON (feu.site_key = ds.site_key OR fp.site_key = ds.site_key OR fft.site_key = ds.site_key)
WHERE dt.full_date = CAST(GETDATE() as DATE)
GROUP BY CAST(GETDATE() as DATE);
GO

PRINT '✅ Real-Time Operations View Created';

-- Create Predictive Insights View
PRINT '';
PRINT '3. Creating Predictive Insights View...';
IF OBJECT_ID('analytics.vw_PredictiveInsights', 'V') IS NOT NULL
    DROP VIEW analytics.vw_PredictiveInsights;
GO

CREATE VIEW analytics.vw_PredictiveInsights AS
WITH MonthlyTrends AS (
    SELECT 
        dt.year,
        dt.month,
        dt.month_name,
        SUM(feu.operating_hours) as monthly_operating_hours,
        SUM(feu.maintenance_cost) as monthly_maintenance_cost,
        AVG(feu.efficiency_ratio) as monthly_avg_efficiency,
        SUM(fp.produced_volume) as monthly_production,
        SUM(fft.actual_cost) as monthly_spending
    FROM dim.DimTime dt
    LEFT JOIN fact.FactEquipmentUsage feu ON dt.time_key = feu.time_key
    LEFT JOIN fact.FactProduction fp ON dt.time_key = fp.time_key
    LEFT JOIN fact.FactFinancialTransaction fft ON dt.time_key = fft.time_key
    WHERE dt.year >= YEAR(GETDATE()) - 1
    GROUP BY dt.year, dt.month, dt.month_name
)
SELECT 
    year,
    month,
    month_name,
    monthly_operating_hours,
    monthly_maintenance_cost,
    monthly_avg_efficiency,
    monthly_production,
    monthly_spending,
    
    -- 3-month rolling averages for trend analysis
    AVG(monthly_operating_hours) OVER (ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as rolling_avg_operating_hours,
    AVG(monthly_maintenance_cost) OVER (ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as rolling_avg_maintenance_cost,
    AVG(monthly_avg_efficiency) OVER (ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as rolling_avg_efficiency,
    
    -- Predictive indicators
    CASE 
        WHEN monthly_maintenance_cost > AVG(monthly_maintenance_cost) OVER (ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) * 1.2
        THEN 'HIGH_MAINTENANCE_RISK'
        WHEN monthly_avg_efficiency < AVG(monthly_avg_efficiency) OVER (ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) * 0.9
        THEN 'EFFICIENCY_DECLINE'
        ELSE 'NORMAL'
    END as risk_indicator
    
FROM MonthlyTrends;
GO

PRINT '✅ Predictive Insights View Created';

-- Create Cost Optimization View
PRINT '';
PRINT '4. Creating Cost Optimization View...';
IF OBJECT_ID('analytics.vw_CostOptimization', 'V') IS NOT NULL
    DROP VIEW analytics.vw_CostOptimization;
GO

CREATE VIEW analytics.vw_CostOptimization AS
SELECT 
    dt.year,
    dt.month,
    dt.month_name,
    
    -- Cost Analysis
    SUM(fft.actual_cost) as total_actual_cost,
    SUM(fft.budgeted_cost) as total_budgeted_cost,
    SUM(fft.actual_cost - fft.budgeted_cost) as total_variance,
    
    -- Equipment Cost Efficiency
    SUM(feu.maintenance_cost) as total_maintenance_cost,
    SUM(feu.operating_hours) as total_operating_hours,
    CASE 
        WHEN SUM(feu.operating_hours) > 0
        THEN SUM(feu.maintenance_cost) / SUM(feu.operating_hours)
        ELSE 0
    END as maintenance_cost_per_hour,
    
    -- Production Cost Efficiency
    SUM(fp.total_cost) as total_production_cost,
    SUM(fp.produced_volume) as total_produced_volume,
    CASE 
        WHEN SUM(fp.produced_volume) > 0
        THEN SUM(fp.total_cost) / SUM(fp.produced_volume)
        ELSE 0
    END as cost_per_unit_produced,
    
    -- Efficiency Metrics
    AVG(feu.efficiency_ratio) as avg_equipment_efficiency,
    
    -- Budget Variance Analysis
    CASE 
        WHEN SUM(fft.budgeted_cost) > 0
        THEN ((SUM(fft.actual_cost) - SUM(fft.budgeted_cost)) / SUM(fft.budgeted_cost)) * 100
        ELSE 0
    END as budget_variance_percentage

FROM dim.DimTime dt
LEFT JOIN fact.FactFinancialTransaction fft ON dt.time_key = fft.time_key
LEFT JOIN fact.FactEquipmentUsage feu ON dt.time_key = feu.time_key
LEFT JOIN fact.FactProduction fp ON dt.time_key = fp.time_key
WHERE dt.year >= YEAR(GETDATE()) - 2
GROUP BY dt.year, dt.month, dt.month_name;
GO

PRINT '✅ Cost Optimization View Created';

-- Final verification
PRINT '';
PRINT '5. Final Verification...';
SELECT 
    SCHEMA_NAME(schema_id) as SchemaName, 
    name as ViewName,
    create_date as CreatedDate
FROM sys.views 
WHERE SCHEMA_NAME(schema_id) = 'analytics' 
ORDER BY name;

PRINT '';
PRINT '🎯 Advanced Analytics Views Setup Complete!';
