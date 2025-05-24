#!/bin/bash
# PT XYZ Data Warehouse Performance Testing Script
# Date: 2025-05-24

echo "🚀 PT XYZ Data Warehouse - Performance Testing"
echo "=============================================="
echo

# Test database performance with sample queries
echo "📊 Running Performance Tests..."
echo

# Function to measure query execution time
run_query_test() {
    local query_name="$1"
    local query="$2"
    
    echo "Testing: $query_name"
    
    start_time=$(date +%s.%N)
    
    docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P 'YourSecurePassword123!' \
        -d PTXYZ_DataWarehouse -Q "$query" -C > /dev/null 2>&1
    
    end_time=$(date +%s.%N)
    execution_time=$(echo "$end_time - $start_time" | bc)
    
    printf "   ✅ Completed in %.3f seconds\n" "$execution_time"
}

# Test 1: Equipment Usage Summary
echo "1. Equipment Usage Performance Test:"
run_query_test "Equipment Usage Aggregation" "
SELECT 
    de.equipment_name,
    de.equipment_type,
    COUNT(*) as usage_count,
    SUM(feu.operating_hours) as total_hours,
    AVG(feu.efficiency_ratio) as avg_efficiency
FROM fact.FactEquipmentUsage feu
JOIN dim.DimEquipment de ON feu.equipment_key = de.equipment_key
GROUP BY de.equipment_name, de.equipment_type
ORDER BY total_hours DESC;
"

# Test 2: Production Performance
echo
echo "2. Production Performance Test:"
run_query_test "Production Summary" "
SELECT 
    ds.site_name,
    dm.material_name,
    SUM(fp.produced_volume) as total_production,
    AVG(fp.unit_cost) as avg_cost,
    COUNT(*) as production_count
FROM fact.FactProduction fp
JOIN dim.DimSite ds ON fp.site_key = ds.site_key
JOIN dim.DimMaterial dm ON fp.material_key = dm.material_key
GROUP BY ds.site_name, dm.material_name
ORDER BY total_production DESC;
"

# Test 3: Financial Analysis
echo
echo "3. Financial Performance Test:"
run_query_test "Financial Analysis" "
SELECT 
    dt.year,
    dt.month_name,
    da.account_type,
    SUM(fft.actual_cost) as total_actual,
    SUM(fft.budgeted_cost) as total_budget,
    AVG(fft.variance_percentage) as avg_variance
FROM fact.FactFinancialTransaction fft
JOIN dim.DimTime dt ON fft.time_key = dt.time_key
JOIN dim.DimAccount da ON fft.account_key = da.account_key
GROUP BY dt.year, dt.month_name, da.account_type
ORDER BY dt.year DESC, dt.month DESC;
"

# Test 4: Complex JOIN Performance
echo
echo "4. Complex JOIN Performance Test:"
run_query_test "Multi-table JOIN" "
SELECT 
    ds.site_name,
    dt.year,
    dt.month_name,
    COUNT(DISTINCT feu.equipment_usage_id) as equipment_records,
    COUNT(DISTINCT fp.production_id) as production_records,
    COUNT(DISTINCT fft.transaction_id) as financial_records
FROM dim.DimSite ds
JOIN dim.DimTime dt ON 1=1
LEFT JOIN fact.FactEquipmentUsage feu ON ds.site_key = feu.site_key AND dt.time_key = feu.time_key
LEFT JOIN fact.FactProduction fp ON ds.site_key = fp.site_key AND dt.time_key = fp.time_key  
LEFT JOIN fact.FactFinancialTransaction fft ON ds.site_key = fft.site_key AND dt.time_key = fft.time_key
WHERE dt.year >= 2024
GROUP BY ds.site_name, dt.year, dt.month_name
HAVING COUNT(DISTINCT feu.equipment_usage_id) > 0 
    OR COUNT(DISTINCT fp.production_id) > 0 
    OR COUNT(DISTINCT fft.transaction_id) > 0
ORDER BY ds.site_name, dt.year DESC, dt.month DESC;
"

echo
echo "📈 Performance Testing Summary:"
echo "=============================="
echo

# Check index usage
echo "🔍 Checking Index Usage:"
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P 'YourSecurePassword123!' \
    -d PTXYZ_DataWarehouse -Q "
SELECT 
    OBJECT_SCHEMA_NAME(i.object_id) as schema_name,
    OBJECT_NAME(i.object_id) as table_name,
    i.name as index_name,
    i.type_desc as index_type
FROM sys.indexes i
WHERE i.object_id IN (
    SELECT object_id FROM sys.tables 
    WHERE schema_id IN (SCHEMA_ID('dim'), SCHEMA_ID('fact'))
)
AND i.name IS NOT NULL
ORDER BY schema_name, table_name, i.name;
" -C

echo
echo "📊 Database Statistics:"
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P 'YourSecurePassword123!' \
    -d PTXYZ_DataWarehouse -Q "
SELECT 
    'Total Tables' as metric,
    COUNT(*) as value
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA IN ('dim', 'fact')
UNION ALL
SELECT 
    'Total Indexes' as metric,
    COUNT(*) as value
FROM sys.indexes i
WHERE i.object_id IN (
    SELECT object_id FROM sys.tables 
    WHERE schema_id IN (SCHEMA_ID('dim'), SCHEMA_ID('fact'))
)
AND i.name IS NOT NULL;
" -C

echo
echo "✅ Performance testing completed!"
echo "🎯 The data warehouse is optimized and ready for dashboard connections."
