#!/bin/bash
# PT XYZ Data Warehouse - Status Check Script
# Author: Data Engineering Team
# Date: 2025-05-24
# Description: Check status of all PT XYZ Data Warehouse services

set -euo pipefail

# Global variables
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly LOG_FILE="$PROJECT_ROOT/logs/status.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

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

# Check Docker service status
check_docker_services() {
    info "🐳 Docker Services Status"
    info "========================="
    
    local services=(
        "ptxyz_postgres"
        "ptxyz_sqlserver"
        "ptxyz_redis"
        "ptxyz_airflow_webserver"
        "ptxyz_airflow_scheduler"
        "ptxyz_airflow_worker"
        "ptxyz_grafana"
        "ptxyz_superset"
        "ptxyz_metabase"
        "ptxyz_jupyter"
    )
    
    local running=0
    local total=${#services[@]}
    
    echo ""
    for service in "${services[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^${service}$"; then
            local status=$(docker ps --format "{{.Status}}" --filter "name=${service}")
            success "✅ $service: $status"
            ((running++))
        else
            error "❌ $service: Not running"
        fi
    done
    
    echo ""
    info "Summary: $running/$total services running"
    
    if [[ $running -eq $total ]]; then
        success "🎯 All services are running!"
        return 0
    else
        warn "⚠️ Some services are not running"
        return 1
    fi
}

# Check web service accessibility
check_web_services() {
    info "🌐 Web Services Accessibility"
    info "============================="
    
    local web_services=(
        "Airflow:http://localhost:8080/health"
        "Grafana:http://localhost:3000/api/health"
        "Superset:http://localhost:8088/health"
        "Metabase:http://localhost:3001/api/health"
        "Jupyter:http://localhost:8888/api"
    )
    
    echo ""
    for service_info in "${web_services[@]}"; do
        local name="${service_info%:*}"
        local url="${service_info#*:}"
        
        if curl -s -f "$url" >/dev/null 2>&1; then
            success "✅ $name is accessible"
        else
            error "❌ $name is not accessible ($url)"
        fi
    done
}

# Check database connectivity
check_database() {
    info "🗄️ Database Connectivity"
    info "========================"
    
    echo ""
    
    # Check SQL Server
    if docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -C -Q "SELECT 1 as test" >/dev/null 2>&1; then
        success "✅ SQL Server is accessible"
        
        # Get database info
        local db_info=$(docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -C -Q "
        USE PTXYZ_DataWarehouse;
        SELECT 
            'Records: ' + CAST(COUNT(*) as VARCHAR) as Info
        FROM (
            SELECT 1 as id FROM fact.FactProduction
            UNION ALL
            SELECT 1 FROM fact.FactEquipmentUsage
            UNION ALL
            SELECT 1 FROM fact.FactFinancialTransaction
        ) combined;
        " 2>/dev/null | grep "Records:" | head -1)
        
        if [[ -n "$db_info" ]]; then
            info "📊 Database: $db_info"
        fi
    else
        error "❌ SQL Server is not accessible"
    fi
    
    # Check PostgreSQL (Airflow)
    if docker exec ptxyz_postgres psql -U airflow -d airflow -c "SELECT 1;" >/dev/null 2>&1; then
        success "✅ PostgreSQL (Airflow) is accessible"
    else
        error "❌ PostgreSQL (Airflow) is not accessible"
    fi
}

# Check system resources
check_system_resources() {
    info "💻 System Resources"
    info "=================="
    
    echo ""
    
    # Memory usage
    local memory_info=$(free -h | grep "Mem:")
    local memory_used=$(echo $memory_info | awk '{print $3}')
    local memory_total=$(echo $memory_info | awk '{print $2}')
    info "🧠 Memory: $memory_used / $memory_total"
    
    # Disk usage
    local disk_usage=$(df -h . | tail -1 | awk '{print $5}')
    local disk_available=$(df -h . | tail -1 | awk '{print $4}')
    info "💾 Disk: $disk_usage used, $disk_available available"
    
    # Docker resource usage
    if command -v docker &> /dev/null; then
        echo ""
        info "🐳 Docker Container Resources:"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | grep ptxyz | head -10
    fi
}

# Check monitoring status
check_monitoring() {
    info "📊 Monitoring Status"
    info "==================="
    
    echo ""
    
    # Check monitoring processes
    if [[ -f "$PROJECT_ROOT/scripts/monitoring/monitoring.log" ]]; then
        success "✅ Monitoring system is active"
        
        # Show last monitoring update
        local last_update=$(tail -1 "$PROJECT_ROOT/scripts/monitoring/monitoring.log" 2>/dev/null | head -1)
        if [[ -n "$last_update" ]]; then
            info "📋 Last update: $last_update"
        fi
        
        # Check monitoring health
        if tail -5 "$PROJECT_ROOT/scripts/monitoring/monitoring.log" 2>/dev/null | grep -q "ERROR"; then
            warn "⚠️ Recent monitoring errors detected"
        else
            success "✅ Monitoring system healthy"
        fi
    else
        warn "⚠️ Monitoring system not active"
    fi
    
    # Check for PID files
    local pid_count=0
    for pidfile in "$PROJECT_ROOT"/scripts/monitoring/*.pid; do
        if [[ -f "$pidfile" ]]; then
            local pid=$(cat "$pidfile")
            if kill -0 "$pid" 2>/dev/null; then
                ((pid_count++))
            fi
        fi
    done
    
    if [[ $pid_count -gt 0 ]]; then
        info "🔄 Active monitoring processes: $pid_count"
    fi
}

# Show access information
show_access_info() {
    info "🌐 Service Access URLs"
    info "====================="
    
    echo ""
    echo "📊 Web Interfaces:"
    echo "  • Airflow:      http://localhost:8080 (admin/admin)"
    echo "  • Grafana:      http://localhost:3000 (admin/admin)"
    echo "  • Superset:     http://localhost:8088 (admin/admin)"
    echo "  • Metabase:     http://localhost:3001"
    echo "  • Jupyter:      http://localhost:8888"
    echo ""
    echo "🗄️ Database:"
    echo "  • SQL Server:   localhost:1433"
    echo "  • Database:     PTXYZ_DataWarehouse"
    echo "  • Username:     sa"
    echo "  • Password:     YourSecurePassword123!"
    echo ""
    echo "📋 Management Commands:"
    echo "  • Start:        ./bin/setup.sh"
    echo "  • Stop:         ./bin/stop.sh"
    echo "  • Test:         ./bin/test.sh"
    echo "  • Logs:         docker-compose logs [service]"
    echo ""
}

# Generate health score
calculate_health_score() {
    local total_checks=0
    local passed_checks=0
    
    # Docker services check
    ((total_checks++))
    if check_docker_services >/dev/null 2>&1; then
        ((passed_checks++))
    fi
    
    # Database check
    ((total_checks++))
    if docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -C -Q "SELECT 1" >/dev/null 2>&1; then
        ((passed_checks++))
    fi
    
    # Web services check
    ((total_checks++))
    if curl -s -f "http://localhost:8080/health" >/dev/null 2>&1; then
        ((passed_checks++))
    fi
    
    local health_score=$((passed_checks * 100 / total_checks))
    
    echo ""
    if [[ $health_score -eq 100 ]]; then
        success "🎯 System Health: $health_score% - Excellent"
    elif [[ $health_score -ge 80 ]]; then
        warn "⚠️ System Health: $health_score% - Good"
    elif [[ $health_score -ge 60 ]]; then
        warn "⚠️ System Health: $health_score% - Fair"
    else
        error "❌ System Health: $health_score% - Poor"
    fi
    
    return $health_score
}

# Main status check function
main() {
    local start_time=$(date +%s)
    
    info "🔍 PT XYZ Data Warehouse Status Check"
    info "===================================="
    echo ""
    
    # Perform all checks
    check_docker_services
    echo ""
    check_web_services
    echo ""
    check_database
    echo ""
    check_system_resources
    echo ""
    check_monitoring
    echo ""
    
    # Calculate overall health
    calculate_health_score
    
    # Show access info if requested
    if [[ "${SHOW_ACCESS:-false}" == "true" ]]; then
        echo ""
        show_access_info
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    info "📋 Status check completed in ${duration} seconds"
    
    # Return appropriate exit code
    if calculate_health_score >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Show help
show_help() {
    echo "PT XYZ Data Warehouse Status Check Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -a, --access        Show access information"
    echo "  -w, --watch         Continuous monitoring (refresh every 10s)"
    echo "  -q, --quiet         Show only summary"
    echo ""
    echo "Examples:"
    echo "  $0                  # Standard status check"
    echo "  $0 --access         # Include access URLs"
    echo "  $0 --watch          # Continuous monitoring"
}

# Parse command line arguments
SHOW_ACCESS=false
WATCH_MODE=false
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -a|--access)
            SHOW_ACCESS=true
            shift
            ;;
        -w|--watch)
            WATCH_MODE=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Execute based on mode
if [[ "$WATCH_MODE" == "true" ]]; then
    info "Starting continuous monitoring (Ctrl+C to stop)..."
    while true; do
        clear
        main
        sleep 10
    done
else
    main
fi
