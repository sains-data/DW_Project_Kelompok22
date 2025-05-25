-- ========================================
-- PT XYZ Data Warehouse - Sample Dashboard Queries
-- ========================================

-- 1. Equipment Utilization Dashboard
SELECT 
    e.equipment_type,
    e.model,
    s.site_name,
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
GROUP BY e.equipment_type, e.model, s.site_name
ORDER BY total_fuel_consumption DESC;

-- 2. Production Performance Dashboard
SELECT 
    t.year,
    t.month,
    t.month_name,
    s.site_name,
    m.material_type,
    SUM(f.produced_volume) as total_production,
    AVG(f.unit_cost) as avg_unit_cost,
    SUM(f.total_cost) as total_cost,
    COUNT(*) as production_sessions
FROM fact.FactProduction f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimMaterial m ON f.material_key = m.material_key
GROUP BY t.year, t.month, t.month_name, s.site_name, m.material_type
ORDER BY t.year DESC, t.month DESC, total_production DESC;

-- 3. Financial Analysis Dashboard
SELECT 
    t.year,
    t.quarter,
    s.site_name,
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
JOIN dim.DimAccount a ON f.account_key = a.account_key
GROUP BY t.year, t.quarter, s.site_name, a.account_type, a.account_name
ORDER BY t.year DESC, t.quarter DESC, total_amount DESC;

-- 4. Site Performance Overview
SELECT 
    s.site_name,
    s.location,
    s.site_type,
    COUNT(DISTINCT eu.equipment_key) as equipment_count,
    SUM(p.tonnage_produced) as total_production,
    SUM(ft.transaction_amount) as total_revenue,
    AVG(p.quality_score) as avg_quality
FROM dim.DimSite s
LEFT JOIN fact.FactEquipmentUsage eu ON s.site_key = eu.site_key
LEFT JOIN fact.FactProduction p ON s.site_key = p.site_key
LEFT JOIN fact.FactFinancialTransaction ft ON s.site_key = ft.site_key
GROUP BY s.site_name, s.location, s.site_type
ORDER BY total_production DESC;

-- 5. Monthly Trends Summary
SELECT 
    t.year,
    t.month,
    t.month_name,
    COUNT(DISTINCT eu.equipment_key) as active_equipment,
    SUM(p.tonnage_produced) as monthly_production,
    SUM(ft.transaction_amount) as monthly_revenue,
    AVG(eu.fuel_consumption) as avg_fuel_consumption
FROM dim.DimTime t
LEFT JOIN fact.FactEquipmentUsage eu ON t.time_key = eu.time_key
LEFT JOIN fact.FactProduction p ON t.time_key = p.time_key
LEFT JOIN fact.FactFinancialTransaction ft ON t.time_key = ft.time_key
WHERE t.year >= 2023
GROUP BY t.year, t.month, t.month_name
ORDER BY t.year DESC, t.month DESC;
