# PT XYZ Data Warehouse - Quick Start Guide

## What's Included

Your Docker Compose setup includes:

### 🗄️ Core Services
- **SQL Server 2022**: Main data warehouse database
- **Apache Airflow**: ETL pipeline orchestration  
- **PostgreSQL**: Backend for Airflow metadata

### 📊 Analytics & Visualization
- **Jupyter Notebooks**: Data analysis environment
- **Grafana**: Real-time dashboards
- **Apache Superset**: Business intelligence tool
- **Metabase**: Alternative BI platform

### ⚙️ Management Tools
- **Redis**: Message broker for Airflow
- **Custom ETL DAGs**: Pre-built data pipelines

## Quick Commands

```bash
# Start everything
make up

# Check status
make status

# View logs
make logs

# Stop everything
make down

# Run tests
./test.sh

# Get help
make help
```

## Access Points

| Service | URL | Login |
|---------|-----|-------|
| **SQL Server** | `localhost:1433` | sa / PTXYZDataWarehouse2025! |
| **Airflow** | http://localhost:8080 | admin / admin |
| **Jupyter** | http://localhost:8888 | No password |
| **Grafana** | http://localhost:3000 | admin / admin |
| **Superset** | http://localhost:8088 | admin / admin |
| **Metabase** | http://localhost:3001 | Setup required |

## First Steps

1. **Start the services:**
   ```bash
   ./setup.sh
   ```

2. **Wait for initialization (2-3 minutes)**

3. **Test the setup:**
   ```bash
   ./test.sh
   ```

4. **Access Airflow and enable DAGs:**
   - Go to http://localhost:8080
   - Login with admin/admin
   - Enable `ptxyz_etl_pipeline` and `ptxyz_dimension_loader`

5. **Check SQL Server:**
   ```bash
   make shell-sql
   # Then run: SELECT name FROM sys.databases;
   ```

6. **Open Jupyter for analysis:**
   - Go to http://localhost:8888
   - Open `ptxyz_analysis.ipynb`

## Data Flow

```
CSV Files → Airflow ETL → SQL Server → Analytics Tools
    ↓              ↓           ↓            ↓
Dataset/    → Transform → Star Schema → Dashboards
```

## Troubleshooting

**Services not starting?**
```bash
make logs
sudo chown -R 50000:0 logs plugins
make restart
```

**SQL Server connection issues?**
```bash
make logs-sql
# Wait longer for SQL Server to initialize
```

**Need more help?**
- Check `DOCKER_README.md` for detailed documentation
- Run `./test.sh` to diagnose issues
- Use `make logs [service]` to see specific service logs

## Project Structure

```
DW_Project_Kelompok22/
├── docker-compose.yml      # Main orchestration file
├── .env                   # Environment variables
├── Makefile              # Easy management commands
├── setup.sh              # Quick setup script
├── test.sh               # Test and validation script
├── DOCKER_README.md      # Detailed documentation
├── Dataset/              # Your CSV data files
├── dags/                 # Airflow ETL pipelines
├── notebooks/            # Jupyter analysis notebooks
├── grafana/              # Dashboard configurations
└── misi3/               # Original SQL scripts
```

Enjoy your PT XYZ Data Warehouse! 🚀
