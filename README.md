# 🏭 **PT XYZ Data Warehouse - Complete Docker Environment**

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Apache Airflow](https://img.shields.io/badge/Apache%20Airflow-017CEE?style=for-the-badge&logo=apache%20airflow&logoColor=white)](https://airflow.apache.org/)
[![SQL Server](https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white)](https://www.microsoft.com/sql-server)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgresql.org/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)](https://grafana.com/)
[![Jupyter](https://img.shields.io/badge/Jupyter-F37626?style=for-the-badge&logo=jupyter&logoColor=white)](https://jupyter.org/)

## 📋 Project Overview

**PT XYZ Data Warehouse** is a comprehensive data management system designed specifically for the mining industry. This project implements a modern data warehouse architecture using star schema to analyze mining operations, equipment efficiency, material production, and financial management.

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   PT XYZ Data Warehouse                        │
├─────────────────────────────────────────────────────────────────┤
│  📊 Visualization Layer                                         │
│  ├── Grafana (Port 3000)     - Real-time Dashboards           │
│  ├── Superset (Port 8088)    - Advanced Analytics             │
│  ├── Metabase (Port 3001)    - Business Intelligence          │
│  └── Jupyter (Port 8888)     - Data Science Notebooks         │
├─────────────────────────────────────────────────────────────────┤
│  🔄 ETL/ELT Processing Layer                                    │
│  └── Apache Airflow (Port 8080) - Workflow Orchestration      │
├─────────────────────────────────────────────────────────────────┤
│  💾 Data Storage Layer                                          │
│  ├── SQL Server (Port 1433)  - Main Data Warehouse            │
│  ├── PostgreSQL (Port 5432)  - Airflow Metadata               │
│  └── Redis (Port 6379)       - Caching & Message Broker       │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Docker Engine 20.10+
- Docker Compose V2
- At least 8GB RAM
- At least 20GB free disk space

### 1. Environment Setup
```bash
# Clone the repository (if not already done)
cd DW_Project_Kelompok22

# Ensure environment file exists
ls -la .env
```

### 2. Clean Docker Environment
```bash
# Remove all existing containers and volumes for clean start
docker system prune -af --volumes
```

### 3. Start All Services
```bash
# Start all services in background
docker compose up -d

# Check status (wait 5-10 minutes for full initialization)
docker compose ps
```

### 4. Access Services
After startup, access these URLs:

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| **Airflow** | http://localhost:8080 | admin / admin |
| **Grafana** | http://localhost:3000 | admin / admin |
| **Superset** | http://localhost:8088 | admin / admin |
| **Metabase** | http://localhost:3001 | Setup on first visit |
| **Jupyter** | http://localhost:8888 | Token in logs: `docker compose logs jupyter` |
| **SQL Server** | localhost:1433 | sa / YourPassword123! |

## 📊 Service Details

### 🔄 Apache Airflow - ETL Orchestration
- **URL**: http://localhost:8080
- **Purpose**: Schedules and monitors ETL pipelines
- **Key Features**:
  - Automated data extraction from CSV sources
  - Data transformation and cleaning
  - Loading into SQL Server data warehouse
  - Comprehensive logging and monitoring

### 💾 SQL Server - Main Data Warehouse
- **Connection**: localhost:1433
- **Database**: PTXYZ_DW
- **Purpose**: Central analytical database
- **Schema**: Star schema with fact and dimension tables

### 📈 Grafana - Real-time Dashboards
- **URL**: http://localhost:3000
- **Purpose**: Operational monitoring dashboards
- **Features**: Production metrics, equipment performance, KPI tracking

### 🔍 Apache Superset - Advanced Analytics
- **URL**: http://localhost:8088
- **Purpose**: Self-service business intelligence
- **Features**: SQL Lab, chart builder, dashboard creation

### 🏢 Metabase - Business Intelligence
- **URL**: http://localhost:3001
- **Purpose**: User-friendly analytics interface
- **Features**: Question builder, automated insights, executive reports

### 📓 Jupyter - Data Science Environment
- **URL**: http://localhost:8888
- **Purpose**: Data science and analysis
- **Pre-installed**: pandas, numpy, matplotlib, seaborn, plotly, scikit-learn

## 🛠️ Management Commands

### Service Management
```bash
# View all container status
docker compose ps

# View logs for specific service
docker compose logs -f airflow-webserver

# Restart specific services
docker compose restart airflow-webserver airflow-scheduler

# Stop all services
docker compose down

# Complete cleanup (removes volumes)
docker compose down -v --remove-orphans
docker system prune -af --volumes
```

### Database Operations
```bash
# Connect to SQL Server
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'YourPassword123!' -C -N

# Connect to PostgreSQL (Airflow metadata)
docker compose exec postgres psql -U airflow -d airflow_db

# Check Redis
docker compose exec redis redis-cli ping
```

## 🔍 Troubleshooting

### Common Issues

#### Services Won't Start
```bash
# Check if ports are available
netstat -tulpn | grep -E ':(3000|8080|8088|3001|8888|1433)'

# Check Docker resources
docker system df
docker stats
```

#### Airflow Database Issues
```bash
# Reset Airflow metadata (will lose DAG history)
docker compose down
docker volume rm ptxyz-dw_postgres_data
docker compose up -d postgres redis
# Wait for postgres to be healthy, then start Airflow
docker compose up -d airflow-webserver airflow-scheduler airflow-worker
```

#### SQL Server Connection Problems
```bash
# Verify SQL Server health
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'YourPassword123!' -Q "SELECT @@VERSION" -C -N

# Check logs for errors
docker compose logs sqlserver
```

#### Performance Issues
- Ensure Docker has at least 8GB RAM allocated
- Check available disk space: `df -h`
- Monitor container resources: `docker stats`

### Health Monitoring
```bash
# Check all service health
docker compose ps

# Monitor resource usage
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# View service logs
docker compose logs --tail=50 <service-name>
```

## 📁 Data Engineering Best Practices

### Project Structure
```
DW_Project_Kelompok22/
├── data/
│   ├── raw/           # Source CSV files
│   ├── processed/     # Cleaned data
│   └── logs/          # ETL logs
├── dags/              # Airflow DAGs
├── src/
│   ├── etl/           # ETL processing scripts
│   └── utils/         # Utility functions
├── configs/           # Configuration files
├── grafana/           # Grafana dashboards
└── docs/              # Documentation
```

### ETL Pipeline Design
1. **Extract**: Read data from CSV files in `data/raw/Dataset/`
2. **Transform**: Clean, validate, and prepare data
3. **Load**: Insert into SQL Server dimensional model
4. **Monitor**: Track data quality and pipeline health

## 🚀 Next Steps

1. **Verify All Services**: Check that all URLs are accessible
2. **Load Sample Data**: Run ETL pipeline to populate data warehouse
3. **Configure Dashboards**: Set up Grafana and Superset dashboards
4. **Test Connections**: Verify database connections from all tools
5. **Custom Development**: Add your specific business logic and reports

## 📞 Support

For issues:
1. Check this troubleshooting guide
2. Review container logs: `docker compose logs <service>`
3. Ensure all prerequisites are met
4. Check Docker and system resources

---

**🎯 PT XYZ Data Warehouse - Complete Docker Environment Ready!**
    end
```

## 🚀 Fitur Utama

### 📊 **Dashboard & Visualisasi**
- **Real-time Monitoring**: Dashboard Grafana untuk monitoring operasi 24/7
- **Advanced Analytics**: Apache Superset untuk analisis data mendalam
- **Business Reports**: Metabase untuk laporan bisnis reguler
- **Data Science**: Jupyter Notebooks untuk analisis prediktif

### 🔄 **ETL Pipeline**
- **Automated Processing**: Pipeline ETL otomatis menggunakan Apache Airflow
- **Data Quality**: Validasi dan pembersihan data otomatis
- **Scalable Architecture**: Dapat menangani volume data besar
- **Error Handling**: Sistem monitoring dan alerting untuk error handling

### 📈 **Analytics & KPI**
- **Equipment Efficiency**: Tracking efisiensi peralatan dan downtime
- **Production Metrics**: Monitoring produksi berdasarkan material dan region
- **Financial Analysis**: Analisis varians budget dan cost control
- **Operational Intelligence**: Insights untuk optimasi operasional

## 🛠️ Teknologi yang Digunakan

### **Core Technologies**
| Teknologi | Versi | Fungsi |
|-----------|-------|--------|
| **Docker** | Latest | Containerization & Deployment |
| **Python** | 3.12+ | ETL Scripts & Data Processing |
| **SQL Server** | 2022 | Data Warehouse Database |
| **Apache Airflow** | 2.8+ | ETL Orchestration |

### **Visualization Tools**
| Tool | Port | Fungsi |
|------|------|--------|
| **Grafana** | 3000 | Real-time Dashboards |
| **Apache Superset** | 8088 | Advanced Analytics |
| **Metabase** | 3001 | Business Intelligence |
| **Jupyter** | 8888 | Data Science Analysis |

### **Supporting Services**
- **PostgreSQL**: Metadata storage untuk Airflow
- **Redis**: Caching & message broker
- **Docker Compose**: Multi-container orchestration

## 📦 Instalasi & Setup

### **Prasyarat**
```bash
# Pastikan Docker dan Docker Compose terinstall
docker --version
docker-compose --version

# Minimum requirements:
# - RAM: 8GB
# - Storage: 10GB free space
# - OS: Linux/macOS/Windows with WSL2
```

### **Quick Start**
```bash
# 1. Clone repository
git clone <repository-url>
cd DW_Project_Kelompok22

# 2. Setup environment
cp .env.example .env
# Edit .env sesuai kebutuhan

# 3. Build dan jalankan semua services
docker-compose up -d

# 4. Tunggu semua services siap (5-10 menit)
./show_status.sh

# 5. Jalankan ETL pipeline
python standalone_etl.py

# 6. Akses dashboards
./open_dashboards.sh
```

### **Akses Services**
| Service | URL | Username | Password |
|---------|-----|----------|----------|
| Grafana | http://localhost:3000 | admin | admin |
| Superset | http://localhost:8088 | admin | admin |
| Metabase | http://localhost:3001 | - | Setup required |
| Airflow | http://localhost:8080 | admin | admin |
| Jupyter | http://localhost:8888 | - | Token-based |

## 📁 Struktur Proyek

```
DW_Project_Kelompok22/
├── 📊 Dashboard Configuration
│   ├── grafana/                    # Grafana dashboards & datasources
│   ├── superset-config/            # Superset configuration
│   └── notebooks/                  # Jupyter analysis notebooks
│
├── 🔄 ETL Pipeline
│   ├── dags/                       # Airflow DAGs
│   ├── airflow/                    # Airflow configuration
│   ├── standalone_etl.py           # Standalone ETL script
│   └── run_complete_etl.py         # Complete ETL runner
│
├── 🗄️ Data & Schema
│   ├── Dataset/                    # Sample datasets
│   ├── init-scripts/               # Database initialization
│   └── misi*/                      # Project milestones
│
├── 🐳 Infrastructure
│   ├── docker-compose.yml          # Multi-container setup
│   ├── Dockerfile                  # Custom images
│   └── .env.example                # Environment template
│
├── 📋 Documentation
│   ├── README.md                   # Main documentation
│   ├── QUICKSTART.md               # Quick start guide
│   ├── DOCKER_README.md            # Docker setup guide
│   ├── CONTRIBUTING.md             # Contribution guidelines
│   ├── SECURITY.md                 # Security guidelines
│   └── FINAL_DEPLOYMENT_REPORT.md  # Deployment status
│
└── 🛠️ Utilities
    ├── setup.sh                   # Setup script
    ├── test.sh                     # Testing script
    ├── show_status.sh              # Status checker
    └── open_dashboards.sh          # Dashboard launcher
```

## 🗃️ Database Schema

### **Star Schema Design**
```sql
-- Dimension Tables
dim.DimTime          (830 records)     -- Time dimensions
dim.DimSite          (1,747 records)   -- Mining sites
dim.DimEquipment     (6 records)       -- Heavy equipment
dim.DimMaterial      (5 records)       -- Mined materials
dim.DimEmployee      (10 records)      -- Workforce
dim.DimShift         (3 records)       -- Work shifts
dim.DimProject       (50 records)      -- Mining projects
dim.DimAccount       (30 records)      -- Financial accounts

-- Fact Tables
fact.FactEquipmentUsage      (236,892 records)  -- Equipment operations
fact.FactProduction          (2,261 records)    -- Production output
fact.FactFinancialTransaction (115,901 records) -- Financial transactions
```

### **Key Relationships**
- Semua fact tables menggunakan foreign key `*_key` yang menghubungkan ke dimension tables
- Surrogate keys digunakan untuk optimasi performance
- Computed columns untuk kalkulasi otomatis (variance, efficiency)

## 📊 Dashboard & Analytics

### **1. Equipment Efficiency Dashboard**
- **Metrics**: Operating hours, downtime, efficiency percentage
- **Granularity**: Per equipment type, daily/weekly/monthly
- **KPI**: 95.66% overall equipment efficiency

### **2. Production Analytics**
- **Material Tracking**: Metal (434,721 units), Ore (112,687 units)
- **Regional Analysis**: Production per region dan site
- **Trend Analysis**: Daily production trends

### **3. Financial Management**
- **Budget Variance**: Actual vs budgeted costs
- **Project Tracking**: 50 active mining projects
- **Cost Control**: Real-time cost monitoring

### **4. Operational Intelligence**
- **Real-time Monitoring**: Live operational status
- **Predictive Analytics**: Equipment maintenance scheduling
- **Performance Optimization**: Efficiency improvement recommendations

## 🧪 Testing & Validation

### **Data Quality Tests**
```bash
# Jalankan test suite lengkap
./test.sh

# Test individual components
python test_etl.py              # ETL pipeline testing
python test_dashboard_queries.py # Dashboard query validation
python check_schema.py          # Schema validation
```

### **Performance Benchmarks**
- **ETL Processing**: 350K+ records dalam < 5 menit
- **Query Performance**: Sub-second response untuk dashboard queries
- **Data Integrity**: 100% referential integrity maintained
- **System Uptime**: 99.9% availability target

## 👥 Tim Pengembang

| Nama | NPM | Role | Kontribusi |
|------|-----|------|------------|
| **Ericson Chandra Sihombing** | 121450026 | Project Lead | Architecture & System Design |
| **Ramadhita Atifa Hendri** | 121450131 | Data Engineer | ETL Pipeline & Data Modeling |
| **Eggi Satria** | 122450032 | DevOps Engineer | Infrastructure & Deployment |
| **Nabila Anilda Zahrah** | 122450063 | Analytics Engineer | Dashboard & Visualization |
| **Syalaisha Andini Putriansyah** | 122450111 | QA Engineer | Testing & Documentation |

## 📚 Dokumentasi Tambahan

### **Panduan Pengguna**
- 📖 [Quick Start Guide](QUICKSTART.md) - Memulai dengan cepat
- 🐳 [Docker Setup](DOCKER_README.md) - Setup menggunakan Docker
- 🔧 [Contributing Guide](CONTRIBUTING.md) - Panduan kontribusi
- 🔒 [Security Guidelines](SECURITY.md) - Panduan keamanan

### **Referensi Teknis**
- 📊 [Dashboard Connection Guide](DASHBOARD_CONNECTION_GUIDE.json)
- 📋 [SQL Queries Reference](DASHBOARD_SQL_QUERIES.json)
- 📈 [Final Deployment Report](FINAL_DEPLOYMENT_REPORT.md)

## 🤝 Kontribusi

Kami menyambut kontribusi dari komunitas! Silakan baca [CONTRIBUTING.md](CONTRIBUTING.md) untuk panduan detail.

### **Cara Berkontribusi**
1. Fork repository ini
2. Buat feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit perubahan (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

## 📄 Lisensi

Proyek ini dilisensikan under MIT License - lihat file [LICENSE](LICENSE) untuk detail.

## 🆘 Support & Troubleshooting

### **FAQ**
**Q: Service tidak bisa start?**
A: Pastikan port 1433, 3000, 8080, 8088 tidak digunakan aplikasi lain.

**Q: ETL gagal dengan error koneksi?**
A: Tunggu 5-10 menit untuk semua services siap, kemudian coba lagi.

**Q: Dashboard tidak menampilkan data?**
A: Jalankan `python standalone_etl.py` untuk load data terlebih dahulu.

### **Mendapatkan Bantuan**
- 🐛 [Report Issues](../../issues) - Laporkan bug atau request fitur
- 📧 Email: eggi.122450032@students.itera.ac.id
- 💬 Diskusi: Gunakan GitHub Discussions
---

<div align="center">

**🏆 PT XYZ Data Warehouse - Solusi Data Mining Terpadu**

*Dikembangkan dengan ❤️ oleh Kelompok 22*

[![Kelompok 22](https://img.shields.io/badge/Kelompok-22-blue?style=for-the-badge)](.)
[![Institut Teknologi Sumatera](https://img.shields.io/badge/Institut%20Teknologi%20Sumatera-green?style=for-the-badge)](https://www.itera.ac.id)
[![Data Warehouse](https://img.shields.io/badge/Data-Warehouse-orange?style=for-the-badge)](.)

</div>
