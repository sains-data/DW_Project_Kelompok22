-- Advanced Analytics Views for PT XYZ Data Warehouse
-- Date: 2025-05-24
-- Purpose: Create sophisticated business intelligence views

USE PTXYZ_DataWarehouse;
GO

PRINT '🚀 Creating Advanced Analytics Views...';
PRINT ' ';

-- =================================================================
-- 1. EXECUTIVE DASHBOARD VIEW
-- =================================================================
IF OBJECT_ID('analytics.vw_ExecutiveDashboard', 'V') IS NOT NULL
    DROP VIEW analytics.vw_ExecutiveDashboard;
GO

-- Create analytics schema if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'analytics')
    EXEC('CREATE SCHEMA analytics');
GO

CREATE VIEW analytics.vw_ExecutiveDashboard AS
WITH MonthlyMetrics AS (
    SELECT 
        dt.year,
        dt.month,
        dt.month_name,
        -- Production KPIs
        COALESCE(SUM(fp.produced_volume), 0) as total_production,
        COALESCE(AVG(fp.unit_cost), 0) as avg_unit_cost,
        COALESCE(SUM(fp.total_cost), 0) as total_production_cost,
        
        -- Financial KPIs
        COALESCE(SUM(fft.actual_cost), 0) as total_actual_spending,
        COALESCE(SUM(fft.budgeted_cost), 0) as total_budget,
        COALESCE(AVG(fft.variance_percentage), 0) as avg_budget_variance,
        
        -- Equipment KPIs
        COALESCE(SUM(feu.operating_hours), 0) as total_operating_hours,
        COALESCE(SUM(feu.downtime_hours), 0) as total_downtime_hours,
        COALESCE(SUM(feu.maintenance_cost), 0) as total_maintenance_cost,
        COALESCE(AVG(feu.efficiency_ratio), 0) as avg_equipment_efficiency,
        
        -- Site count
        COUNT(DISTINCT ds.site_key) as active_sites
        
    FROM dim.DimTime dt
    LEFT JOIN fact.FactProduction fp ON dt.time_key = fp.time_key
    LEFT JOIN fact.FactFinancialTransaction fft ON dt.time_key = fft.time_key
    LEFT JOIN fact.FactEquipmentUsage feu ON dt.time_key = feu.time_key
    LEFT JOIN dim.DimSite ds ON fp.site_key = ds.site_key OR fft.site_key = ds.site_key OR feu.site_key = ds.site_key
    WHERE dt.year >= YEAR(GETDATE()) - 2
    GROUP BY dt.year, dt.month, dt.month_name
)
SELECT 
    year,
    month,
    month_name,
    
    -- Production Metrics
    total_production,
    avg_unit_cost,
    total_production_cost,
    
    -- Financial Health
    total_actual_spending,
    total_budget,
    CASE 
        WHEN total_budget > 0 
        THEN ((total_actual_spending - total_budget) / total_budget) * 100
        ELSE 0 
    END as budget_variance_percent,
    
    -- Operational Efficiency
    total_operating_hours,
    total_downtime_hours,
    CASE 
        WHEN (total_operating_hours + total_downtime_hours) > 0
        THEN (total_operating_hours * 100.0) / (total_operating_hours + total_downtime_hours)
        ELSE 0
    END as equipment_utilization_percent,
    
    avg_equipment_efficiency,
    total_maintenance_cost,
    active_sites,
    
    -- Productivity Ratios
    CASE 
        WHEN total_operating_hours > 0
        THEN total_production / total_operating_hours
        ELSE 0
    END as production_per_hour,
    
    CASE 
        WHEN total_production_cost > 0
        THEN total_production / total_production_cost
        ELSE 0
    END as production_efficiency_ratio

FROM MonthlyMetrics
WHERE total_production > 0 OR total_actual_spending > 0 OR total_operating_hours > 0;
GO

PRINT '✅ Created Executive Dashboard View';

