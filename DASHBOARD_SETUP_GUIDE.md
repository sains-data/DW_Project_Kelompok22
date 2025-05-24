# Dashboard Configuration Guide

## 🎯 Quick Start Guide for PT XYZ Data Warehouse Dashboards

All visualization platforms are now ready for configuration. Follow these steps to connect them to your data warehouse.

---

## 📊 SQL Server Connection Details

Use these connection parameters for all dashboard tools:

```
Host: localhost (or sqlserver from within Docker network)
Port: 1433
Database: PTXYZ_DataWarehouse
Username: sa
Password: YourSecurePassword123!
```

---

## 1. 📈 Grafana Setup (Port 3000)

### Initial Login:
- URL: http://localhost:3000
- Username: `admin`
- Password: `admin`

### Add SQL Server Data Source:
1. Go to **Configuration** → **Data Sources**
2. Click **Add data source**
3. Select **Microsoft SQL Server**
4. Configure:
   ```
   Host: sqlserver:1433
   Database: PTXYZ_DataWarehouse
   User: sa
   Password: YourSecurePassword123!
   ```

### Sample Queries for Dashboards:
```sql
-- Equipment Usage by Site
SELECT 
    s.site_name,
    SUM(f.operating_hours) as total_hours,
    AVG(f.fuel_consumption) as avg_fuel
FROM fact.FactEquipmentUsage f
JOIN dim.DimSite s ON f.site_key = s.site_key
GROUP BY s.site_name;

-- Production by Month
SELECT 
    t.month_name,
    t.year,
    SUM(f.produced_volume) as total_production
FROM fact.FactProduction f
JOIN dim.DimTime t ON f.time_key = t.time_key
GROUP BY t.month_name, t.year
ORDER BY t.year, t.month;
```

---

## 2. 🚀 Apache Superset Setup (Port 8088)

### Initial Login:
- URL: http://localhost:8088
- Username: `admin`
- Password: `admin`

### Add Database Connection:
1. Go to **Settings** → **Database Connections**
2. Click **+ DATABASE**
3. Select **Microsoft SQL Server**
4. Configure SQLAlchemy URI:
   ```
   mssql+pymssql://sa:YourSecurePassword123!@sqlserver:1433/PTXYZ_DataWarehouse
   ```

### Create Datasets:
Add these key tables as datasets:
- `fact.FactEquipmentUsage`
- `fact.FactProduction`  
- `fact.FactFinancialTransaction`
- `dim.DimSite`
- `dim.DimTime`

---

## 3. 📊 Metabase Setup (Port 3001)

### Initial Setup:
- URL: http://localhost:3001
- Follow the setup wizard

### Add SQL Server Database:
1. In setup wizard, choose **SQL Server**
2. Configure:
   ```
   Host: sqlserver
   Port: 1433
   Database name: PTXYZ_DataWarehouse
   Username: sa
   Password: YourSecurePassword123!
   ```

### Auto-scan Tables:
Metabase will automatically discover and analyze your dimensional model tables.

---

## 4. 🔬 Jupyter Labs Setup (Port 8888)

### Access:
- URL: http://localhost:8888
- No authentication required (development setup)

### Connect to SQL Server:
Create a new notebook and use this connection code:
```python
import pandas as pd
import pymssql

# Database connection
conn = pymssql.connect(
    server='sqlserver',
    port=1433,
    database='PTXYZ_DataWarehouse',
    user='sa',
    password='YourSecurePassword123!'
)

# Sample query
query = """
SELECT TOP 10 
    s.site_name,
    e.equipment_name,
    f.operating_hours,
    f.fuel_consumption
FROM fact.FactEquipmentUsage f
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimEquipment e ON f.equipment_key = e.equipment_key
ORDER BY f.operating_hours DESC
"""

df = pd.read_sql(query, conn)
print(df)
```

---

## 📋 Key Business Metrics to Track

### Equipment Performance:
- Total operating hours by equipment type
- Fuel consumption trends
- Maintenance costs by site
- Equipment downtime analysis

### Production Analytics:
- Production volume by material type
- Site productivity comparisons
- Shift performance analysis
- Employee productivity metrics

### Financial Insights:
- Budget vs actual cost analysis
- Project profitability tracking
- Cost variance by account type
- Regional financial performance

---

## 🎯 Sample Dashboard Ideas

### 1. Executive Dashboard:
- Total production volume (current month)
- Equipment utilization rates
- Cost variance summary
- Site performance overview

### 2. Operations Dashboard:
- Real-time equipment status
- Shift production targets
- Maintenance alerts
- Fuel consumption monitoring

### 3. Financial Dashboard:
- Budget vs actual spending
- Project cost tracking
- Account-wise expense analysis
- Cost trend analysis

---

## 🔧 Troubleshooting

### Connection Issues:
- Ensure SQL Server container is running: `docker ps | grep sqlserver`
- Check network connectivity: Use `sqlserver` as hostname within Docker
- Verify credentials: Username `sa`, Password `YourSecurePassword123!`

### Data Issues:
- Refresh ETL: Run `python standalone_etl.py`
- Check data quality: Review ETL logs in `etl_execution.log`
- Verify table contents: Use SQL queries to inspect data

### Performance:
- Index optimization: Review database indexes
- Query tuning: Optimize dashboard queries
- Resource monitoring: Check Docker container resources

---

## 📈 Next Steps

1. **Configure Data Sources**: Set up connections in all platforms
2. **Create Dashboards**: Build business-specific visualizations  
3. **Set up Alerts**: Configure monitoring and notifications
4. **User Access**: Set up user accounts and permissions
5. **Scheduled Reports**: Automate report generation

---

**Happy Analyzing! 🚀**

Your PT XYZ Data Warehouse is now ready for comprehensive business intelligence and analytics.
