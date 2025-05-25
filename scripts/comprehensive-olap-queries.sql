-- =========================================================================
-- PT XYZ Data Warehouse - Comprehensive OLAP Queries for Dashboard Analytics
-- Created: 2025-05-25
-- Purpose: Advanced OLAP queries for business intelligence dashboards
-- =========================================================================

USE PTXYZ_DataWarehouse;
GO

PRINT '🚀 Creating Comprehensive OLAP Queries for Dashboard Analytics...';
PRINT '======================================================================';

-- =========================================================================
-- 1. EXECUTIVE DASHBOARD QUERIES
-- =========================================================================

PRINT '📊 1. Executive Dashboard Queries';
PRINT '================================';

-- 1.1 KPI Summary View
IF OBJECT_ID('analytics.vw_ExecutiveKPIs', 'V') IS NOT NULL DROP VIEW analytics.vw_ExecutiveKPIs;
GO

CREATE VIEW analytics.vw_ExecutiveKPIs AS
WITH CurrentPeriod AS (
    SELECT 
        -- Production KPIs
        SUM(fp.produced_volume) as total_production_current,
        AVG(fp.unit_cost) as avg_unit_cost_current,
        SUM(fp.total_cost) as total_production_cost_current,
        
        -- Equipment KPIs
        AVG(feu.efficiency_ratio) as avg_equipment_efficiency_current,
        SUM(feu.operating_hours) as total_operating_hours_current,
        SUM(feu.downtime_hours) as total_downtime_hours_current,
        SUM(feu.maintenance_cost) as total_maintenance_cost_current,
        
        -- Financial KPIs
        SUM(fft.budgeted_cost) as total_budget_current,
        SUM(fft.actual_cost) as total_actual_cost_current,
        AVG(fft.variance_percentage) as avg_variance_percentage_current,
        
        -- Site Activity
        COUNT(DISTINCT ds.site_key) as active_sites_current
    FROM dim.DimTime dt
    LEFT JOIN fact.FactProduction fp ON dt.time_key = fp.time_key
    LEFT JOIN fact.FactEquipmentUsage feu ON dt.time_key = feu.time_key
    LEFT JOIN fact.FactFinancialTransaction fft ON dt.time_key = fft.time_key
    LEFT JOIN dim.DimSite ds ON fp.site_key = ds.site_key OR feu.site_key = ds.site_key OR fft.site_key = ds.site_key
    WHERE dt.year = YEAR(GETDATE()) AND dt.month = MONTH(GETDATE())
),
PreviousPeriod AS (
    SELECT 
        SUM(fp.produced_volume) as total_production_previous,
        AVG(fp.unit_cost) as avg_unit_cost_previous,
        SUM(fp.total_cost) as total_production_cost_previous,
        AVG(feu.efficiency_ratio) as avg_equipment_efficiency_previous,
        SUM(feu.operating_hours) as total_operating_hours_previous,
        SUM(fft.budgeted_cost) as total_budget_previous,
        SUM(fft.actual_cost) as total_actual_cost_previous
    FROM dim.DimTime dt
    LEFT JOIN fact.FactProduction fp ON dt.time_key = fp.time_key
    LEFT JOIN fact.FactEquipmentUsage feu ON dt.time_key = feu.time_key
    LEFT JOIN fact.FactFinancialTransaction fft ON dt.time_key = fft.time_key
    WHERE dt.year = YEAR(DATEADD(month, -1, GETDATE())) 
      AND dt.month = MONTH(DATEADD(month, -1, GETDATE()))
)
SELECT 
    -- Current Period KPIs
    cp.total_production_current,
    cp.avg_unit_cost_current,
    cp.total_production_cost_current,
    cp.avg_equipment_efficiency_current,
    cp.total_operating_hours_current,
    cp.total_downtime_hours_current,
    cp.total_maintenance_cost_current,
    cp.total_budget_current,
    cp.total_actual_cost_current,
    cp.avg_variance_percentage_current,
    cp.active_sites_current,
    
    -- Month-over-Month Growth
    CASE WHEN pp.total_production_previous > 0 
         THEN ((cp.total_production_current - pp.total_production_previous) / pp.total_production_previous) * 100 
         ELSE 0 END as production_growth_percent,
    
    CASE WHEN pp.avg_equipment_efficiency_previous > 0 
         THEN ((cp.avg_equipment_efficiency_current - pp.avg_equipment_efficiency_previous) / pp.avg_equipment_efficiency_previous) * 100 
         ELSE 0 END as efficiency_improvement_percent,
    
    CASE WHEN pp.total_budget_previous > 0 
         THEN ((cp.total_actual_cost_current - pp.total_actual_cost_previous) / pp.total_budget_previous) * 100 
         ELSE 0 END as cost_variance_trend_percent,
    
    -- Calculated Ratios
    CASE WHEN (cp.total_operating_hours_current + cp.total_downtime_hours_current) > 0
         THEN (cp.total_operating_hours_current / (cp.total_operating_hours_current + cp.total_downtime_hours_current)) * 100
         ELSE 0 END as overall_utilization_percent,
    
    CASE WHEN cp.total_budget_current > 0
         THEN ((cp.total_actual_cost_current - cp.total_budget_current) / cp.total_budget_current) * 100
         ELSE 0 END as budget_variance_percent

