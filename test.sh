#!/bin/bash

# PT XYZ Data Warehouse Test Script
echo "=== PT XYZ Data Warehouse Test Script ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a service is running
check_service() {
    local service_name=$1
    local port=$2
    
    echo -n "Checking $service_name on port $port: "
    
    if docker compose ps | grep -q "$service_name.*Up"; then
        if nc -z localhost $port 2>/dev/null; then
            echo -e "${GREEN}✓ Running${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ Container up but port not accessible${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Not running${NC}"
        return 1
    fi
}

# Function to test database connection
test_database() {
    echo -n "Testing SQL Server connection: "
    
    if docker compose exec -T sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'PTXYZDataWarehouse2025!' -Q "SELECT 1" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Connected${NC}"
        
        echo -n "Testing DW_PTXYZ database: "
        if docker compose exec -T sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'PTXYZDataWarehouse2025!' -d DW_PTXYZ -Q "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Database accessible${NC}"
        else
            echo -e "${YELLOW}⚠ Database not found or not accessible${NC}"
        fi
    else
        echo -e "${RED}✗ Connection failed${NC}"
    fi
}

# Function to test web services
test_web_service() {
    local service_name=$1
    local url=$2
    
    echo -n "Testing $service_name web interface: "
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|302\|401"; then
        echo -e "${GREEN}✓ Accessible${NC}"
    else
        echo -e "${RED}✗ Not accessible${NC}"
    fi
}

echo ""
echo "=== Service Status Check ==="

# Check core services
check_service "sqlserver" "1433"
check_service "airflow-webserver" "8080"
check_service "jupyter" "8888"
check_service "grafana" "3000"
check_service "superset" "8088"
check_service "metabase" "3001"

echo ""
echo "=== Database Connection Test ==="
test_database

echo ""
echo "=== Web Service Accessibility Test ==="
test_web_service "Airflow" "http://localhost:8080"
test_web_service "Jupyter" "http://localhost:8888"
test_web_service "Grafana" "http://localhost:3000"
test_web_service "Superset" "http://localhost:8088"
test_web_service "Metabase" "http://localhost:3001"

echo ""
echo "=== Resource Usage ==="
echo "Docker containers resource usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo ""
echo "=== Data Warehouse Files Check ==="
echo -n "Checking dataset files: "
if [ -f "Dataset/dataset_production.csv" ] && [ -f "Dataset/dataset_alat_berat_dw.csv" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${YELLOW}⚠ Some dataset files missing${NC}"
fi

echo -n "Checking SQL scripts: "
if [ -f "misi3/DW_PTXYZ_Misi3_Script(1).sql" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${RED}✗ SQL script missing${NC}"
fi

echo ""
echo "=== Network Connectivity ==="
echo "Container network status:"
docker network inspect ptxyz-dw_dw_network --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}' 2>/dev/null || echo "Network not found"

echo ""
echo "=== Log Summary ==="
echo "Recent error messages (if any):"
docker compose logs --tail=10 2>&1 | grep -i error | head -5 || echo "No recent errors found"

echo ""
echo "=== Test Complete ==="
echo "For detailed logs of any service, use: docker compose logs [service_name]"
echo "To restart a failing service, use: docker compose restart [service_name]"
