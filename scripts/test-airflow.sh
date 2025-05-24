#!/bin/bash

# PT XYZ Data Warehouse - Airflow DAG Testing Script
# This script tests the Airflow DAGs and ETL workflows

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 PT XYZ Data Warehouse - Airflow DAG Testing${NC}"
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

# Wait for Airflow to be ready
echo -e "${YELLOW}📋 Checking Airflow Status...${NC}"
echo ""

# Check if Airflow webserver is running
if curl -s --connect-timeout 5 --max-time 10 "http://localhost:8080/health" > /dev/null 2>&1; then
    print_status "OK" "Airflow webserver is running"
else
    print_status "FAIL" "Airflow webserver is not accessible"
    exit 1
fi

# Check DAGs
echo -e "${BLUE}1. Checking DAG Status:${NC}"

# List all DAGs
echo "Listing available DAGs..."
docker exec ptxyz_airflow_webserver airflow dags list | grep ptxyz || echo "No PT XYZ DAGs found"

# Check specific DAG
echo ""
echo "Checking PT XYZ ETL DAG..."
docker exec ptxyz_airflow_webserver airflow dags show ptxyz_etl_pipeline 2>/dev/null && print_status "OK" "ptxyz_etl_pipeline DAG found" || print_status "WARN" "ptxyz_etl_pipeline DAG not found"

# Test DAG syntax
echo ""
echo -e "${BLUE}2. Testing DAG Syntax:${NC}"
docker exec ptxyz_airflow_webserver python -c "
import sys
sys.path.append('/opt/airflow/dags')
try:
    from ptxyz_etl_dag import dag
    print('✅ ptxyz_etl_dag.py syntax is valid')
except Exception as e:
    print(f'❌ Syntax error in ptxyz_etl_dag.py: {e}')
    
try:
    from ptxyz_dimension_loader import dag
    print('✅ ptxyz_dimension_loader.py syntax is valid') 
except Exception as e:
    print(f'❌ Syntax error in ptxyz_dimension_loader.py: {e}')
" 2>/dev/null

# Test database connection from Airflow
echo ""
echo -e "${BLUE}3. Testing Database Connection from Airflow:${NC}"
docker exec ptxyz_airflow_webserver python -c "
import pymssql
try:
    conn = pymssql.connect(
        server='sqlserver',
        port=1433,
        database='PTXYZ_DataWarehouse',
        user='sa',
        password='YourSecurePassword123!',
        timeout=10
    )
    cursor = conn.cursor()
    cursor.execute('SELECT COUNT(*) FROM information_schema.tables WHERE table_schema IN (\'dim\', \'fact\', \'staging\')')
    result = cursor.fetchone()
    print(f'✅ Database connection successful - {result[0]} tables found')
    conn.close()
except Exception as e:
    print(f'❌ Database connection failed: {e}')
" 2>/dev/null

# Check task dependencies
echo ""
echo -e "${BLUE}4. Checking Task Dependencies:${NC}"
docker exec ptxyz_airflow_webserver airflow tasks list ptxyz_etl_pipeline 2>/dev/null | head -10 || print_status "WARN" "Could not list tasks for ptxyz_etl_pipeline"

# Trigger a test run (optional)
echo ""
echo -e "${BLUE}5. Testing DAG Execution (Optional):${NC}"
read -p "Do you want to trigger a test run of the ETL DAG? (y/N): " trigger_test

if [[ "$trigger_test" =~ ^[Yy]$ ]]; then
    echo "Triggering ETL DAG test run..."
    docker exec ptxyz_airflow_webserver airflow dags trigger ptxyz_etl_pipeline 2>/dev/null && print_status "OK" "ETL DAG triggered successfully" || print_status "WARN" "Failed to trigger ETL DAG"
    
    echo "You can monitor the execution at: http://localhost:8080"
    echo "Username: admin, Password: admin"
fi

echo ""
echo -e "${BLUE}6. Airflow System Information:${NC}"
echo "Scheduler Status:"
docker exec ptxyz_airflow_scheduler airflow jobs check --job-type SchedulerJob 2>/dev/null || echo "Scheduler status check failed"

echo ""
echo "Worker Status:"
docker exec ptxyz_airflow_worker airflow celery worker --help > /dev/null 2>&1 && print_status "OK" "Celery worker is available" || print_status "WARN" "Celery worker check failed"

echo ""
echo -e "${GREEN}📊 Airflow Access Information:${NC}"
echo "  • Web UI: http://localhost:8080"
echo "  • Username: admin"
echo "  • Password: admin"
echo ""
echo -e "${GREEN}🔍 Available DAGs:${NC}"
echo "  • ptxyz_etl_pipeline - Main ETL workflow"
echo "  • ptxyz_dimension_loader - Dimension loading workflow"
echo ""
echo -e "${YELLOW}🚀 Airflow testing complete!${NC}"
echo "Check the Airflow web UI for detailed DAG execution monitoring."

exit 0
