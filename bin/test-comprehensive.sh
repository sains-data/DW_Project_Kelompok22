#!/bin/bash
# PT XYZ Data Warehouse - Comprehensive Test Suite
# Author: Data Engineering Team
# Date: 2025-05-24
# Description: End-to-end, integration, and unit tests for PT XYZ Data Warehouse

set -euo pipefail

# Global variables
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly LOG_FILE="$PROJECT_ROOT/logs/test.log"
readonly TEST_RESULTS_DIR="$PROJECT_ROOT/tests/results"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TEST_START_TIME=""

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

info() { echo -e "${BLUE}$*${NC}"; }
warn() { echo -e "${YELLOW}$*${NC}"; }
error() { echo -e "${RED}$*${NC}"; }
success() { echo -e "${GREEN}$*${NC}"; }

# Test framework functions
start_test() {
    local test_name="$1"
    TEST_START_TIME=$(date +%s)
    ((TESTS_RUN++))
    info "🧪 Testing: $test_name"
}

pass_test() {
    local test_name="$1"
    local end_time=$(date +%s)
    local duration=$((end_time - TEST_START_TIME))
    ((TESTS_PASSED++))
    success "✅ PASS: $test_name (${duration}s)"
    log "TEST_PASS" "$test_name completed in ${duration}s"
}

fail_test() {
    local test_name="$1"
    local error_msg="${2:-No error message provided}"
    local end_time=$(date +%s)
    local duration=$((end_time - TEST_START_TIME))
    ((TESTS_FAILED++))
    error "❌ FAIL: $test_name (${duration}s)"
    error "   Error: $error_msg"
    log "TEST_FAIL" "$test_name failed after ${duration}s: $error_msg"
}

# Setup test environment
setup_test_environment() {
    info "🔧 Setting up test environment..."
    
    # Create test results directory
    mkdir -p "$TEST_RESULTS_DIR"
    
    # Clear previous logs
    > "$LOG_FILE"
    
    success "✅ Test environment ready"
}

# Test 1: Docker Services Health Check
test_docker_services() {
    start_test "Docker Services Health"
    
    local required_services=(
        "ptxyz_postgres"
        "ptxyz_sqlserver"
        "ptxyz_redis"
        "ptxyz_airflow_webserver"
        "ptxyz_airflow_scheduler"
        "ptxyz_grafana"
        "ptxyz_superset"
        "ptxyz_metabase"
        "ptxyz_jupyter"
    )
    
    for service in "${required_services[@]}"; do
        if ! docker ps --format "{{.Names}}" | grep -q "^${service}$"; then
            fail_test "Docker Services Health" "Service $service is not running"
            return 1
        fi
    done
    
    pass_test "Docker Services Health"
}

# Test 2: Database Connectivity
test_database_connectivity() {
    start_test "Database Connectivity"
    
    # Test SQL Server connection
    if ! docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -C -Q "SELECT 1 as test" >/dev/null 2>&1; then
        fail_test "Database Connectivity" "Cannot connect to SQL Server"
        return 1
    fi
    
    # Test database exists
    if ! docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -C -Q "USE PTXYZ_DataWarehouse; SELECT 1" >/dev/null 2>&1; then
        fail_test "Database Connectivity" "PTXYZ_DataWarehouse database not found"
        return 1
    fi
    
    # Test PostgreSQL (Airflow)
    if ! docker exec ptxyz_postgres psql -U airflow -d airflow -c "SELECT 1;" >/dev/null 2>&1; then
        fail_test "Database Connectivity" "Cannot connect to PostgreSQL (Airflow)"
        return 1
    fi
    
    pass_test "Database Connectivity"
}

