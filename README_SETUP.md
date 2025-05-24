# PT XYZ Data Warehouse Project - Complete Setup Guide

## 🏗️ Architecture Overview

This is a comprehensive Data Warehouse solution for PT XYZ Mining Company with the following components:

### Core Infrastructure
- **SQL Server 2022**: Primary Data Warehouse Database
- **Apache Airflow**: ETL Pipeline Orchestration
- **PostgreSQL**: Airflow Metadata Database
- **Redis**: Message Broker for Airflow

### Analytics & Visualization
- **Apache Superset**: Primary BI Dashboard
- **Grafana**: Monitoring & Additional Dashboards
- **Metabase**: Alternative BI Tool
- **Jupyter Lab**: Data Analysis & Exploration

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose installed
- At least 8GB RAM available
- Linux/macOS/Windows with WSL2

### 1. Environment Setup

Copy the environment template:
```bash
cp .env.example .env
```

Update passwords in `.env` file (recommended for production):
```bash
nano .env
```

### 2. Clean Docker Environment (if needed)

```bash
# Stop all containers
docker stop $(docker ps -aq) 2>/dev/null || true

# Remove all containers
docker rm $(docker ps -aq) 2>/dev/null || true

# Remove all images (CAUTION: This removes ALL Docker images)
docker rmi $(docker images -q) 2>/dev/null || true

# Remove all volumes
docker volume prune -f

# Clean system
docker system prune -af --volumes
```

### 3. Build and Start Services

```bash
# Build and start all services
docker compose up -d --build

# Monitor logs
docker compose logs -f
```

### 4. Verify Services

Check if all services are running:
```bash
docker compose ps
```

Expected services:
- ✅ ptxyz_sqlserver (Port 1433)
- ✅ ptxyz_postgres (Internal)
- ✅ ptxyz_redis (Internal)
- ✅ ptxyz_airflow_webserver (Port 8080)
- ✅ ptxyz_airflow_scheduler (Internal)
- ✅ ptxyz_superset (Port 8088)
- ✅ ptxyz_jupyter (Port 8888)
- ✅ ptxyz_grafana (Port 3000)
- ✅ ptxyz_metabase (Port 3001)

## 🔗 Service Access URLs

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| Airflow Web UI | http://localhost:8080 | admin | admin |
| Superset | http://localhost:8088 | admin | admin |
| Grafana | http://localhost:3000 | admin | admin |
| Metabase | http://localhost:3001 | (setup required) | - |
| Jupyter Lab | http://localhost:8888 | - | Token: ptxyz123 |
| SQL Server | localhost:1433 | sa | YourSecurePassword123! |

## 📁 Project Structure

```
DW_Project_Kelompok22/
├── 📊 Data Layer
│   ├── data/
│   │   ├── raw/Dataset/           # Raw CSV files
│   │   ├── processed/             # Processed data
│   │   └── temp/                  # Temporary files
│   └── init-scripts/              # Database initialization
│
├── 🔄 ETL Layer
│   ├── dags/                      # Airflow DAGs
│   ├── airflow/                   # Airflow configuration
│   └── src/etl/                   # ETL logic
│
├── 📈 Analytics Layer
│   ├── notebooks/                 # Jupyter notebooks
│   ├── grafana/                   # Grafana dashboards
│   └── configs/superset/          # Superset configuration
│
├── 🐳 Infrastructure
│   ├── docker-compose.yml         # Container orchestration
│   ├── .env                       # Environment variables
│   └── logs/                      # Application logs
│
└── 📚 Documentation
    ├── docs/                      # Detailed documentation
    ├── README.md                  # This file
    └── ARCHITECTURE.md            # System architecture
```

## 🛠️ Development Workflow

### Daily Operations

1. **Start the environment:**
   ```bash
   docker compose up -d
   ```

2. **Monitor services:**
   ```bash
   docker compose ps
   docker compose logs -f [service_name]
   ```

3. **Stop the environment:**
   ```bash
   docker compose down
   ```

### ETL Development

1. **Access Airflow UI:** http://localhost:8080
2. **Develop DAGs:** Edit files in `dags/` directory
3. **Test locally:** Use Jupyter Lab for data exploration
4. **Monitor execution:** Check Airflow logs and task status

