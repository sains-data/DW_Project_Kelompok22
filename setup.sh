#!/bin/bash

# PT XYZ Data Warehouse Docker Setup Script
echo "=== PT XYZ Data Warehouse Setup ==="

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo "Docker Compose is not available. Please install Docker Compose plugin first."
    exit 1
fi

# Create required directories if they don't exist
echo "Creating required directories..."
mkdir -p logs plugins

# Set appropriate permissions for Airflow
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