FROM CurrentPeriod cp
CROSS JOIN PreviousPeriod pp;
GO

-- 1.2 Monthly Trend Analysis
CREATE VIEW analytics.vw_MonthlyTrends AS
SELECT 
    dt.year,
    dt.month,
    dt.month_name,
    
    -- Production Metrics
    SUM(fp.produced_volume) as monthly_production,
    AVG(fp.unit_cost) as avg_unit_cost,
    SUM(fp.total_cost) as total_production_cost,
    
    -- Equipment Metrics
    AVG(feu.efficiency_ratio) as avg_efficiency,
    SUM(feu.operating_hours) as total_operating_hours,
    SUM(feu.downtime_hours) as total_downtime_hours,
    SUM(feu.maintenance_cost) as total_maintenance_cost,
    
    -- Financial Metrics
    SUM(fft.budgeted_cost) as total_budget,
    SUM(fft.actual_cost) as total_actual_cost,
    SUM(fft.variance_amount) as total_variance,
    
    -- Site Activity
    COUNT(DISTINCT ds.site_key) as active_sites,
    COUNT(DISTINCT de.equipment_key) as active_equipment,
    
    -- Calculated KPIs
    CASE WHEN SUM(fp.produced_volume) > 0 AND SUM(feu.operating_hours) > 0
         THEN SUM(fp.produced_volume) / SUM(feu.operating_hours)
         ELSE 0 END as production_per_hour,
    
    CASE WHEN SUM(fft.budgeted_cost) > 0
         THEN (SUM(fft.actual_cost) / SUM(fft.budgeted_cost)) * 100
         ELSE 0 END as budget_utilization_percent

FROM dim.DimTime dt
LEFT JOIN fact.FactProduction fp ON dt.time_key = fp.time_key
LEFT JOIN fact.FactEquipmentUsage feu ON dt.time_key = feu.time_key
LEFT JOIN fact.FactFinancialTransaction fft ON dt.time_key = fft.time_key
LEFT JOIN dim.DimSite ds ON fp.site_key = ds.site_key OR feu.site_key = ds.site_key OR fft.site_key = ds.site_key
LEFT JOIN dim.DimEquipment de ON feu.equipment_key = de.equipment_key
WHERE dt.year >= YEAR(GETDATE()) - 2
GROUP BY dt.year, dt.month, dt.month_name
HAVING SUM(fp.produced_volume) > 0 OR SUM(feu.operating_hours) > 0 OR SUM(fft.actual_cost) > 0;
GO

PRINT '✅ Executive Dashboard Queries Created';

-- =========================================================================
-- 2. OPERATIONS DASHBOARD QUERIES
-- =========================================================================

PRINT '';
PRINT '⚙️ 2. Operations Dashboard Queries';
PRINT '=================================';

-- 2.1 Real-time Equipment Status
CREATE VIEW analytics.vw_EquipmentStatus AS
SELECT 
    de.equipment_name,
    de.equipment_type,
    de.capacity,
    ds.site_name,
    ds.region,
    
    -- Recent Performance (Last 7 Days)
    AVG(feu.efficiency_ratio) as current_efficiency,
    SUM(feu.operating_hours) as week_operating_hours,
    SUM(feu.downtime_hours) as week_downtime_hours,
    SUM(feu.fuel_consumption) as week_fuel_consumption,
    SUM(feu.maintenance_cost) as week_maintenance_cost,
    
    -- Status Indicators
    CASE 
        WHEN AVG(feu.efficiency_ratio) >= 0.85 THEN 'Excellent'
        WHEN AVG(feu.efficiency_ratio) >= 0.70 THEN 'Good'
        WHEN AVG(feu.efficiency_ratio) >= 0.50 THEN 'Fair'
        ELSE 'Needs Attention'
    END as performance_status,
    
    CASE
        WHEN SUM(feu.downtime_hours) / NULLIF(SUM(feu.operating_hours + feu.downtime_hours), 0) <= 0.1 THEN 'Excellent'
        WHEN SUM(feu.downtime_hours) / NULLIF(SUM(feu.operating_hours + feu.downtime_hours), 0) <= 0.2 THEN 'Good'
        ELSE 'High Downtime'
    END as availability_status,
    
    -- Utilization Percentage
    CASE 
        WHEN SUM(feu.operating_hours + feu.downtime_hours) > 0
        THEN (SUM(feu.operating_hours) / SUM(feu.operating_hours + feu.downtime_hours)) * 100
        ELSE 0
    END as utilization_percent

