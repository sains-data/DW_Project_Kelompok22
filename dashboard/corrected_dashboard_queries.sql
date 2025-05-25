-- ========================================
-- PT XYZ Data Warehouse - Corrected Dashboard Queries
-- Schema-Aligned Version
-- ========================================

-- 1. Equipment Utilization Dashboard (CORRECTED)
SELECT 
    e.equipment_type,
    e.model,
    s.site_name,
    s.region,
    COUNT(*) as usage_sessions,
    AVG(f.operating_hours) as avg_operating_hours,
    AVG(f.downtime_hours) as avg_downtime_hours,
    SUM(f.fuel_consumption) as total_fuel_consumption,
    AVG(f.maintenance_cost) as avg_maintenance_cost,
    AVG(f.efficiency_ratio) as avg_efficiency_ratio
FROM fact.FactEquipmentUsage f
JOIN dim.DimEquipment e ON f.equipment_key = e.equipment_key
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE t.year = 2024
GROUP BY e.equipment_type, e.model, s.site_name, s.region
ORDER BY total_fuel_consumption DESC;

-- 2. Production Performance Dashboard (CORRECTED)
SELECT 
    t.year,
    t.month,
    t.month_name,
    s.site_name,
    s.region,
    m.material_type,
    m.material_name,
    SUM(f.produced_volume) as total_production,
    AVG(f.unit_cost) as avg_unit_cost,
    SUM(f.total_cost) as total_cost,
    COUNT(*) as production_sessions
FROM fact.FactProduction f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimMaterial m ON f.material_key = m.material_key
GROUP BY t.year, t.month, t.month_name, s.site_name, s.region, m.material_type, m.material_name
ORDER BY t.year DESC, t.month DESC, total_production DESC;

-- 3. Financial Analysis Dashboard (CORRECTED)
SELECT 
    t.year,
    t.quarter,
    s.site_name,
    s.region,
    p.project_name,
    a.account_type,
    a.account_name,
    SUM(f.budgeted_cost) as total_budgeted,
    SUM(f.actual_cost) as total_actual,
    SUM(f.variance_amount) as total_variance,
    AVG(f.variance_percentage) as avg_variance_percentage,
    COUNT(*) as transaction_count
FROM fact.FactFinancialTransaction f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimProject p ON f.project_key = p.project_key
JOIN dim.DimAccount a ON f.account_key = a.account_key
WHERE t.year = 2024
GROUP BY t.year, t.quarter, s.site_name, s.region, p.project_name, a.account_type, a.account_name
ORDER BY total_variance DESC;

-- 4. Site Performance Overview (CORRECTED)
SELECT 
    s.site_name,
    s.region,
    COUNT(DISTINCT f1.equipment_key) as equipment_count,
    SUM(f1.operating_hours) as total_operating_hours,
    AVG(f1.efficiency_ratio) as avg_equipment_efficiency,
    SUM(f2.produced_volume) as total_production,
    SUM(f3.actual_cost) as total_costs
FROM dim.DimSite s
LEFT JOIN fact.FactEquipmentUsage f1 ON s.site_key = f1.site_key
LEFT JOIN fact.FactProduction f2 ON s.site_key = f2.site_key
LEFT JOIN fact.FactFinancialTransaction f3 ON s.site_key = f3.site_key
LEFT JOIN dim.DimTime t ON f1.time_key = t.time_key
WHERE t.year = 2024 OR t.year IS NULL
GROUP BY s.site_name, s.region
ORDER BY total_production DESC;

-- 5. Monthly Trends Summary (CORRECTED)
SELECT 
    t.year,
    t.month,
    t.month_name,
    SUM(f1.operating_hours) as total_operating_hours,
    SUM(f1.fuel_consumption) as total_fuel_consumption,
    AVG(f1.efficiency_ratio) as avg_equipment_efficiency,
    SUM(f2.produced_volume) as total_production,
    SUM(f3.budgeted_cost) as total_budgeted,
    SUM(f3.actual_cost) as total_actual,
    SUM(f3.variance_amount) as total_variance
FROM dim.DimTime t
LEFT JOIN fact.FactEquipmentUsage f1 ON t.time_key = f1.time_key
LEFT JOIN fact.FactProduction f2 ON t.time_key = f2.time_key
LEFT JOIN fact.FactFinancialTransaction f3 ON t.time_key = f3.time_key
WHERE t.year = 2024
GROUP BY t.year, t.month, t.month_name
ORDER BY t.year, t.month;

-- ========================================
-- OLAP DRILL-DOWN QUERIES
-- ========================================

