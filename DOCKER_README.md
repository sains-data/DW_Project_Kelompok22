# PT XYZ Data Warehouse Docker Implementation

## Overview

This Docker Compose setup provides a complete data warehouse implementation for PT XYZ's mining operations, including:

- **SQL Server 2022**: Main data warehouse database
- **Apache Airflow**: ETL pipeline orchestration
- **Jupyter Notebooks**: Data analysis and exploration
- **Grafana**: Real-time dashboards and monitoring
- **Apache Superset**: Business intelligence and visualization
- **Metabase**: Alternative BI tool for business users

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Data Sources  │    │   ETL Pipeline  │    │  Data Warehouse │
│                 │    │                 │    │                 │
│ • SAP S/4HANA   │────▶│ Apache Airflow  │────▶│  SQL Server     │
│ • IoT Sensors   │    │ • Extract       │    │ • Star Schema   │
│ • CSV Files     │    │ • Transform     │    │ • Fact Tables   │
│ • Excel         │    │ • Load          │    │ • Dimension     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
┌─────────────────┐    ┌─────────────────┐              │
│  Visualization  │    │    Analysis     │              │
│                 │    │                 │              │
│ • Grafana       │◀───┤ • Jupyter       │◀─────────────┘
│ • Superset      │    │ • Python/SQL    │
│ • Metabase      │    │ • Data Science  │
└─────────────────┘    └─────────────────┘
```

## Prerequisites

- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)
- At least 8GB RAM
- At least 20GB free disk space

## Quick Start

1. **Clone and navigate to the project directory:**
   ```bash
   cd /home/egistr/Documents/kuliah/semester6/dw/DW_Project_Kelompok22
   ```

2. **Run the setup script:**
   ```bash
   ./setup.sh
   ```

3. **Or start services manually:**
   ```bash
   docker compose up -d
   ```

## Service Access

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| SQL Server | `localhost:1433` | sa / PTXYZDataWarehouse2025! |
| Airflow | http://localhost:8080 | admin / admin |
| Jupyter | http://localhost:8888 | No password |
| Grafana | http://localhost:3000 | admin / admin |
| Superset | http://localhost:8088 | admin / admin |
| Metabase | http://localhost:3001 | Setup on first access |

## Data Structure

### Fact Tables
- `fact_production`: Mining production data
- `fact_equipment_usage`: Heavy equipment utilization
- `fact_financials`: Financial and cost data
- `fact_environmental`: Environmental compliance data

### Dimension Tables
- `dim_time`: Time dimension
- `dim_site`: Mining site locations
- `dim_material`: Material types
- `dim_employee`: Employee information
- `dim_shift`: Work shifts
- `dim_equipment`: Heavy equipment details
- `dim_project`: Project information
- `dim_account`: Financial accounts
- `dim_environmental_activity`: Environmental activities

## ETL Pipeline

The Airflow DAG `ptxyz_etl_pipeline` includes:

1. **Extract**: Data from CSV files and external sources
2. **Transform**: Data cleaning, validation, and standardization
3. **Load**: Insert into SQL Server data warehouse
4. **Quality Check**: Data validation and integrity checks

### Running the ETL Pipeline

1. Access Airflow at http://localhost:8080
2. Enable the `ptxyz_etl_pipeline` DAG
3. Monitor execution in the Airflow UI

## Data Analysis

### Jupyter Notebooks

Pre-configured notebook available at `/notebooks/ptxyz_analysis.ipynb` includes:
- Database connection setup
- Data exploration and visualization
- Sample analytical queries
- Production and equipment analysis

### Sample Queries

```sql
-- Production by material type
SELECT DM.material_name, SUM(FP.volume_produced) AS total_production
FROM fact_production FP
JOIN dim_material DM ON FP.material_key = DM.material_key
GROUP BY DM.material_name
ORDER BY total_production DESC;

-- Equipment utilization
SELECT E.equipment_name, 
       SUM(operating_hours) as total_operating,
       SUM(idle_hours) as total_idle,
       (SUM(operating_hours) / (SUM(operating_hours) + SUM(idle_hours)) * 100) as utilization_percent
