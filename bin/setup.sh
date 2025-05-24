#!/bin/bash
# PT XYZ Data Warehouse - Main Setup Script
# This script sets up the entire data warehouse infrastructure using Docker
# Author: PT XYZ Data Engineering Team
# Date: 2025-05-24

set -e

# Configuration
PROJECT_NAME="PT XYZ Data Warehouse"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="${PROJECT_ROOT}/logs/setup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Ensure logs directory exists
mkdir -p "${PROJECT_ROOT}/logs"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Print colored output
print_status() {
    echo -e "${2}${1}${NC}"
    log "$1"
}

# Print header
print_header() {
    echo -e "${BLUE}"
    echo "=================================================================="
    echo "🚀 $PROJECT_NAME - Complete Setup"
    echo "=================================================================="
    echo -e "${NC}"
    log "Starting setup process"
}

# Check prerequisites
check_prerequisites() {
    print_status "📋 Checking Prerequisites..." "$YELLOW"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_status "❌ Docker is not installed. Please install Docker first." "$RED"
        exit 1
    fi
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        print_status "❌ Docker Compose is not available. Please install Docker Compose." "$RED"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker ps &> /dev/null; then
        print_status "❌ Docker daemon is not running. Please start Docker." "$RED"
        exit 1
    fi
    
    print_status "✅ All prerequisites met" "$GREEN"
}

# Setup environment
setup_environment() {
    print_status "🔧 Setting up environment..." "$YELLOW"
    
    cd "$PROJECT_ROOT"
    
    # Create required directories
    mkdir -p {logs,data/{raw,processed,staging,warehouse,backups},config/environments}
    
    # Set up environment file
    if [ ! -f .env ]; then
        if [ -f .env.template ]; then
            cp .env.template .env
            print_status "✅ Environment file created from template" "$GREEN"
        else
            cat > .env << EOF
# PT XYZ Data Warehouse Environment Configuration
COMPOSE_PROJECT_NAME=ptxyz
MSSQL_SA_PASSWORD=YourSecurePassword123!
AIRFLOW_UID=50000
AIRFLOW_GID=0
POSTGRES_USER=airflow
POSTGRES_PASSWORD=airflow
POSTGRES_DB=airflow
REDIS_PASSWORD=redispass
GRAFANA_ADMIN_PASSWORD=admin
SUPERSET_SECRET_KEY=superset_secret_key_123
JUPYTER_TOKEN=ptxyz123
EOF
            print_status "✅ Default environment file created" "$GREEN"
        fi
    fi
    
    # Set proper permissions for Airflow
    print_status "🔒 Setting up permissions..." "$CYAN"
    sudo chown -R 50000:0 logs/ 2>/dev/null || true
    chmod -R 755 logs/ 2>/dev/null || true
    
    print_status "✅ Environment setup complete" "$GREEN"
}
echo "Setting up Airflow permissions..."
sudo chown -R 50000:0 logs plugins

# Build and start the services
echo "Starting PT XYZ Data Warehouse services..."
docker compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Check service status
echo "Checking service status..."
docker compose ps

echo ""
echo "=== PT XYZ Data Warehouse Setup Complete ==="
echo ""
echo "Services Available:"
echo "- SQL Server Data Warehouse: localhost:1433"
echo "  - Username: sa"
echo "  - Password: PTXYZDataWarehouse2025!"
echo "  - Database: DW_PTXYZ"
echo ""
echo "- Airflow Web UI: http://localhost:8080"
echo "  - Username: admin"
echo "  - Password: admin"
echo ""
echo "- Jupyter Notebooks: http://localhost:8888"
echo "  - No password required"
echo ""
echo "- Grafana Dashboard: http://localhost:3000"
echo "  - Username: admin"
echo "  - Password: admin"
echo ""
echo "- Apache Superset: http://localhost:8088"
echo "  - Username: admin"
echo "  - Password: admin"
echo ""
echo "- Metabase: http://localhost:3001"
echo "  - Setup required on first access"
echo ""
echo "To stop all services: docker compose down"
echo "To view logs: docker compose logs [service_name]"

# Setup Docker infrastructure
setup_docker() {
    print_status "🐳 Setting up Docker infrastructure..." "$YELLOW"
    
    cd "$PROJECT_ROOT"
    
    # Ensure we have docker-compose.yml in the right location
    if [ -f config/docker/docker-compose.yml ]; then
        cp config/docker/docker-compose.yml ./
    fi
    
    # Pull required images
    print_status "📥 Pulling Docker images..." "$CYAN"
    docker compose pull
    
    # Build custom images if needed
    print_status "🔨 Building custom images..." "$CYAN"
    docker compose build --no-cache
    
    print_status "✅ Docker infrastructure ready" "$GREEN"
}