FROM dim.DimEquipment de
JOIN fact.FactEquipmentUsage feu ON de.equipment_key = feu.equipment_key
JOIN dim.DimSite ds ON feu.site_key = ds.site_key
JOIN dim.DimTime dt ON feu.time_key = dt.time_key
WHERE dt.date >= DATEADD(day, -7, GETDATE())
GROUP BY de.equipment_name, de.equipment_type, de.capacity, ds.site_name, ds.region;
GO

-- 2.2 Production Performance by Site
CREATE VIEW analytics.vw_SiteProductionPerformance AS
SELECT 
    ds.site_name,
    ds.region,
    dm.material_type,
    dm.material_name,
    
    -- Production Metrics
    SUM(fp.produced_volume) as total_production,
    AVG(fp.unit_cost) as avg_unit_cost,
    SUM(fp.total_cost) as total_production_cost,
    COUNT(*) as production_sessions,
    
    -- Equipment Performance at Site
    AVG(feu.efficiency_ratio) as site_avg_efficiency,
    SUM(feu.operating_hours) as site_operating_hours,
    SUM(feu.maintenance_cost) as site_maintenance_cost,
    
    -- Financial Performance
    SUM(fft.actual_cost) as site_total_cost,
    SUM(fft.budgeted_cost) as site_budget,
    
    -- Calculated Metrics
    CASE WHEN SUM(fp.produced_volume) > 0 AND SUM(feu.operating_hours) > 0
         THEN SUM(fp.produced_volume) / SUM(feu.operating_hours)
         ELSE 0 END as production_efficiency,
    
    CASE WHEN SUM(fft.budgeted_cost) > 0
         THEN ((SUM(fft.actual_cost) - SUM(fft.budgeted_cost)) / SUM(fft.budgeted_cost)) * 100
         ELSE 0 END as budget_variance_percent

FROM dim.DimSite ds
LEFT JOIN fact.FactProduction fp ON ds.site_key = fp.site_key
LEFT JOIN fact.FactEquipmentUsage feu ON ds.site_key = feu.site_key
LEFT JOIN fact.FactFinancialTransaction fft ON ds.site_key = fft.site_key
LEFT JOIN dim.DimMaterial dm ON fp.material_key = dm.material_key
JOIN dim.DimTime dt ON fp.time_key = dt.time_key OR feu.time_key = dt.time_key OR fft.time_key = dt.time_key
WHERE dt.date >= DATEADD(day, -30, GETDATE())
GROUP BY ds.site_name, ds.region, dm.material_type, dm.material_name
HAVING SUM(fp.produced_volume) > 0 OR SUM(feu.operating_hours) > 0;
GO

PRINT '✅ Operations Dashboard Queries Created';

-- =========================================================================
-- 3. FINANCIAL ANALYTICS QUERIES
-- =========================================================================

PRINT '';
PRINT '💰 3. Financial Analytics Queries';
PRINT '================================';

