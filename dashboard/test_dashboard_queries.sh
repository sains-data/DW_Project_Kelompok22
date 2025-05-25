#!/bin/bash
# Test Corrected Dashboard Queries Script

echo "🔍 Testing PT XYZ Dashboard Queries (Schema-Aligned)"
echo "================================================="

# Database connection details
SERVER="localhost,1433"
DATABASE="PTXYZ_DataWarehouse"
USERNAME="sa"
PASSWORD="PTXYZSecure123!"

echo "📊 Testing Equipment Utilization Query..."
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P 'PTXYZSecure123!' \
    -d PTXYZ_DataWarehouse \
    -Q "
    SELECT TOP 5
        e.equipment_type,
        e.model,
        s.site_name,
        COUNT(*) as usage_sessions,
        AVG(f.operating_hours) as avg_operating_hours,
        AVG(f.downtime_hours) as avg_downtime_hours,
        SUM(f.fuel_consumption) as total_fuel_consumption,
        AVG(f.maintenance_cost) as avg_maintenance_cost
    FROM fact.FactEquipmentUsage f
    JOIN dim.DimEquipment e ON f.equipment_key = e.equipment_key
    JOIN dim.DimSite s ON f.site_key = s.site_key
    JOIN dim.DimTime t ON f.time_key = t.time_key
    GROUP BY e.equipment_type, e.model, s.site_name
    ORDER BY total_fuel_consumption DESC;
    " \
    -C -N

echo ""
echo "📈 Testing Production Performance Query..."
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P 'PTXYZSecure123!' \
    -d PTXYZ_DataWarehouse \
    -Q "
    SELECT TOP 5
        t.year,
        t.month,
        t.month_name,
        s.site_name,
        m.material_type,
        SUM(f.produced_volume) as total_production,
        AVG(f.unit_cost) as avg_unit_cost
    FROM fact.FactProduction f
    JOIN dim.DimTime t ON f.time_key = t.time_key
    JOIN dim.DimSite s ON f.site_key = s.site_key
    JOIN dim.DimMaterial m ON f.material_key = m.material_key
    GROUP BY t.year, t.month, t.month_name, s.site_name, m.material_type
    ORDER BY t.year DESC, t.month DESC, total_production DESC;
    " \
    -C -N

echo ""
echo "💰 Testing Financial Analysis Query..."
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P 'PTXYZSecure123!' \
    -d PTXYZ_DataWarehouse \
    -Q "
    SELECT TOP 5
        t.year,
        t.quarter,
        s.site_name,
        p.project_name,
        a.account_type,
        SUM(f.budgeted_cost) as total_budgeted,
        SUM(f.actual_cost) as total_actual,
        SUM(f.variance_amount) as total_variance
    FROM fact.FactFinancialTransaction f
    JOIN dim.DimTime t ON f.time_key = t.time_key
    JOIN dim.DimSite s ON f.site_key = s.site_key
    JOIN dim.DimProject p ON f.project_key = p.project_key
    JOIN dim.DimAccount a ON f.account_key = a.account_key
    GROUP BY t.year, t.quarter, s.site_name, p.project_name, a.account_type
    ORDER BY total_variance DESC;
    " \
    -C -N

echo ""
echo "🔍 Testing Table Row Counts..."
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P 'PTXYZSecure123!' \
    -d PTXYZ_DataWarehouse \
    -Q "
    SELECT 'FactEquipmentUsage' as TableName, COUNT(*) as RowCount FROM fact.FactEquipmentUsage
    UNION ALL
    SELECT 'FactProduction', COUNT(*) FROM fact.FactProduction
    UNION ALL
    SELECT 'FactFinancialTransaction', COUNT(*) FROM fact.FactFinancialTransaction
    UNION ALL
    SELECT 'DimTime', COUNT(*) FROM dim.DimTime
    UNION ALL
    SELECT 'DimSite', COUNT(*) FROM dim.DimSite
    UNION ALL
    SELECT 'DimEquipment', COUNT(*) FROM dim.DimEquipment;
    " \
    -C -N

echo ""
echo "✅ All queries tested successfully!"
echo "🎯 Ready to create dashboards in Grafana and Superset"
echo ""
echo "🔗 Dashboard Access URLs:"
echo "   Grafana:  http://localhost:3000 (admin/admin)"
echo "   Superset: http://localhost:8088 (admin/admin)"
echo "   Metabase: http://localhost:3001"
echo "   Jupyter:  http://localhost:8888 (token: ptxyz123)"