# Start services
start_services() {
    print_status "🚀 Starting services..." "$YELLOW"
    
    # Start core services first
    print_status "🔧 Starting core services (Database, Redis)..." "$CYAN"
    docker compose up -d sqlserver redis postgres
    
    # Wait for database to be ready
    print_status "⏳ Waiting for database to be ready..." "$CYAN"
    sleep 30
    
    # Start data services
    print_status "📊 Starting data services (Airflow, Jupyter)..." "$CYAN"
    docker compose up -d airflow-init
    sleep 10
    docker compose up -d airflow-webserver airflow-scheduler airflow-worker jupyter
    
    # Start visualization services
    print_status "📈 Starting visualization services (Grafana, Superset, Metabase)..." "$CYAN"
    docker compose up -d grafana superset metabase
    
    print_status "✅ All services started" "$GREEN"
}

# Initialize database
initialize_database() {
    print_status "🗄️ Initializing database..." "$YELLOW"
    
    # Wait for SQL Server to be ready
    print_status "⏳ Waiting for SQL Server to be fully ready..." "$CYAN"
    sleep 60
    
    # Run database initialization
    if [ -f scripts/setup/init-database.sh ]; then
        bash scripts/setup/init-database.sh
    else
        # Create basic database structure
        docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -C -Q "
        IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'PTXYZ_DataWarehouse')
        BEGIN
            CREATE DATABASE PTXYZ_DataWarehouse;
            PRINT 'Database PTXYZ_DataWarehouse created successfully';
        END
        ELSE
        BEGIN
            PRINT 'Database PTXYZ_DataWarehouse already exists';
        END
        "
    fi
    
    print_status "✅ Database initialized" "$GREEN"
}

# Setup monitoring
setup_monitoring() {
    print_status "🔍 Setting up monitoring..." "$YELLOW"
    
    if [ -f scripts/monitoring/setup-monitoring.sh ]; then
        bash scripts/monitoring/setup-monitoring.sh
    fi
    
    print_status "✅ Monitoring setup complete" "$GREEN"
}

# Verify installation
verify_installation() {
    print_status "🧪 Verifying installation..." "$YELLOW"
    
    # Check service health
    sleep 30
    
    local failed_services=0
    
    # Check each service
    services=("sqlserver:1433" "airflow-webserver:8080" "grafana:3000" "superset:8088" "metabase:3001" "jupyter:8888")
    
    for service in "${services[@]}"; do
        service_name="${service%:*}"
        port="${service#*:}"
        
        if docker ps | grep -q "ptxyz_${service_name}"; then
            print_status "✅ $service_name is running" "$GREEN"
        else
            print_status "❌ $service_name is not running" "$RED"
            ((failed_services++))
        fi
    done
    
    if [ $failed_services -eq 0 ]; then
        print_status "✅ All services are running successfully" "$GREEN"
        return 0
    else
        print_status "⚠️ $failed_services service(s) failed to start" "$YELLOW"
        return 1
    fi
}

# Display access information
show_access_info() {
    print_status "🌐 Access Information" "$BLUE"
    echo
    echo -e "${CYAN}📊 Web Services:${NC}"
    echo "  • Airflow:          http://localhost:8080 (admin/admin)"
    echo "  • Grafana:          http://localhost:3000 (admin/admin)"
    echo "  • Apache Superset:  http://localhost:8088 (admin/admin)"
    echo "  • Metabase:         http://localhost:3001"
    echo "  • Jupyter Labs:     http://localhost:8888 (token: ptxyz123)"
    echo
    echo -e "${CYAN}🗄️ Database:${NC}"
    echo "  • SQL Server:       localhost:1433"
    echo "  • Database:         PTXYZ_DataWarehouse"
    echo "  • Username:         sa"
    echo "  • Password:         YourSecurePassword123!"
    echo
    echo -e "${CYAN}🛠️ Management Commands:${NC}"
    echo "  • Stop services:    ./bin/stop.sh"
    echo "  • Check status:     ./bin/status.sh"
    echo "  • View logs:        ./bin/logs.sh"
    echo "  • Run tests:        ./bin/test.sh"
    echo
}

# Main setup function
main() {
    print_header
    
    check_prerequisites
    setup_environment
    setup_docker
    start_services
    initialize_database
    setup_monitoring
    
    if verify_installation; then
        print_status "🎉 Setup completed successfully!" "$GREEN"
        show_access_info
    else
        print_status "⚠️ Setup completed with some issues. Check logs for details." "$YELLOW"
        echo "Log file: $LOG_FILE"
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo "Setup PT XYZ Data Warehouse infrastructure"
        echo
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --skip-pull    Skip pulling Docker images"
        echo "  --dev          Setup for development environment"
        echo
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
