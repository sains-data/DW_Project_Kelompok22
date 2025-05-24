#!/bin/bash

# PT XYZ Data Warehouse - Final Deployment Verification Script
# This script performs comprehensive verification of the entire system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

echo -e "${BLUE}🚀 PT XYZ Data Warehouse - Final Deployment Verification${NC}"
echo "=================================================================="
echo ""

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}✅ $message${NC}"
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
    else
        echo -e "${RED}❌ $message${NC}"
    fi
}

# Function to test HTTP endpoint
test_endpoint() {
    local url=$1
    local name=$2
    local expected_code=${3:-200}
    
    echo -n "Testing $name ($url)... "
    
    local http_code=$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if echo "$http_code" | grep -q "$expected_code"; then
        print_status "OK" "$name is accessible"
        return 0
    else
        print_status "FAIL" "$name is not accessible (HTTP: $http_code)"
        return 1
    fi
}

# Function to test SQL Server connection
test_sqlserver() {
    echo -n "Testing SQL Server connection... "
    
    if docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -Q "SELECT 1" -C -N > /dev/null 2>&1; then
        print_status "OK" "SQL Server connection successful"
        return 0
    else
        print_status "FAIL" "SQL Server connection failed"
        return 1
    fi
}

# Function to verify data warehouse tables
verify_data_warehouse() {
    echo -n "Verifying data warehouse tables... "
    
    local query="USE PTXYZ_DataWarehouse; SELECT COUNT(*) FROM information_schema.tables WHERE table_schema IN ('dim', 'fact', 'staging');"
    
    local result=$(docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -Q "$query" -C -N -h -1 2>/dev/null | grep -E '^[[:space:]]*[0-9]+[[:space:]]*$' | tr -d ' ')
    
    if [ "$result" -ge "14" ]; then
        print_status "OK" "Data warehouse schema verified ($result tables)"
        return 0
    else
        print_status "FAIL" "Data warehouse schema incomplete ($result tables found)"
        return 1
    fi
}

# Function to verify data loading
verify_data_loading() {
    echo -n "Verifying data loading... "
    
    local query="USE PTXYZ_DataWarehouse; SELECT (SELECT COUNT(*) FROM fact.FactEquipmentUsage) + (SELECT COUNT(*) FROM fact.FactProduction) + (SELECT COUNT(*) FROM fact.FactFinancialTransaction);"
    
    local result=$(docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -Q "$query" -C -N -h -1 2>/dev/null | grep -E '^[[:space:]]*[0-9]+[[:space:]]*$' | tr -d ' ')
    
    if [ "$result" -gt "300000" ]; then
        print_status "OK" "Data successfully loaded ($result fact records)"
        return 0
    else
        print_status "WARN" "Data loading incomplete ($result fact records)"
        return 1
    fi
}

# Start verification
echo -e "${YELLOW}📋 Starting System Verification...${NC}"
echo ""

# 1. Check Docker services
echo -e "${BLUE}1. Docker Services Status:${NC}"
RUNNING_CONTAINERS=$(docker ps --format "{{.Names}}" | grep "ptxyz_" | wc -l)

if [ "$RUNNING_CONTAINERS" -eq "11" ]; then
    print_status "OK" "All 11 services are running"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep "ptxyz_"
else
    print_status "FAIL" "Only $RUNNING_CONTAINERS/11 services are running"
    echo "Missing services:"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep "ptxyz_"
fi

echo ""

# 2. Database connectivity
echo -e "${BLUE}2. Database Connectivity:${NC}"
test_sqlserver
verify_data_warehouse
verify_data_loading

echo ""

# 3. Web services accessibility
echo -e "${BLUE}3. Web Services Accessibility:${NC}"
test_endpoint "http://localhost:8080/health" "Airflow Web UI"
test_endpoint "http://localhost:3000/api/health" "Grafana" "200\|302"
test_endpoint "http://localhost:8088/health" "Apache Superset"
test_endpoint "http://localhost:3001/" "Metabase" "200\|302"
test_endpoint "http://localhost:8888/" "Jupyter Labs" "200\|302"

echo ""

# 4. Data quality summary
echo -e "${BLUE}4. Data Warehouse Summary:${NC}"

if test_sqlserver; then
    echo "Generating data quality report..."
    
    # Copy the SQL script into the container first
    cat << 'EOF' > data_summary.sql
USE PTXYZ_DataWarehouse;

PRINT '=== Data Warehouse Summary Report ===';
PRINT '';

-- Staging Tables Summary
PRINT 'STAGING TABLES:';
SELECT 'Equipment Usage: ' + CAST(COUNT(*) AS VARCHAR(10)) + ' records' as summary FROM staging.EquipmentUsage;
SELECT 'Production: ' + CAST(COUNT(*) AS VARCHAR(10)) + ' records' as summary FROM staging.Production;
SELECT 'Financial Transactions: ' + CAST(COUNT(*) AS VARCHAR(10)) + ' records' as summary FROM staging.FinancialTransaction;

