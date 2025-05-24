#!/bin/bash
# PT XYZ Data Warehouse - Status Check Script
# This script checks the status of all services and components
# Author: PT XYZ Data Engineering Team
# Date: 2025-05-24

set -e

# Configuration
PROJECT_NAME="PT XYZ Data Warehouse"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${2}${1}${NC}"
}

# Check service health
check_service() {
    local service_name=$1
    local port=$2
    local expected_response=${3:-""}
    
    if docker ps --filter "name=ptxyz_${service_name}" --format "{{.Names}}" | grep -q "ptxyz_${service_name}"; then
        if [ -n "$port" ]; then
            if curl -s "http://localhost:${port}" > /dev/null 2>&1; then
                print_status "✅ $service_name (port $port)" "$GREEN"
                return 0
            else
                print_status "⚠️ $service_name running but not responding on port $port" "$YELLOW"
                return 1
            fi
        else
            print_status "✅ $service_name" "$GREEN"
            return 0
        fi
    else
        print_status "❌ $service_name not running" "$RED"
        return 1
    fi
}

# Check database connectivity
check_database() {
    print_status "🗄️ Database Status:" "$BLUE"
    
    if docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -C -Q "SELECT 1" > /dev/null 2>&1; then
        print_status "✅ SQL Server database connection" "$GREEN"
        
        # Check if our database exists
        DB_EXISTS=$(docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -C -Q "SELECT COUNT(*) FROM sys.databases WHERE name = 'PTXYZ_DataWarehouse'" -h -1 2>/dev/null | tr -d ' \n\r' || echo "0")
        
        if [ "$DB_EXISTS" = "1" ]; then
            print_status "✅ PTXYZ_DataWarehouse database exists" "$GREEN"
            
            # Get record count
            TOTAL_RECORDS=$(docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -C -Q "USE PTXYZ_DataWarehouse; SELECT COUNT(*) FROM sys.tables" -h -1 2>/dev/null | tr -d ' \n\r' || echo "0")
            print_status "📊 Database contains $TOTAL_RECORDS tables" "$CYAN"
        else
            print_status "⚠️ PTXYZ_DataWarehouse database not found" "$YELLOW"
        fi
    else
        print_status "❌ SQL Server database connection failed" "$RED"
    fi
    echo
}

# Check monitoring status
check_monitoring() {
    print_status "🔍 Monitoring Status:" "$BLUE"
    
    if [ -f "${PROJECT_ROOT}/scripts/monitoring/monitoring.log" ]; then
        # Check if monitoring is active (recent log entries)
        RECENT_LOGS=$(find "${PROJECT_ROOT}/scripts/monitoring/monitoring.log" -mmin -5 2>/dev/null | wc -l)
        if [ "$RECENT_LOGS" -gt 0 ]; then
            print_status "✅ Monitoring system active" "$GREEN"
            
            # Show last monitoring status
            LAST_STATUS=$(tail -1 "${PROJECT_ROOT}/scripts/monitoring/monitoring.log" 2>/dev/null | grep -o "Overall Health: [A-Z]*" || echo "Status unknown")
            print_status "📊 $LAST_STATUS" "$CYAN"
        else
            print_status "⚠️ Monitoring system inactive (no recent logs)" "$YELLOW"
        fi
    else
        print_status "❌ Monitoring system not configured" "$RED"
    fi
    echo
}

# Check disk space and resources
check_resources() {
    print_status "💾 System Resources:" "$BLUE"
    
    # Check disk space
    DISK_USAGE=$(df -h "${PROJECT_ROOT}" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -lt 80 ]; then
        print_status "✅ Disk space: ${DISK_USAGE}% used" "$GREEN"
    elif [ "$DISK_USAGE" -lt 90 ]; then
        print_status "⚠️ Disk space: ${DISK_USAGE}% used (consider cleanup)" "$YELLOW"
    else
        print_status "❌ Disk space: ${DISK_USAGE}% used (critically low)" "$RED"
    fi
    
    # Check Docker disk usage
    DOCKER_DISK=$(docker system df --format "table {{.Type}}\t{{.Size}}" | grep -E "Images|Containers|Volumes" | awk '{sum+=$2} END {print sum}' || echo "0")
    print_status "🐳 Docker disk usage: ${DOCKER_DISK}B" "$CYAN"
    
    # Show container resource usage
    print_status "📊 Container Resources:" "$CYAN"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep ptxyz | head -5
    echo
}

# Main status check function
main() {
    echo -e "${BLUE}"
    echo "=================================================================="
    echo "📊 $PROJECT_NAME - System Status"
    echo "=================================================================="
    echo -e "${NC}"
    
    print_status "🔍 Service Health Check:" "$BLUE"
    
    local total_services=0
    local healthy_services=0
    
    # Core services
    services=(
        "sqlserver:1433"
        "airflow-webserver:8080"
        "airflow-scheduler:"
        "airflow-worker:"
        "grafana:3000"
        "superset:8088"
        "metabase:3001"
        "jupyter:8888"
        "postgres:5432"
        "redis:6379"
    )
    
    for service in "${services[@]}"; do
        service_name="${service%:*}"
        port="${service#*:}"
        ((total_services++))
        
        if [ -z "$port" ]; then
            if check_service "$service_name"; then
                ((healthy_services++))
            fi
        else
            if check_service "$service_name" "$port"; then
                ((healthy_services++))
            fi
        fi
    done
    
    echo
    print_status "📊 Service Summary: $healthy_services/$total_services services healthy" "$CYAN"
    echo
    
    check_database
    check_monitoring
    check_resources
    
    # Overall health status
    if [ "$healthy_services" -eq "$total_services" ]; then
        print_status "🎉 System Status: HEALTHY" "$GREEN"
    elif [ "$healthy_services" -gt $((total_services / 2)) ]; then
        print_status "⚠️ System Status: DEGRADED" "$YELLOW"
    else
        print_status "❌ System Status: CRITICAL" "$RED"
    fi
    
    echo
    print_status "🌐 Quick Access URLs:" "$BLUE"
    echo "  • Airflow:    http://localhost:8080"
    echo "  • Grafana:    http://localhost:3000"
    echo "  • Superset:   http://localhost:8088"
    echo "  • Metabase:   http://localhost:3001"
    echo "  • Jupyter:    http://localhost:8888"
    echo
    print_status "🛠️ Management Commands:" "$CYAN"
    echo "  • View logs:     ./bin/logs.sh [service]"
    echo "  • Restart:       ./bin/stop.sh && ./bin/setup.sh"
    echo "  • Run tests:     ./bin/test.sh"
    echo "  • Monitor:       ./bin/monitor.sh"
}

# Handle arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo "Check PT XYZ Data Warehouse system status"
        echo
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --brief        Show brief status only"
        echo "  --json         Output status in JSON format"
        echo
        exit 0
        ;;
    --brief)
        # Brief status check
        healthy=$(docker ps --filter "name=ptxyz_" --format "{{.Names}}" | wc -l)
        total=10
        if [ "$healthy" -eq "$total" ]; then
            echo "✅ All services healthy ($healthy/$total)"
        else
            echo "⚠️ System status: $healthy/$total services running"
        fi
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