### Dashboard Development

1. **Superset:** Primary BI tool with rich visualization
2. **Grafana:** Monitoring and time-series dashboards
3. **Metabase:** Simple, user-friendly BI interface

## 🔧 Troubleshooting

### Common Issues

**Issue: Container fails to start**
```bash
# Check logs
docker compose logs [service_name]

# Restart specific service
docker compose restart [service_name]
```

**Issue: Database connection errors**
```bash
# Check SQL Server is healthy
docker compose exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -Q 'SELECT 1'

# Check PostgreSQL
docker compose exec postgres pg_isready -U airflow
```

**Issue: Airflow webserver not accessible**
```bash
# Check if webserver is running
docker compose ps | grep webserver

# Restart Airflow services
docker compose restart airflow-webserver airflow-scheduler
```

**Issue: Port conflicts**
```bash
# Check what's using the port
netstat -tulpn | grep :8080

# Kill process using port
sudo kill -9 $(lsof -t -i:8080)
```

### Service Health Checks

```bash
# Check all service health
docker compose ps

# Individual service health
docker inspect ptxyz_sqlserver | grep -i health
docker inspect ptxyz_postgres | grep -i health
```

### Reset Environment

**Soft reset (keeps data):**
```bash
docker compose down
docker compose up -d
```

**Hard reset (removes all data):**
```bash
docker compose down -v
docker compose up -d --build
```

## 📊 Data Pipeline

### ETL Process Flow

1. **Extract:** Raw CSV files from `data/raw/Dataset/`
2. **Transform:** Data cleaning and processing in Airflow
3. **Load:** Insert into SQL Server Data Warehouse
4. **Visualize:** Dashboards in Superset/Grafana/Metabase

### Monitoring

- **Airflow UI:** Pipeline execution status
- **Grafana:** System metrics and custom dashboards
- **Logs:** Application logs in `logs/` directory

## 🔒 Security Considerations

### Production Deployment

1. **Change default passwords** in `.env` file
2. **Use Docker secrets** for sensitive data
3. **Enable SSL/TLS** for external access
4. **Configure firewall rules** properly
5. **Regular security updates** for base images

### Access Control

- Airflow: Basic authentication enabled
- Superset: Built-in user management
- Grafana: Admin panel with user roles
- Database: Strong SA password required

## 🧪 Testing

### Run Tests

```bash
# ETL tests
python test_etl.py

# Dashboard connection tests
python test_dashboard_queries.py

# Full system test
./test.sh
```

### Data Validation

```bash
# Check schema
python check_schema.py

# Validate fact tables
python check_fact_tables.py

# Financial data validation
python check_financial_table.py
```

## 📞 Support

### Getting Help

1. Check this README first
2. Review service logs: `docker compose logs [service_name]`
3. Check individual service documentation
4. Review project issues and documentation

### Useful Commands

```bash
# View resource usage
docker stats

# Access container shell
docker compose exec [service_name] bash

# Backup database
docker compose exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourSecurePassword123!' -Q "BACKUP DATABASE..."

# View network information
docker network ls
docker network inspect ptxyz-dw_dw_network
```

## 🔄 Updates and Maintenance

### Regular Maintenance

1. **Monitor disk space:** Docker volumes can grow large
2. **Update base images:** Regularly pull latest versions
3. **Backup data:** Regular database and volume backups
4. **Review logs:** Check for errors and performance issues

### Version Updates

```bash
# Pull latest images
docker compose pull

# Rebuild with updates
docker compose up -d --build --force-recreate
```

---

## 📋 Quick Reference

### Service Ports
- SQL Server: 1433
- Airflow: 8080
- Superset: 8088
- Jupyter: 8888
- Grafana: 3000
- Metabase: 3001

### Default Credentials
- **Airflow:** admin/admin
- **Superset:** admin/admin
- **Grafana:** admin/admin
- **SQL Server:** sa/YourSecurePassword123!
- **Jupyter:** Token: ptxyz123

### Key Directories
- **DAGs:** `dags/`
- **Data:** `data/raw/Dataset/`
- **Logs:** `logs/`
- **Notebooks:** `notebooks/`
- **Config:** `configs/`

---

*For detailed architecture and technical documentation, see `ARCHITECTURE.md`*
