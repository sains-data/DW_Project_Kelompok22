.PHONY: help build up down restart logs clean backup restore

# Default target
help:
	@echo "PT XYZ Data Warehouse Docker Management"
	@echo "======================================"
	@echo "Available commands:"
	@echo "  make build      - Build all Docker images"
	@echo "  make up         - Start all services"
	@echo "  make down       - Stop all services"
	@echo "  make restart    - Restart all services"
	@echo "  make logs       - View all logs"
	@echo "  make clean      - Stop and remove all containers and volumes"
	@echo "  make backup     - Backup SQL Server data"
	@echo "  make restore    - Restore SQL Server data"
	@echo "  make status     - Show service status"
	@echo ""
	@echo "Individual services:"
	@echo "  make logs-sql   - View SQL Server logs"
	@echo "  make logs-airflow - View Airflow logs"
	@echo "  make shell-sql  - Connect to SQL Server"

# Build all services
build:
	@echo "Building PT XYZ Data Warehouse services..."
	docker compose build

# Start all services
up:
	@echo "Starting PT XYZ Data Warehouse services..."
	docker compose up -d
	@echo "Services started. Access points:"
	@echo "- SQL Server: localhost:1433"
	@echo "- Airflow: http://localhost:8080"
	@echo "- Jupyter: http://localhost:8888"
	@echo "- Grafana: http://localhost:3000"
	@echo "- Superset: http://localhost:8088"
	@echo "- Metabase: http://localhost:3001"

# Stop all services
down:
	@echo "Stopping PT XYZ Data Warehouse services..."
	docker compose down

# Restart all services
restart:
	@echo "Restarting PT XYZ Data Warehouse services..."
	docker compose restart

# View all logs
logs:
	docker compose logs -f

# View SQL Server logs
logs-sql:
	docker compose logs -f sqlserver

# View Airflow logs
logs-airflow:
	docker compose logs -f airflow-webserver airflow-scheduler airflow-worker

# Show service status
status:
	docker compose ps

# Clean everything (CAREFUL: This removes all data!)
clean:
	@echo "WARNING: This will remove all containers and data volumes!"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ]
	docker compose down -v
	docker system prune -f

# Backup SQL Server data
backup:
	@echo "Creating backup of SQL Server data..."
	docker run --rm \
		-v ptxyz-dw_sqlserver_data:/data \
		-v $(PWD)/backups:/backup \
		alpine sh -c "mkdir -p /backup && tar czf /backup/sqlserver_backup_$(shell date +%Y%m%d_%H%M%S).tar.gz /data"
	@echo "Backup completed in ./backups/"

# Create backups directory if it doesn't exist
backups:
	mkdir -p backups

# Initialize development environment
init-dev: backups
	@echo "Initializing development environment..."
	mkdir -p logs plugins
	sudo chown -R 50000:0 logs plugins
	@echo "Development environment ready!"

# Connect to SQL Server shell
shell-sql:
	docker compose exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P PTXYZDataWarehouse2025!

# Monitor services
monitor:
	@echo "Monitoring PT XYZ Data Warehouse services..."
	watch docker compose ps
