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
    SUM(f.fuel_consumption) as total_fuel_consumption,
    AVG(f.maintenance_hours) as avg_maintenance_hours
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
    s.site_name,
    m.material_type,
    SUM(f.tonnage_produced) as total_production,
    AVG(f.quality_score) as avg_quality_score,
    COUNT(*) as production_sessions
FROM fact.FactProduction f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimMaterial m ON f.material_key = m.material_key
GROUP BY t.year, t.month, s.site_name, m.material_type
ORDER BY t.year DESC, t.month DESC, total_production DESC;

-- 3. Financial Analysis Dashboard
SELECT 
    t.year,
    t.quarter,
    s.site_name,
    a.account_type,
    a.account_name,
    SUM(f.transaction_amount) as total_amount,
    COUNT(*) as transaction_count,
    AVG(f.transaction_amount) as avg_transaction_amount
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
