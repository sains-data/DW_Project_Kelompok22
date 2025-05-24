#!/bin/bash
# PT XYZ Data Warehouse - Stop Script
# This script stops all data warehouse services gracefully
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

# Print header
print_header() {
    echo -e "${BLUE}"
    echo "=================================================================="
    echo "🛑 $PROJECT_NAME - Shutdown"
    echo "=================================================================="
    echo -e "${NC}"
}

# Stop monitoring services
stop_monitoring() {
    print_status "🔍 Stopping monitoring services..." "$YELLOW"
    
    # Stop monitoring processes
    if [ -f "${PROJECT_ROOT}/scripts/monitoring/monitoring.pid" ]; then
        PID=$(cat "${PROJECT_ROOT}/scripts/monitoring/monitoring.pid")
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID"
            print_status "✅ Monitoring process stopped (PID: $PID)" "$GREEN"
        fi
        rm -f "${PROJECT_ROOT}/scripts/monitoring/monitoring.pid"
    fi
    
    # Stop any background monitoring processes
    pkill -f "monitor_dashboard.py" 2>/dev/null || true
    pkill -f "health_monitor.py" 2>/dev/null || true
    
    print_status "✅ Monitoring services stopped" "$GREEN"
}

# Stop Docker services
stop_docker_services() {
    print_status "🐳 Stopping Docker services..." "$YELLOW"
    
    cd "$PROJECT_ROOT"
    
    # Stop all services gracefully
    print_status "📊 Stopping visualization services..." "$CYAN"
    docker compose stop metabase superset grafana 2>/dev/null || true
    
    print_status "🔧 Stopping data processing services..." "$CYAN"
    docker compose stop airflow-worker airflow-scheduler airflow-webserver jupyter 2>/dev/null || true
    
    print_status "🗄️ Stopping database services..." "$CYAN"
    docker compose stop sqlserver postgres redis 2>/dev/null || true
    
    # Remove containers if requested
    if [[ "${1}" == "--remove" || "${1}" == "-r" ]]; then
        print_status "🗑️ Removing containers..." "$CYAN"
        docker compose down --remove-orphans
        print_status "✅ Containers removed" "$GREEN"
    else
        print_status "⏸️ Containers stopped (use --remove to delete them)" "$YELLOW"
    fi
}

# Clean up temporary files
cleanup_temp_files() {
    print_status "🧹 Cleaning up temporary files..." "$YELLOW"
    
    # Clean up log files if requested
    if [[ "${1}" == "--clean-logs" ]]; then
        find "${PROJECT_ROOT}/logs" -name "*.log" -type f -delete 2>/dev/null || true
        print_status "✅ Log files cleaned" "$GREEN"
    fi
    
    # Clean up temporary monitoring files
    rm -f /tmp/monitoring/*.json 2>/dev/null || true
    
    print_status "✅ Cleanup complete" "$GREEN"
}

# Show system status after shutdown
show_status() {
    print_status "📊 System Status After Shutdown:" "$BLUE"
    
    # Check if any containers are still running
    RUNNING_CONTAINERS=$(docker ps --filter "name=ptxyz_" --format "{{.Names}}" | wc -l)
    
    if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
        print_status "✅ All PT XYZ containers stopped" "$GREEN"
    else
        print_status "⚠️ $RUNNING_CONTAINERS container(s) still running:" "$YELLOW"
        docker ps --filter "name=ptxyz_" --format "table {{.Names}}\t{{.Status}}"
    fi
    
    # Show disk space freed (if containers were removed)
    if [[ "${1}" == "--remove" || "${1}" == "-r" ]]; then
        print_status "💾 Run 'docker system prune' to free up additional disk space" "$CYAN"
    fi
}

# Main stop function
main() {
    print_header
    
    local remove_containers=false
    local clean_logs=false
    
    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --remove|-r)
                remove_containers=true
                ;;
            --clean-logs)
                clean_logs=true
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo "Stop PT XYZ Data Warehouse services"
                echo
                echo "Options:"
                echo "  --help, -h       Show this help message"
                echo "  --remove, -r     Remove containers after stopping"
                echo "  --clean-logs     Clean log files"
                echo "  --force          Force stop all services immediately"
                echo
                exit 0
                ;;
            --force)
                print_status "⚠️ Force stopping all services..." "$YELLOW"
                docker compose kill 2>/dev/null || true
                docker compose down --remove-orphans 2>/dev/null || true
                exit 0
                ;;
        esac
    done
    
    stop_monitoring
    
    if $remove_containers; then
        stop_docker_services "--remove"
    else
        stop_docker_services
    fi
    
    if $clean_logs; then
        cleanup_temp_files "--clean-logs"
    else
        cleanup_temp_files
    fi
    
    show_status "$@"
    
    print_status "🎯 Shutdown completed successfully!" "$GREEN"
    echo
    print_status "💡 To restart the system, run: ./bin/setup.sh" "$CYAN"
}

# Execute main function
main "$@"