-- 3.1 Cost Analysis by Category
CREATE VIEW analytics.vw_CostAnalysis AS
SELECT 
    da.account_type,
    da.budget_category,
    ds.site_name,
    ds.region,
    dt.year,
    dt.quarter,
    dt.month_name,
    
    -- Financial Metrics
    SUM(fft.budgeted_cost) as total_budget,
    SUM(fft.actual_cost) as total_actual_cost,
    SUM(fft.variance_amount) as total_variance,
    AVG(fft.variance_percentage) as avg_variance_percentage,
    COUNT(*) as transaction_count,
    
    -- Equipment-related Costs
    SUM(feu.maintenance_cost) as equipment_maintenance_cost,
    SUM(feu.fuel_consumption * 2.5) as estimated_fuel_cost, -- Assuming $2.5 per unit
    
    -- Cost per Production Unit
    CASE WHEN SUM(fp.produced_volume) > 0
         THEN SUM(fft.actual_cost) / SUM(fp.produced_volume)
         ELSE 0 END as cost_per_unit_produced,
    
    -- Budget Performance Indicators
    CASE 
        WHEN SUM(fft.budgeted_cost) > 0 AND SUM(fft.actual_cost) < SUM(fft.budgeted_cost) * 0.95 THEN 'Under Budget'
        WHEN SUM(fft.budgeted_cost) > 0 AND SUM(fft.actual_cost) > SUM(fft.budgeted_cost) * 1.05 THEN 'Over Budget'
        ELSE 'On Budget'
    END as budget_status

FROM fact.FactFinancialTransaction fft
JOIN dim.DimAccount da ON fft.account_key = da.account_key
JOIN dim.DimSite ds ON fft.site_key = ds.site_key
JOIN dim.DimTime dt ON fft.time_key = dt.time_key
LEFT JOIN fact.FactEquipmentUsage feu ON ds.site_key = feu.site_key AND dt.time_key = feu.time_key
LEFT JOIN fact.FactProduction fp ON ds.site_key = fp.site_key AND dt.time_key = fp.time_key
WHERE dt.year >= YEAR(GETDATE()) - 2
GROUP BY da.account_type, da.budget_category, ds.site_name, ds.region, dt.year, dt.quarter, dt.month_name;
GO

-- 3.2 Profitability Analysis
CREATE VIEW analytics.vw_ProfitabilityAnalysis AS
SELECT 
    ds.site_name,
    ds.region,
    dm.material_type,
    dt.year,
    dt.quarter,
    
    -- Revenue Estimation (assuming selling price is 1.5x production cost)
    SUM(fp.total_cost) * 1.5 as estimated_revenue,
    SUM(fp.total_cost) as production_cost,
    SUM(fft.actual_cost) as operational_cost,
    SUM(feu.maintenance_cost) as maintenance_cost,
    
    -- Profit Calculation
    (SUM(fp.total_cost) * 1.5) - SUM(fft.actual_cost) - SUM(feu.maintenance_cost) as estimated_profit,
    
    -- Margin Calculation
    CASE WHEN SUM(fp.total_cost) > 0
         THEN (((SUM(fp.total_cost) * 1.5) - SUM(fft.actual_cost) - SUM(feu.maintenance_cost)) / (SUM(fp.total_cost) * 1.5)) * 100
         ELSE 0 END as profit_margin_percent,
    
    -- Efficiency Metrics
    SUM(fp.produced_volume) as total_production,
    AVG(feu.efficiency_ratio) as avg_equipment_efficiency,
    
    -- ROI Calculation
    CASE WHEN SUM(fft.actual_cost) > 0
         THEN (((SUM(fp.total_cost) * 1.5) - SUM(fft.actual_cost)) / SUM(fft.actual_cost)) * 100
         ELSE 0 END as roi_percent

FROM dim.DimSite ds
JOIN fact.FactProduction fp ON ds.site_key = fp.site_key
JOIN fact.FactFinancialTransaction fft ON ds.site_key = fft.site_key
JOIN fact.FactEquipmentUsage feu ON ds.site_key = feu.site_key
JOIN dim.DimMaterial dm ON fp.material_key = dm.material_key
JOIN dim.DimTime dt ON fp.time_key = dt.time_key
WHERE dt.year >= YEAR(GETDATE()) - 2
  AND SUM(fp.produced_volume) > 0
GROUP BY ds.site_name, ds.region, dm.material_type, dt.year, dt.quarter;
GO

PRINT '✅ Financial Analytics Queries Created';

-- =========================================================================
-- 4. PREDICTIVE ANALYTICS QUERIES
-- =========================================================================

PRINT '';
PRINT '🔮 4. Predictive Analytics Queries';
PRINT '=================================';