-- =================================================================
-- 2. REAL-TIME OPERATIONS VIEW
-- =================================================================
CREATE VIEW analytics.vw_RealTimeOperations AS
SELECT 
    ds.site_name,
    ds.region,
    de.equipment_name,
    de.equipment_type,
    dm.material_name,
    
    -- Current Status (last 7 days)
    COUNT(DISTINCT feu.equipment_usage_id) as recent_equipment_activities,
    COUNT(DISTINCT fp.production_id) as recent_production_runs,
    COUNT(DISTINCT fft.transaction_id) as recent_transactions,
    
    -- Performance Indicators
    AVG(feu.efficiency_ratio) as avg_efficiency,
    SUM(feu.operating_hours) as total_operating_hours,
    SUM(feu.downtime_hours) as total_downtime_hours,
    
    -- Production Status
    SUM(fp.produced_volume) as total_volume_produced,
    AVG(fp.unit_cost) as avg_unit_cost,
    
    -- Financial Impact
    SUM(fft.actual_cost) as total_costs,
    SUM(feu.maintenance_cost) as maintenance_costs,
    
    -- Status Indicators
    CASE 
        WHEN AVG(feu.efficiency_ratio) >= 0.8 THEN 'Excellent'
        WHEN AVG(feu.efficiency_ratio) >= 0.6 THEN 'Good'
        WHEN AVG(feu.efficiency_ratio) >= 0.4 THEN 'Fair'
        ELSE 'Needs Attention'
    END as performance_status,
    
    CASE
        WHEN SUM(feu.downtime_hours) / NULLIF(SUM(feu.operating_hours + feu.downtime_hours), 0) <= 0.1 THEN 'Excellent'
        WHEN SUM(feu.downtime_hours) / NULLIF(SUM(feu.operating_hours + feu.downtime_hours), 0) <= 0.2 THEN 'Good'
        ELSE 'High Downtime'
    END as availability_status

FROM dim.DimSite ds
LEFT JOIN fact.FactEquipmentUsage feu ON ds.site_key = feu.site_key
LEFT JOIN fact.FactProduction fp ON ds.site_key = fp.site_key
LEFT JOIN fact.FactFinancialTransaction fft ON ds.site_key = fft.site_key
LEFT JOIN dim.DimEquipment de ON feu.equipment_key = de.equipment_key
LEFT JOIN dim.DimMaterial dm ON fp.material_key = dm.material_key
LEFT JOIN dim.DimTime dt ON feu.time_key = dt.time_key OR fp.time_key = dt.time_key OR fft.time_key = dt.time_key
WHERE dt.date >= DATEADD(day, -7, GETDATE())
GROUP BY 
    ds.site_name, ds.region, de.equipment_name, de.equipment_type, dm.material_name
HAVING 
    COUNT(DISTINCT feu.equipment_usage_id) > 0 
    OR COUNT(DISTINCT fp.production_id) > 0 
    OR COUNT(DISTINCT fft.transaction_id) > 0;
GO

PRINT '✅ Created Real-Time Operations View';