FROM fact_equipment_usage F
JOIN dim_equipment E ON F.equipment_key = E.equipment_key
GROUP BY E.equipment_name
ORDER BY utilization_percent DESC;
```

## Monitoring and Visualization

### Grafana Dashboards
- Production KPIs
- Equipment utilization
- Financial metrics
- Environmental compliance

### Superset Charts
- Interactive production reports
- Equipment performance analysis
- Cost analysis dashboards

## Data Loading

### Initial Data Setup

1. **Place your data files in the `Dataset/` directory**
2. **The following files are expected:**
   - `dataset_production.csv`: Production data
   - `dataset_alat_berat_dw.csv`: Equipment data
   - Additional transaction data in `dataset_transaksi/`

3. **Run the ETL pipeline to load data into the warehouse**

### Data Format Requirements

#### Production Data
```csv
date,site,material,material_type,unit,operator,shift,volume,target
2025-01-01,Site A,Coal,Bituminous,Tons,John Doe,Day,1500,1400
```

#### Equipment Data
```csv
equipment_id,equipment_name,equipment_type,operating_hours,idle_hours,fuel_consumed
EQ001,Excavator 1,Excavator,8.5,1.5,250.5
```

## Troubleshooting

### Common Issues

1. **SQL Server connection issues:**
   ```bash
   docker compose logs sqlserver
   ```

2. **Airflow initialization problems:**
   ```bash
   docker compose logs airflow-webserver
   ```

3. **Permission issues with Airflow:**
   ```bash
   sudo chown -R 50000:0 logs plugins
   ```

### Useful Commands

```bash
# View all service logs
docker compose logs

# View specific service logs
docker compose logs [service_name]

# Restart a specific service
docker compose restart [service_name]

# Stop all services
docker compose down

# Stop and remove all data
docker compose down -v

# Scale Airflow workers
docker compose up -d --scale airflow-worker=3
```

## Security Considerations

⚠️ **Important**: This setup is for development/testing purposes. For production:

1. Change all default passwords
2. Use secure connection strings
3. Enable SSL/TLS
4. Implement proper network security
5. Use secrets management
6. Enable audit logging

## Performance Tuning

### SQL Server Optimization
- Implement proper indexing (already included in scripts)
- Configure appropriate memory settings
- Use table partitioning for large datasets

### Airflow Optimization
- Adjust parallelism settings
- Monitor DAG performance
- Scale workers based on workload

## Backup and Recovery

### SQL Server Backups
```sql
BACKUP DATABASE DW_PTXYZ TO DISK = '/var/opt/mssql/backup/DW_PTXYZ.bak'
```

### Data Volume Backups
```bash
docker run --rm -v ptxyz-dw_sqlserver_data:/data -v $(pwd):/backup alpine tar czf /backup/sqlserver_backup.tar.gz /data
```

## Support and Maintenance

### Health Checks
All services include health checks. Monitor with:
```bash
docker compose ps
```

### Log Rotation
Configure log rotation for production environments to prevent disk space issues.

### Updates
Regularly update Docker images:
```bash
docker compose pull
docker compose up -d
```

## Development

### Adding New Data Sources
1. Update the Airflow DAG in `dags/ptxyz_etl_dag.py`
2. Add data transformation logic
3. Update database schema if needed

### Custom Dashboards
1. **Grafana**: Import dashboard JSON files
2. **Superset**: Create charts and dashboards via UI
3. **Metabase**: Use the question builder

## License

This implementation is for educational purposes as part of the PT XYZ Data Warehouse project.

## Contributors

- Ericson Chandra Sihombing (121450026)
- Ramadhita Atifa Hendri (121450131)
- Eggi Satria (122450032)
- Nabila Anilda Zahrah (122450063)
- Syalaisha Andini Putriansyah (122450111)

Program Studi Sains Data  
Fakultas Sains  
Institut Teknologi Sumatera  
2025
