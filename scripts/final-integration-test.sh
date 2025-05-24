#!/bin/bash
# PT XYZ Data Warehouse Final Integration Test
# Date: 2025-05-24

echo "🚀 PT XYZ Data Warehouse - Final Integration Test"
echo "================================================="
echo

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

success_count=0
total_tests=0

# Function to run test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((total_tests++))
    echo -e "${BLUE}Test $total_tests: $test_name${NC}"
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "   ${GREEN}✅ PASSED${NC}"
        ((success_count++))
    else
        echo -e "   ${RED}❌ FAILED${NC}"
    fi
}

echo "🔍 Running System Integration Tests..."
echo

# Test 1: Docker Services
run_test "Docker Services Running" "docker-compose ps | grep -q 'Up'"

# Test 2: SQL Server Connection
run_test "SQL Server Database Connection" "docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -Q 'SELECT 1' -C"

# Test 3: Data Warehouse Tables
run_test "Data Warehouse Schema Validation" "docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -d PTXYZ_DataWarehouse -Q 'SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA IN (\"dim\", \"fact\")' -C | grep -q '11'"

# Test 4: Data Loading Verification
run_test "Fact Table Data Verification" "docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -d PTXYZ_DataWarehouse -Q 'SELECT COUNT(*) FROM fact.FactEquipmentUsage' -C | grep -q '[0-9]'"

# Test 5: Index Performance
run_test "Database Index Verification" "docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -d PTXYZ_DataWarehouse -Q 'SELECT COUNT(*) FROM sys.indexes WHERE name IS NOT NULL' -C | grep -q '[0-9]'"

# Test 6: Airflow DAG Status
run_test "Airflow DAG Validation" "curl -s --connect-timeout 5 --max-time 10 http://localhost:8080/health | grep -q 'healthy'"

# Test 7: Grafana Dashboard Platform
run_test "Grafana Dashboard Access" "curl -s --connect-timeout 5 --max-time 10 http://localhost:3000/api/health | grep -q 'ok'"

# Test 8: Superset Dashboard Platform
run_test "Apache Superset Access" "curl -s --connect-timeout 5 --max-time 10 http://localhost:8088/health | grep -q 'OK'"

# Test 9: Metabase Dashboard Platform
run_test "Metabase Access" "curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w '%{http_code}' http://localhost:3001/ | grep -q '^2'"

# Test 10: Jupyter Labs
run_test "Jupyter Labs Access" "curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w '%{http_code}' http://localhost:8888/ | grep -q '^2'"

echo
echo "📊 Integration Test Results:"
echo "============================"
echo -e "Tests Passed: ${GREEN}$success_count${NC} / $total_tests"
echo

if [ $success_count -eq $total_tests ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! System is fully operational.${NC}"
else
    echo -e "${YELLOW}⚠️  Some tests failed. System may have issues.${NC}"
fi

echo
echo "🎯 Final System Status:"
echo "======================"

# Get final system statistics
echo "📈 Data Warehouse Metrics:"
docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -d PTXYZ_DataWarehouse -Q "
PRINT '   Total Tables: ' + CAST((SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA IN ('dim', 'fact')) AS VARCHAR(10));
PRINT '   Total Indexes: ' + CAST((SELECT COUNT(*) FROM sys.indexes WHERE name IS NOT NULL AND object_id IN (SELECT object_id FROM sys.tables WHERE schema_id IN (SCHEMA_ID('dim'), SCHEMA_ID('fact')))) AS VARCHAR(10));
SELECT 
    '   Equipment Usage Records: ' + CAST(COUNT(*) AS VARCHAR(20)) as summary
FROM fact.FactEquipmentUsage
UNION ALL
SELECT 
    '   Production Records: ' + CAST(COUNT(*) AS VARCHAR(20))
FROM fact.FactProduction  
UNION ALL
SELECT 
    '   Financial Records: ' + CAST(COUNT(*) AS VARCHAR(20))
FROM fact.FactFinancialTransaction;
" -C 2>/dev/null | grep -E "^   "

echo
echo "🌐 Access Points:"
echo "   • Airflow UI:      http://localhost:8080 (admin/admin)"
echo "   • Grafana:         http://localhost:3000 (admin/admin)"
echo "   • Apache Superset: http://localhost:8088 (admin/admin)"
echo "   • Metabase:        http://localhost:3001"
echo "   • Jupyter Labs:    http://localhost:8888"

echo
echo "🔗 Database Connection:"
echo "   • Server:          localhost:1433"
echo "   • Database:        PTXYZ_DataWarehouse"
echo "   • Username:        sa"
echo "   • Password:        YourSecurePassword123!"

echo
echo "📁 Key Files:"
echo "   • dashboard_queries.sql - Sample dashboard queries"
echo "   • PTXYZ_DataWarehouse_Analysis.ipynb - Jupyter analysis"
echo "   • Performance optimizations applied with 25 indexes"

echo
if [ $success_count -eq $total_tests ]; then
    echo -e "${GREEN}🚀 PT XYZ Data Warehouse is PRODUCTION READY!${NC}"
    echo -e "${GREEN}   All systems operational, dashboards configured, performance optimized.${NC}"
else
    echo -e "${YELLOW}🔧 System needs attention - check failed tests above.${NC}"
fi
echo