-- 6. Equipment Performance by Time Period (OLAP Drill-Down)
SELECT 
    t.year,
    t.quarter,
    t.month,
    e.equipment_type,
    e.equipment_name,
    s.site_name,
    SUM(f.operating_hours) as total_operating_hours,
    SUM(f.downtime_hours) as total_downtime_hours,
    AVG(f.efficiency_ratio) as avg_efficiency,
    SUM(f.fuel_consumption) as total_fuel,
    SUM(f.maintenance_cost) as total_maintenance_cost
FROM fact.FactEquipmentUsage f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimEquipment e ON f.equipment_key = e.equipment_key
JOIN dim.DimSite s ON f.site_key = s.site_key
GROUP BY ROLLUP(t.year, t.quarter, t.month, e.equipment_type, e.equipment_name, s.site_name)
ORDER BY t.year, t.quarter, t.month, e.equipment_type;

-- 7. Production Analysis with OLAP (Drill-Down by Geography and Material)
SELECT 
    s.region,
    s.site_name,
    m.material_type,
    m.material_name,
    t.year,
    t.quarter,
    SUM(f.produced_volume) as total_production,
    AVG(f.unit_cost) as avg_unit_cost,
    SUM(f.total_cost) as total_cost
FROM fact.FactProduction f
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimMaterial m ON f.material_key = m.material_key
JOIN dim.DimTime t ON f.time_key = t.time_key
GROUP BY ROLLUP(s.region, s.site_name, m.material_type, m.material_name, t.year, t.quarter)
ORDER BY s.region, s.site_name, m.material_type, t.year, t.quarter;

-- 8. Financial Performance OLAP Cube
SELECT 
    t.year,
    t.quarter,
    s.region,
    s.site_name,
    p.project_name,
    a.account_type,
    SUM(f.budgeted_cost) as total_budgeted,
    SUM(f.actual_cost) as total_actual,
    SUM(f.variance_amount) as total_variance,
    AVG(f.variance_percentage) as avg_variance_pct
FROM fact.FactFinancialTransaction f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimProject p ON f.project_key = p.project_key
JOIN dim.DimAccount a ON f.account_key = a.account_key
GROUP BY CUBE(t.year, t.quarter, s.region, s.site_name, p.project_name, a.account_type)
ORDER BY t.year, t.quarter, s.region;

-- ========================================
-- KPI QUERIES FOR DASHBOARDS
-- ========================================

-- 9. Key Performance Indicators (Current Month)
WITH CurrentMonth AS (
    SELECT time_key 
    FROM dim.DimTime 
    WHERE year = YEAR(GETDATE()) 
    AND month = MONTH(GETDATE())
)
SELECT 
    'Equipment Efficiency' as KPI,
    CAST(AVG(f.efficiency_ratio) * 100 AS DECIMAL(5,2)) as Value,
    '%' as Unit
FROM fact.FactEquipmentUsage f
WHERE f.time_key IN (SELECT time_key FROM CurrentMonth)

UNION ALL

SELECT 
    'Total Production' as KPI,
    CAST(SUM(f.produced_volume) AS DECIMAL(12,2)) as Value,
    'Tons' as Unit
FROM fact.FactProduction f
WHERE f.time_key IN (SELECT time_key FROM CurrentMonth)

UNION ALL

SELECT 
    'Budget Variance' as KPI,
    CAST(AVG(f.variance_percentage) AS DECIMAL(5,2)) as Value,
    '%' as Unit
FROM fact.FactFinancialTransaction f
WHERE f.time_key IN (SELECT time_key FROM CurrentMonth);

-- 10. Real-time Operational Dashboard Query
SELECT 
    s.site_name,
    s.region,
    COUNT(DISTINCT e.equipment_key) as active_equipment,
    SUM(CASE WHEN f1.operating_hours > 0 THEN 1 ELSE 0 END) as operational_equipment,
    AVG(f1.efficiency_ratio) * 100 as avg_efficiency_pct,
    SUM(f2.produced_volume) as daily_production,
    SUM(f3.actual_cost) as daily_costs
FROM dim.DimSite s
LEFT JOIN fact.FactEquipmentUsage f1 ON s.site_key = f1.site_key
LEFT JOIN dim.DimEquipment e ON f1.equipment_key = e.equipment_key
LEFT JOIN fact.FactProduction f2 ON s.site_key = f2.site_key
LEFT JOIN fact.FactFinancialTransaction f3 ON s.site_key = f3.site_key
JOIN dim.DimTime t ON (f1.time_key = t.time_key OR f2.time_key = t.time_key OR f3.time_key = t.time_key)
WHERE t.date = CAST(GETDATE() AS DATE)
GROUP BY s.site_name, s.region
ORDER BY daily_production DESC;