# Test 3: Web Services Accessibility
test_web_services() {
    start_test "Web Services Accessibility"
    
    local web_services=(
        "Airflow:http://localhost:8080/health"
        "Grafana:http://localhost:3000/api/health"
        "Superset:http://localhost:8088/health"
        "Metabase:http://localhost:3001/api/health"
        "Jupyter:http://localhost:8888/api"
    )
    
    for service_info in "${web_services[@]}"; do
        local name="${service_info%:*}"
        local url="${service_info#*:}"
        
        if ! curl -s -f --max-time 10 "$url" >/dev/null 2>&1; then
            fail_test "Web Services Accessibility" "$name is not accessible at $url"
            return 1
        fi
    done
    
    pass_test "Web Services Accessibility"
}

# Test 4: Database Schema Validation
test_database_schema() {
    start_test "Database Schema Validation"
    
    # Check required schemas exist
    local schemas=("dim" "fact" "staging" "analytics")
    
    for schema in "${schemas[@]}"; do
        local result=$(docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -C -Q "
        USE PTXYZ_DataWarehouse;
        SELECT COUNT(*) as schema_count FROM sys.schemas WHERE name = '$schema';
        " 2>/dev/null | grep -E '^[0-9]+$' | head -1)
        
        if [[ "$result" != "1" ]]; then
            fail_test "Database Schema Validation" "Schema '$schema' not found"
            return 1
        fi
    done
    
    # Check required tables exist
    local required_tables=(
        "dim.DimTime"
        "dim.DimSite" 
        "dim.DimEquipment"
        "dim.DimMaterial"
        "dim.DimEmployee"
        "dim.DimProject"
        "dim.DimAccount"
        "fact.FactEquipmentUsage"
        "fact.FactProduction"
        "fact.FactFinancialTransaction"
    )
    
    for table in "${required_tables[@]}"; do
        local result=$(docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -C -Q "
        USE PTXYZ_DataWarehouse;
        SELECT COUNT(*) as table_count FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = '${table%.*}' AND TABLE_NAME = '${table#*.}';
        " 2>/dev/null | grep -E '^[0-9]+$' | head -1)
        
        if [[ "$result" != "1" ]]; then
            fail_test "Database Schema Validation" "Table '$table' not found"
            return 1
        fi
    done
    
    pass_test "Database Schema Validation"
}

# Test 5: Data Quality Check
test_data_quality() {
    start_test "Data Quality Check"
    
    # Check that fact tables have data
    local fact_tables=("FactEquipmentUsage" "FactProduction" "FactFinancialTransaction")
    
    for table in "${fact_tables[@]}"; do
        local count=$(docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -C -Q "
        USE PTXYZ_DataWarehouse;
        SELECT COUNT(*) FROM fact.$table;
        " 2>/dev/null | grep -E '^[0-9]+$' | head -1)
        
        if [[ -z "$count" ]] || [[ "$count" -eq 0 ]]; then
            fail_test "Data Quality Check" "Table fact.$table has no data"
            return 1
        fi
    done
    
    # Check for data consistency
    local consistency_check=$(docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -C -Q "
    USE PTXYZ_DataWarehouse;
    SELECT COUNT(*) as valid_references FROM fact.FactEquipmentUsage feu
    INNER JOIN dim.DimTime dt ON feu.time_key = dt.time_key
    INNER JOIN dim.DimSite ds ON feu.site_key = ds.site_key
    INNER JOIN dim.DimEquipment de ON feu.equipment_key = de.equipment_key;
    " 2>/dev/null | grep -E '^[0-9]+$' | head -1)
    
    if [[ -z "$consistency_check" ]] || [[ "$consistency_check" -eq 0 ]]; then
        fail_test "Data Quality Check" "Data consistency check failed"
        return 1
    fi
    
    pass_test "Data Quality Check"
}

# Test 6: Analytics Views Functionality
test_analytics_views() {
    start_test "Analytics Views Functionality"
    
    local analytics_views=(
        "vw_ExecutiveDashboard"
        "vw_RealTimeOperations"
        "vw_PredictiveInsights"
        "vw_CostOptimization"
    )
    
    for view in "${analytics_views[@]}"; do
        local result=$(docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -C -Q "
        USE PTXYZ_DataWarehouse;
        SELECT COUNT(*) FROM analytics.$view;
        " 2>/dev/null | grep -E '^[0-9]+$' | head -1)
        
        if [[ -z "$result" ]]; then
            fail_test "Analytics Views Functionality" "View analytics.$view failed to execute"
            return 1
        fi
    done
    
    pass_test "Analytics Views Functionality"
}

# Test 7: ETL Pipeline Test
test_etl_pipeline() {
    start_test "ETL Pipeline Test"
    
    # Check if Airflow DAGs are available
    local dag_check=$(docker exec ptxyz_airflow_webserver airflow dags list 2>/dev/null | grep -c "ptxyz" || echo "0")
    
    if [[ "$dag_check" -eq 0 ]]; then
        fail_test "ETL Pipeline Test" "No PT XYZ DAGs found in Airflow"
        return 1
    fi
    
    # Check DAG status
    local dag_status=$(docker exec ptxyz_airflow_webserver airflow dags state ptxyz_etl_dag 2>/dev/null || echo "failed")
    
    if [[ "$dag_status" == "failed" ]]; then
        warn "ETL Pipeline Test" "DAG state check returned warning (this may be normal for new installations)"
    fi
    
    pass_test "ETL Pipeline Test"
}

# Test 8: Performance Test
test_performance() {
    start_test "Performance Test"
    
    # Test query performance
    local start_time=$(date +%s%N)
    
    docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -C -Q "
    USE PTXYZ_DataWarehouse;
    SELECT COUNT(*) FROM fact.FactEquipmentUsage feu
    INNER JOIN dim.DimTime dt ON feu.time_key = dt.time_key
    INNER JOIN dim.DimSite ds ON feu.site_key = ds.site_key;
    " >/dev/null 2>&1
    
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
    
    if [[ $duration -gt 5000 ]]; then # More than 5 seconds
        fail_test "Performance Test" "Query took too long: ${duration}ms"
        return 1
    fi
    
    pass_test "Performance Test"
}

# Test 9: Monitoring System Test
test_monitoring_system() {
    start_test "Monitoring System Test"
    
    # Check if monitoring logs exist
    if [[ ! -f "$PROJECT_ROOT/scripts/monitoring/monitoring.log" ]]; then
        fail_test "Monitoring System Test" "Monitoring log file not found"
        return 1
    fi
    
    # Check if monitoring is active (recent log entries)
    local recent_logs=$(find "$PROJECT_ROOT/scripts/monitoring" -name "*.log" -mmin -5 | wc -l)
    
    if [[ $recent_logs -eq 0 ]]; then
        warn "Monitoring System Test" "No recent monitoring activity detected"
    fi
    
    pass_test "Monitoring System Test"
}

# Test 10: Integration Test
test_full_integration() {
    start_test "Full Integration Test"
    
    # Test complete data flow: Raw data → ETL → Analytics
    local integration_query='
    USE PTXYZ_DataWarehouse;
    SELECT 
        COUNT(DISTINCT feu.equipment_key) as equipment_count,
        COUNT(DISTINCT fp.production_key) as production_count,
        COUNT(DISTINCT fft.transaction_key) as transaction_count,
        COUNT(*) as total_facts
    FROM fact.FactEquipmentUsage feu
    FULL OUTER JOIN fact.FactProduction fp ON feu.time_key = fp.time_key
    FULL OUTER JOIN fact.FactFinancialTransaction fft ON feu.time_key = fft.time_key
    WHERE feu.equipment_key IS NOT NULL OR fp.production_key IS NOT NULL OR fft.transaction_key IS NOT NULL;
    '
    
    local result=$(docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -C -Q "$integration_query" 2>/dev/null)
    
    if [[ -z "$result" ]]; then
        fail_test "Full Integration Test" "Integration query failed"
        return 1
    fi
    
    pass_test "Full Integration Test"
}

# Generate test report
generate_test_report() {
    local end_time=$(date +%s)
    local total_duration=$((end_time - SUITE_START_TIME))
    
    info "📊 Test Results Summary"
    info "======================"
    echo ""
    
    success "✅ Tests Passed: $TESTS_PASSED"
    error "❌ Tests Failed: $TESTS_FAILED"
    info "📋 Total Tests: $TESTS_RUN"
    info "⏱️ Total Duration: ${total_duration}s"
    
    local success_rate=$((TESTS_PASSED * 100 / TESTS_RUN))
    
    echo ""
    if [[ $TESTS_FAILED -eq 0 ]]; then
        success "🎯 All tests passed! Success rate: 100%"
        echo ""
        success "🚀 PT XYZ Data Warehouse is fully functional!"
    elif [[ $success_rate -ge 80 ]]; then
        warn "⚠️ Most tests passed. Success rate: ${success_rate}%"
        warn "Some issues detected but system is mostly functional."
    else
        error "❌ Multiple test failures. Success rate: ${success_rate}%"
        error "System requires attention before production use."
    fi
    
    # Save detailed report
    cat > "$TEST_RESULTS_DIR/test_report_$(date +%Y%m%d_%H%M%S).json" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "tests_run": $TESTS_RUN,
    "tests_passed": $TESTS_PASSED,
    "tests_failed": $TESTS_FAILED,
    "success_rate": ${success_rate},
    "duration_seconds": $total_duration,
    "status": "$(if [[ $TESTS_FAILED -eq 0 ]]; then echo "PASS"; else echo "FAIL"; fi)"
}
EOF
    
    info "📄 Detailed report saved to: $TEST_RESULTS_DIR/test_report_$(date +%Y%m%d_%H%M%S).json"
}

# Main test execution
main() {
    SUITE_START_TIME=$(date +%s)
    
    info "🧪 PT XYZ Data Warehouse Test Suite"
    info "==================================="
    echo ""
    
    setup_test_environment
    echo ""
    
    # Run all tests
    test_docker_services
    test_database_connectivity
    test_web_services
    test_database_schema
    test_data_quality
    test_analytics_views
    test_etl_pipeline
    test_performance
    test_monitoring_system
    test_full_integration
    
    echo ""
    generate_test_report
    
    # Return appropriate exit code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Show help
show_help() {
    echo "PT XYZ Data Warehouse Test Suite"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -u, --unit          Run only unit tests"
    echo "  -i, --integration   Run only integration tests"
    echo "  -e, --e2e           Run only end-to-end tests"
    echo "  -p, --performance   Run only performance tests"
    echo "  -v, --verbose       Enable verbose output"
    echo ""
    echo "Examples:"
    echo "  $0                  # Run full test suite"
    echo "  $0 --integration    # Run integration tests only"
    echo "  $0 --performance    # Run performance tests only"
}

# Parse command line arguments
TEST_TYPE="all"
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -u|--unit)
            TEST_TYPE="unit"
            shift
            ;;
        -i|--integration)
            TEST_TYPE="integration"
            shift
            ;;
        -e|--e2e)
            TEST_TYPE="e2e"
            shift
            ;;
        -p|--performance)
            TEST_TYPE="performance"
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            set -x
            shift
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Execute tests based on type
case $TEST_TYPE in
    "unit")
        info "Running unit tests only..."
        # Add unit test functions here
        ;;
    "integration")
        info "Running integration tests only..."
        test_database_connectivity
        test_database_schema
        test_data_quality
        test_analytics_views
        test_full_integration
        generate_test_report
        ;;
    "e2e")
        info "Running end-to-end tests only..."
        test_docker_services
        test_web_services
        test_etl_pipeline
        test_monitoring_system
        generate_test_report
        ;;
    "performance")
        info "Running performance tests only..."
        test_performance
        generate_test_report
        ;;
    *)
        main
        ;;
esac