-- =================================================================
-- 3. PREDICTIVE ANALYTICS VIEW
-- =================================================================
CREATE VIEW analytics.vw_PredictiveInsights AS
WITH TrendAnalysis AS (
    SELECT 
        ds.site_key,
        ds.site_name,
        dt.year,
        dt.month,
        
        -- Calculate trends
        AVG(feu.efficiency_ratio) as monthly_efficiency,
        SUM(feu.maintenance_cost) as monthly_maintenance,
        SUM(fp.produced_volume) as monthly_production,
        SUM(fft.actual_cost) as monthly_costs,
        
        -- Calculate rolling averages (3-month)
        AVG(AVG(feu.efficiency_ratio)) OVER (
            PARTITION BY ds.site_key 
            ORDER BY dt.year, dt.month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as efficiency_3month_avg,
        
        AVG(SUM(feu.maintenance_cost)) OVER (
            PARTITION BY ds.site_key 
            ORDER BY dt.year, dt.month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as maintenance_3month_avg,
        
        AVG(SUM(fp.produced_volume)) OVER (
            PARTITION BY ds.site_key 
            ORDER BY dt.year, dt.month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as production_3month_avg
        
    FROM dim.DimSite ds
    JOIN fact.FactEquipmentUsage feu ON ds.site_key = feu.site_key
    JOIN fact.FactProduction fp ON ds.site_key = fp.site_key
    JOIN fact.FactFinancialTransaction fft ON ds.site_key = fft.site_key
    JOIN dim.DimTime dt ON feu.time_key = dt.time_key
    WHERE dt.year >= YEAR(GETDATE()) - 1
    GROUP BY ds.site_key, ds.site_name, dt.year, dt.month
)
SELECT 
    site_name,
    year,
    month,
    
    -- Current Performance
    monthly_efficiency,
    monthly_maintenance,
    monthly_production,
    monthly_costs,
    
    -- Trend Indicators
    efficiency_3month_avg,
    maintenance_3month_avg,
    production_3month_avg,
    
    -- Predictive Indicators
    CASE 
        WHEN monthly_efficiency < efficiency_3month_avg * 0.9 THEN 'Declining'
        WHEN monthly_efficiency > efficiency_3month_avg * 1.1 THEN 'Improving'
        ELSE 'Stable'
    END as efficiency_trend,
    
    CASE 
        WHEN monthly_maintenance > maintenance_3month_avg * 1.2 THEN 'High Risk'
        WHEN monthly_maintenance > maintenance_3month_avg * 1.1 THEN 'Monitor'
        ELSE 'Normal'
    END as maintenance_risk,
    
    CASE 
        WHEN monthly_production < production_3month_avg * 0.9 THEN 'Below Target'
        WHEN monthly_production > production_3month_avg * 1.1 THEN 'Above Target'
        ELSE 'On Target'
    END as production_forecast,
    
    -- ROI Calculations
    CASE 
        WHEN monthly_costs > 0 
        THEN (monthly_production * 100.0) / monthly_costs
        ELSE 0
    END as production_roi

FROM TrendAnalysis;
GO

PRINT '✅ Created Predictive Analytics View';

-- =================================================================
-- 4. COST OPTIMIZATION VIEW
-- =================================================================
CREATE VIEW analytics.vw_CostOptimization AS
SELECT 
    ds.site_name,
    ds.region,
    da.account_type,
    da.budget_category,
    
    -- Cost Analysis
    SUM(fft.budgeted_cost) as total_budget,
    SUM(fft.actual_cost) as total_actual,
    SUM(fft.variance_amount) as total_variance,
    
    -- Cost per Production Unit
    CASE 
        WHEN SUM(fp.produced_volume) > 0 
        THEN SUM(fft.actual_cost) / SUM(fp.produced_volume)
        ELSE 0
    END as cost_per_unit,
    
    -- Equipment Cost Efficiency
    CASE 
        WHEN SUM(feu.operating_hours) > 0 
        THEN SUM(feu.maintenance_cost) / SUM(feu.operating_hours)
        ELSE 0
    END as maintenance_cost_per_hour,
    
    -- Variance Analysis
    CASE 
        WHEN SUM(fft.budgeted_cost) > 0 
        THEN (SUM(fft.actual_cost) - SUM(fft.budgeted_cost)) / SUM(fft.budgeted_cost) * 100
        ELSE 0
    END as budget_variance_percent,
    
    -- Optimization Opportunities
    CASE 
        WHEN (SUM(fft.actual_cost) - SUM(fft.budgeted_cost)) / NULLIF(SUM(fft.budgeted_cost), 0) > 0.2 
        THEN 'High Savings Potential'
        WHEN (SUM(fft.actual_cost) - SUM(fft.budgeted_cost)) / NULLIF(SUM(fft.budgeted_cost), 0) > 0.1 
        THEN 'Medium Savings Potential'
        ELSE 'Optimized'
    END as optimization_opportunity

FROM dim.DimSite ds
JOIN fact.FactFinancialTransaction fft ON ds.site_key = fft.site_key
JOIN fact.FactProduction fp ON ds.site_key = fp.site_key
JOIN fact.FactEquipmentUsage feu ON ds.site_key = feu.site_key
JOIN dim.DimAccount da ON fft.account_key = da.account_key
GROUP BY ds.site_name, ds.region, da.account_type, da.budget_category;
GO

PRINT '✅ Created Cost Optimization View';

-- Update statistics for all new views
PRINT ' ';
PRINT '📊 Updating statistics for analytics views...';

-- Create indexes for performance
CREATE INDEX IX_Analytics_ExecutiveDashboard_Date 
ON analytics.vw_ExecutiveDashboard (year, month) 
WITH (ONLINE = ON);

PRINT ' ';
PRINT '🎯 Advanced Analytics Views Summary:';
PRINT '=====================================';
PRINT ' ';

SELECT 
    'Advanced Analytics Views Created: ' + CAST(COUNT(*) AS VARCHAR(10)) as summary
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'analytics';

PRINT ' ';
PRINT '✅ Advanced analytics views creation completed!';
PRINT ' ';
PRINT '🚀 New Business Intelligence Features:';
PRINT '   • Executive Dashboard - High-level KPIs and trends';
PRINT '   • Real-Time Operations - Current operational status';
PRINT '   • Predictive Analytics - Trend analysis and forecasting';
PRINT '   • Cost Optimization - Financial efficiency insights';
PRINT ' ';
PRINT '📊 Use these views for advanced dashboard creation:';
PRINT '   • analytics.vw_ExecutiveDashboard';
PRINT '   • analytics.vw_RealTimeOperations';
PRINT '   • analytics.vw_PredictiveInsights';
PRINT '   • analytics.vw_CostOptimization';