-- 4.1 Equipment Maintenance Prediction
CREATE VIEW analytics.vw_MaintenancePrediction AS
WITH EquipmentTrends AS (
    SELECT 
        de.equipment_key,
        de.equipment_name,
        de.equipment_type,
        ds.site_name,
        dt.month,
        dt.year,
        
        -- Monthly Aggregations
        AVG(feu.efficiency_ratio) as monthly_efficiency,
        SUM(feu.maintenance_cost) as monthly_maintenance_cost,
        SUM(feu.operating_hours) as monthly_operating_hours,
        SUM(feu.downtime_hours) as monthly_downtime_hours,
        
        -- 3-Month Rolling Averages
        AVG(AVG(feu.efficiency_ratio)) OVER (
            PARTITION BY de.equipment_key 
            ORDER BY dt.year, dt.month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as efficiency_3month_avg,
        
        AVG(SUM(feu.maintenance_cost)) OVER (
            PARTITION BY de.equipment_key 
            ORDER BY dt.year, dt.month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as maintenance_3month_avg

    FROM fact.FactEquipmentUsage feu
    JOIN dim.DimEquipment de ON feu.equipment_key = de.equipment_key
    JOIN dim.DimSite ds ON feu.site_key = ds.site_key
    JOIN dim.DimTime dt ON feu.time_key = dt.time_key
    WHERE dt.year >= YEAR(GETDATE()) - 1
    GROUP BY de.equipment_key, de.equipment_name, de.equipment_type, ds.site_name, dt.month, dt.year
)
SELECT 
    equipment_name,
    equipment_type,
    site_name,
    year,
    month,
    monthly_efficiency,
    monthly_maintenance_cost,
    efficiency_3month_avg,
    maintenance_3month_avg,
    
    -- Prediction Indicators
    CASE 
        WHEN monthly_efficiency < efficiency_3month_avg * 0.85 THEN 'High Risk'
        WHEN monthly_efficiency < efficiency_3month_avg * 0.9 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END as maintenance_risk_level,
    
    CASE 
        WHEN monthly_maintenance_cost > maintenance_3month_avg * 1.5 THEN 'High Cost Alert'
        WHEN monthly_maintenance_cost > maintenance_3month_avg * 1.2 THEN 'Medium Cost Alert'
        ELSE 'Normal'
    END as cost_alert_level,
    
    -- Recommendation
    CASE 
        WHEN monthly_efficiency < efficiency_3month_avg * 0.85 AND monthly_maintenance_cost > maintenance_3month_avg * 1.2 
        THEN 'Schedule Immediate Maintenance'
        WHEN monthly_efficiency < efficiency_3month_avg * 0.9 
        THEN 'Schedule Preventive Maintenance'
        ELSE 'Continue Monitoring'
    END as recommendation

FROM EquipmentTrends
WHERE year = YEAR(GETDATE()) AND month >= MONTH(GETDATE()) - 3;
GO

-- 4.2 Production Forecast
CREATE VIEW analytics.vw_ProductionForecast AS
WITH ProductionTrends AS (
    SELECT 
        ds.site_name,
        ds.region,
        dm.material_type,
        dt.year,
        dt.month,
        
        -- Monthly Production Metrics
        SUM(fp.produced_volume) as monthly_production,
        AVG(fp.unit_cost) as avg_unit_cost,
        SUM(fp.total_cost) as total_cost,
        
        -- Equipment Performance Impact
        AVG(feu.efficiency_ratio) as avg_efficiency,
        SUM(feu.operating_hours) as total_operating_hours,
        
        -- 6-Month Rolling Average
        AVG(SUM(fp.produced_volume)) OVER (
            PARTITION BY ds.site_key, dm.material_key 
            ORDER BY dt.year, dt.month 
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ) as production_6month_avg,
        
        -- Growth Rate Calculation
        LAG(SUM(fp.produced_volume), 1) OVER (
            PARTITION BY ds.site_key, dm.material_key 
            ORDER BY dt.year, dt.month
        ) as previous_month_production

    FROM fact.FactProduction fp
    JOIN dim.DimSite ds ON fp.site_key = ds.site_key
    JOIN dim.DimMaterial dm ON fp.material_key = dm.material_key
    JOIN dim.DimTime dt ON fp.time_key = dt.time_key
    LEFT JOIN fact.FactEquipmentUsage feu ON ds.site_key = feu.site_key AND dt.time_key = feu.time_key
    WHERE dt.year >= YEAR(GETDATE()) - 1
    GROUP BY ds.site_name, ds.region, dm.material_type, dt.year, dt.month, ds.site_key, dm.material_key
)
SELECT 
    site_name,
    region,
    material_type,
    year,
    month,
    monthly_production,
    production_6month_avg,
    
    -- Growth Rate
    CASE WHEN previous_month_production > 0
         THEN ((monthly_production - previous_month_production) / previous_month_production) * 100
         ELSE 0 END as monthly_growth_rate,
    
    -- Forecasted Next Month Production (Simple Linear Trend)
    production_6month_avg * 
    (1 + CASE WHEN previous_month_production > 0
              THEN ((monthly_production - previous_month_production) / previous_month_production)
              ELSE 0 END) as forecasted_next_month,
    
    -- Confidence Level
    CASE 
        WHEN ABS(monthly_production - production_6month_avg) / NULLIF(production_6month_avg, 0) <= 0.1 THEN 'High'
        WHEN ABS(monthly_production - production_6month_avg) / NULLIF(production_6month_avg, 0) <= 0.2 THEN 'Medium'
        ELSE 'Low'
    END as forecast_confidence,
    
    -- Trend Analysis
    CASE 
        WHEN monthly_production > production_6month_avg * 1.1 THEN 'Increasing'
        WHEN monthly_production < production_6month_avg * 0.9 THEN 'Decreasing'
        ELSE 'Stable'
    END as production_trend

FROM ProductionTrends
WHERE year = YEAR(GETDATE());
GO

PRINT '✅ Predictive Analytics Queries Created';

-- =========================================================================
-- 5. DRILL-DOWN ANALYSIS QUERIES
-- =========================================================================

PRINT '';
PRINT '🔍 5. Drill-Down Analysis Queries';
PRINT '================================';

-- 5.1 Equipment Drill-Down Analysis
CREATE VIEW analytics.vw_EquipmentDrillDown AS
SELECT 
    -- Equipment Details
    de.equipment_name,
    de.equipment_type,
    de.capacity,
    de.model,
    ds.site_name,
    ds.region,
    
    -- Time Dimensions
    dt.year,
    dt.quarter,
    dt.month,
    dt.month_name,
    dt.date,
    
    -- Daily Metrics
    feu.operating_hours,
    feu.downtime_hours,
    feu.fuel_consumption,
    feu.maintenance_cost,
    feu.efficiency_ratio,
    
    -- Calculated Daily Metrics
    feu.operating_hours + feu.downtime_hours as total_scheduled_hours,
    CASE WHEN feu.operating_hours > 0 
         THEN feu.fuel_consumption / feu.operating_hours 
         ELSE 0 END as fuel_efficiency,
    
    -- Employee Information
    de2.employee_name as operator_name,
    de2.position as operator_position,
    ds2.shift_name,
    
    -- Categorization
    CASE 
        WHEN feu.efficiency_ratio >= 0.8 THEN 'High Performance'
        WHEN feu.efficiency_ratio >= 0.6 THEN 'Medium Performance'
        ELSE 'Low Performance'
    END as performance_category,
    
    CASE 
        WHEN feu.downtime_hours <= 2 THEN 'Low Downtime'
        WHEN feu.downtime_hours <= 4 THEN 'Medium Downtime'
        ELSE 'High Downtime'
    END as downtime_category

FROM fact.FactEquipmentUsage feu
JOIN dim.DimEquipment de ON feu.equipment_key = de.equipment_key
JOIN dim.DimSite ds ON feu.site_key = ds.site_key
JOIN dim.DimTime dt ON feu.time_key = dt.time_key
LEFT JOIN dim.DimEmployee de2 ON feu.equipment_key = de2.employee_key -- Assuming operator assignment
LEFT JOIN dim.DimShift ds2 ON dt.time_key = ds2.shift_key -- Assuming shift mapping
WHERE dt.date >= DATEADD(month, -6, GETDATE());
GO

-- 5.2 Production Drill-Down Analysis
CREATE VIEW analytics.vw_ProductionDrillDown AS
SELECT 
    -- Production Details
    fp.production_id,
    ds.site_name,
    ds.region,
    dm.material_name,
    dm.material_type,
    dm.unit_of_measure,
    
    -- Time Dimensions
    dt.year,
    dt.quarter,
    dt.month,
    dt.month_name,
    dt.date,
    dt.day_name,
    
    -- Production Metrics
    fp.produced_volume,
    fp.unit_cost,
    fp.total_cost,
    fp.material_quantity,
    
    -- Employee Details
    de.employee_name as operator_name,
    de.position as operator_position,
    de.department,
    
    -- Shift Information
    ds2.shift_name,
    ds2.start_time,
    ds2.end_time,
    
    -- Efficiency Calculations
    CASE WHEN fp.material_quantity > 0
         THEN fp.produced_volume / fp.material_quantity
         ELSE 0 END as material_efficiency,
    
    -- Cost Analysis
    CASE WHEN fp.produced_volume > 0
         THEN fp.total_cost / fp.produced_volume
         ELSE fp.unit_cost END as actual_unit_cost,
    
    -- Performance Categories
    CASE 
        WHEN fp.produced_volume >= dm.capacity * 0.9 THEN 'High Production'
        WHEN fp.produced_volume >= dm.capacity * 0.7 THEN 'Medium Production'
        ELSE 'Low Production'
    END as production_category,
    
    CASE 
        WHEN fp.unit_cost <= 50 THEN 'Low Cost'
        WHEN fp.unit_cost <= 100 THEN 'Medium Cost'
        ELSE 'High Cost'
    END as cost_category

FROM fact.FactProduction fp
JOIN dim.DimSite ds ON fp.site_key = ds.site_key
JOIN dim.DimMaterial dm ON fp.material_key = dm.material_key
JOIN dim.DimTime dt ON fp.time_key = dt.time_key
JOIN dim.DimEmployee de ON fp.employee_key = de.employee_key
JOIN dim.DimShift ds2 ON fp.shift_key = ds2.shift_key
WHERE dt.date >= DATEADD(month, -6, GETDATE());
GO

PRINT '✅ Drill-Down Analysis Queries Created';

-- =========================================================================
-- 6. DASHBOARD AGGREGATION VIEWS
-- =========================================================================

PRINT '';
PRINT '📈 6. Dashboard Aggregation Views';
PRINT '================================';

-- 6.1 Hourly Operations Summary
CREATE VIEW analytics.vw_HourlyOperationsSummary AS
SELECT 
    dt.date,
    DATEPART(hour, dt.date) as hour_of_day,
    ds.site_name,
    
    -- Aggregated Metrics
    COUNT(DISTINCT fp.production_id) as production_sessions,
    SUM(fp.produced_volume) as hourly_production,
    AVG(fp.unit_cost) as avg_unit_cost,
    
    COUNT(DISTINCT feu.equipment_usage_id) as equipment_activities,
    AVG(feu.efficiency_ratio) as avg_efficiency,
    SUM(feu.operating_hours) as total_operating_hours,
    SUM(feu.fuel_consumption) as total_fuel_consumption,
    
    COUNT(DISTINCT fft.transaction_id) as financial_transactions,
    SUM(fft.actual_cost) as hourly_costs

FROM dim.DimTime dt
LEFT JOIN fact.FactProduction fp ON dt.time_key = fp.time_key
LEFT JOIN fact.FactEquipmentUsage feu ON dt.time_key = feu.time_key
LEFT JOIN fact.FactFinancialTransaction fft ON dt.time_key = fft.time_key
LEFT JOIN dim.DimSite ds ON fp.site_key = ds.site_key OR feu.site_key = ds.site_key OR fft.site_key = ds.site_key
WHERE dt.date >= DATEADD(day, -7, GETDATE())
GROUP BY dt.date, DATEPART(hour, dt.date), ds.site_name
HAVING COUNT(DISTINCT fp.production_id) > 0 OR COUNT(DISTINCT feu.equipment_usage_id) > 0;
GO

-- 6.2 Regional Performance Summary
CREATE VIEW analytics.vw_RegionalPerformanceSummary AS
SELECT 
    ds.region,
    dt.year,
    dt.quarter,
    dt.month_name,
    
    -- Site Metrics
    COUNT(DISTINCT ds.site_key) as total_sites,
    COUNT(DISTINCT de.equipment_key) as total_equipment,
    
    -- Production Metrics
    SUM(fp.produced_volume) as regional_production,
    AVG(fp.unit_cost) as avg_unit_cost,
    SUM(fp.total_cost) as total_production_cost,
    
    -- Equipment Performance
    AVG(feu.efficiency_ratio) as regional_avg_efficiency,
    SUM(feu.operating_hours) as total_operating_hours,
    SUM(feu.downtime_hours) as total_downtime_hours,
    SUM(feu.maintenance_cost) as total_maintenance_cost,
    
    -- Financial Performance
    SUM(fft.budgeted_cost) as total_budget,
    SUM(fft.actual_cost) as total_actual_cost,
    SUM(fft.variance_amount) as total_variance,
    
    -- Calculated Regional KPIs
    CASE WHEN SUM(feu.operating_hours + feu.downtime_hours) > 0
         THEN (SUM(feu.operating_hours) / SUM(feu.operating_hours + feu.downtime_hours)) * 100
         ELSE 0 END as regional_utilization_percent,
    
    CASE WHEN SUM(fft.budgeted_cost) > 0
         THEN ((SUM(fft.actual_cost) - SUM(fft.budgeted_cost)) / SUM(fft.budgeted_cost)) * 100
         ELSE 0 END as regional_budget_variance_percent

FROM dim.DimSite ds
LEFT JOIN fact.FactProduction fp ON ds.site_key = fp.site_key
LEFT JOIN fact.FactEquipmentUsage feu ON ds.site_key = feu.site_key
LEFT JOIN fact.FactFinancialTransaction fft ON ds.site_key = fft.site_key
LEFT JOIN dim.DimEquipment de ON feu.equipment_key = de.equipment_key
JOIN dim.DimTime dt ON fp.time_key = dt.time_key OR feu.time_key = dt.time_key OR fft.time_key = dt.time_key
WHERE dt.year >= YEAR(GETDATE()) - 2
GROUP BY ds.region, dt.year, dt.quarter, dt.month_name
HAVING SUM(fp.produced_volume) > 0 OR SUM(feu.operating_hours) > 0;
GO

PRINT '✅ Dashboard Aggregation Views Created';

-- =========================================================================
-- 7. CREATE INDEXES FOR PERFORMANCE
-- =========================================================================

PRINT '';
PRINT '🚀 7. Creating Performance Indexes for Analytics';
PRINT '===============================================';

-- Analytics view supporting indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Analytics_FactProduction_TimeKey_SiteKey')
    CREATE INDEX IX_Analytics_FactProduction_TimeKey_SiteKey ON fact.FactProduction(time_key, site_key);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Analytics_FactEquipmentUsage_TimeKey_EquipmentKey')
    CREATE INDEX IX_Analytics_FactEquipmentUsage_TimeKey_EquipmentKey ON fact.FactEquipmentUsage(time_key, equipment_key);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Analytics_FactFinancialTransaction_TimeKey_AccountKey')
    CREATE INDEX IX_Analytics_FactFinancialTransaction_TimeKey_AccountKey ON fact.FactFinancialTransaction(time_key, account_key);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Analytics_DimTime_Date_Year_Month')
    CREATE INDEX IX_Analytics_DimTime_Date_Year_Month ON dim.DimTime(date, year, month);

PRINT '✅ Performance Indexes Created';

-- =========================================================================
-- 8. UPDATE STATISTICS
-- =========================================================================

PRINT '';
PRINT '📊 8. Updating Statistics for Optimal Performance';
PRINT '===============================================';

UPDATE STATISTICS dim.DimTime;
UPDATE STATISTICS dim.DimSite;
UPDATE STATISTICS dim.DimEquipment;
UPDATE STATISTICS dim.DimMaterial;
UPDATE STATISTICS dim.DimEmployee;
UPDATE STATISTICS dim.DimShift;
UPDATE STATISTICS dim.DimProject;
UPDATE STATISTICS dim.DimAccount;

UPDATE STATISTICS fact.FactEquipmentUsage;
UPDATE STATISTICS fact.FactProduction;
UPDATE STATISTICS fact.FactFinancialTransaction;

PRINT '✅ Statistics Updated';

-- =========================================================================
-- COMPLETION SUMMARY
-- =========================================================================

PRINT '';
PRINT '🎉 COMPREHENSIVE OLAP QUERIES CREATION COMPLETED!';
PRINT '================================================';
PRINT '';
PRINT 'Created Analytics Views:';
PRINT '  ✅ Executive Dashboard (KPIs, Monthly Trends)';
PRINT '  ✅ Operations Dashboard (Equipment Status, Site Performance)';
PRINT '  ✅ Financial Analytics (Cost Analysis, Profitability)';
PRINT '  ✅ Predictive Analytics (Maintenance Prediction, Production Forecast)';
PRINT '  ✅ Drill-Down Analysis (Equipment & Production Details)';
PRINT '  ✅ Dashboard Aggregations (Hourly & Regional Summaries)';
PRINT '';
PRINT 'Performance Optimizations:';
PRINT '  ✅ Strategic Indexes Created';
PRINT '  ✅ Statistics Updated';
PRINT '';
PRINT '🌐 Views are now ready for Dashboard Integration!';

-- Count created views
SELECT 
    'Total Analytics Views Created: ' + CAST(COUNT(*) AS VARCHAR(10)) as summary
FROM sys.views v
INNER JOIN sys.schemas s ON v.schema_id = s.schema_id
WHERE s.name = 'analytics';

PRINT '';