PRINT '';
PRINT 'DIMENSION TABLES:';
SELECT 'Time: ' + CAST(COUNT(*) AS VARCHAR(10)) + ' records' as summary FROM dim.DimTime;
SELECT 'Sites: ' + CAST(COUNT(*) AS VARCHAR(10)) + ' records' as summary FROM dim.DimSite;
SELECT 'Equipment: ' + CAST(COUNT(*) AS VARCHAR(10)) + ' records' as summary FROM dim.DimEquipment;
SELECT 'Materials: ' + CAST(COUNT(*) AS VARCHAR(10)) + ' records' as summary FROM dim.DimMaterial;
SELECT 'Employees: ' + CAST(COUNT(*) AS VARCHAR(10)) + ' records' as summary FROM dim.DimEmployee;
SELECT 'Projects: ' + CAST(COUNT(*) AS VARCHAR(10)) + ' records' as summary FROM dim.DimProject;
SELECT 'Accounts: ' + CAST(COUNT(*) AS VARCHAR(10)) + ' records' as summary FROM dim.DimAccount;

PRINT '';
PRINT 'FACT TABLES:';
SELECT 'Equipment Usage: ' + CAST(COUNT(*) AS VARCHAR(10)) + ' records' as summary FROM fact.FactEquipmentUsage;
SELECT 'Production: ' + CAST(COUNT(*) AS VARCHAR(10)) + ' records' as summary FROM fact.FactProduction;
SELECT 'Financial: ' + CAST(COUNT(*) AS VARCHAR(10)) + ' records' as summary FROM fact.FactFinancialTransaction;

PRINT '';
PRINT 'TOTAL RECORDS:';
SELECT 
    'Total: ' + CAST((
        (SELECT COUNT(*) FROM staging.EquipmentUsage) +
        (SELECT COUNT(*) FROM staging.Production) + 
        (SELECT COUNT(*) FROM staging.FinancialTransaction) +
        (SELECT COUNT(*) FROM dim.DimTime) +
        (SELECT COUNT(*) FROM dim.DimSite) +
        (SELECT COUNT(*) FROM dim.DimEquipment) +
        (SELECT COUNT(*) FROM dim.DimMaterial) +
        (SELECT COUNT(*) FROM dim.DimEmployee) +
        (SELECT COUNT(*) FROM dim.DimProject) +
        (SELECT COUNT(*) FROM dim.DimAccount) +
        (SELECT COUNT(*) FROM fact.FactEquipmentUsage) +
        (SELECT COUNT(*) FROM fact.FactProduction) +
        (SELECT COUNT(*) FROM fact.FactFinancialTransaction)
    ) AS VARCHAR(10)) + ' records' as summary;
EOF

    # Copy the file to the container and execute it
    docker cp data_summary.sql ptxyz_sqlserver:/tmp/data_summary.sql
    docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -i /tmp/data_summary.sql -C -N
    rm -f data_summary.sql
fi

echo ""

# 5. System resources
echo -e "${BLUE}5. System Resources:${NC}"
echo "Docker container resource usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep "ptxyz_" | head -11

echo ""

# 6. Access information
echo -e "${BLUE}6. Access Information:${NC}"
echo -e "${GREEN}🌐 Web Interfaces:${NC}"
echo "  • Airflow UI:      http://localhost:8080 (admin/admin)"
echo "  • Grafana:         http://localhost:3000 (admin/admin)"
echo "  • Apache Superset: http://localhost:8088 (admin/admin)"
echo "  • Metabase:        http://localhost:3001"
echo "  • Jupyter Labs:    http://localhost:8888"
echo ""
echo -e "${GREEN}🔌 Database Connection:${NC}"
echo "  • SQL Server:      localhost:1433"
echo "  • Database:        PTXYZ_DataWarehouse"
echo "  • Username:        sa"
echo "  • Password:        YourSecurePassword123!"

echo ""

# Final status
echo -e "${BLUE}🎯 Deployment Status:${NC}"
if [ "$RUNNING_CONTAINERS" -eq "11" ] && test_sqlserver >/dev/null 2>&1; then
    echo -e "${GREEN}✅ DEPLOYMENT SUCCESSFUL${NC}"
    echo -e "${GREEN}✅ All services operational${NC}"
    echo -e "${GREEN}✅ Data warehouse ready${NC}"
    echo -e "${GREEN}✅ ETL pipeline functional${NC}"
    echo -e "${GREEN}✅ Visualization platforms ready${NC}"
    echo ""
    echo -e "${YELLOW}🚀 PT XYZ Data Warehouse is PRODUCTION READY!${NC}"
    exit 0
else
    echo -e "${RED}❌ DEPLOYMENT ISSUES DETECTED${NC}"
    echo "Please check the above errors and restart services if needed."
    exit 1
fi
