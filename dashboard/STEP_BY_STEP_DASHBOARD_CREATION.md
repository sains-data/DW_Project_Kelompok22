# 🚀 PT XYZ Data Warehouse - Complete Dashboard Creation Guide

## ✅ **VERIFIED WORKING QUERIES** - All Schema-Aligned

This guide provides step-by-step instructions for creating professional dashboards using Superset, Grafana, and Metabase with your PT XYZ mining data warehouse.

---

## 📋 **Prerequisites Checklist**

```bash
# 1. Start all services
./quick-start.sh

# 2. Verify services are running
curl http://localhost:3000  # Grafana
curl http://localhost:8088  # Superset  
curl http://localhost:3001  # Metabase
curl http://localhost:8888  # Jupyter

# 3. Test database connection
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P 'PTXYZSecure123!' \
    -d PTXYZ_DataWarehouse \
    -Q "SELECT COUNT(*) FROM fact.FactEquipmentUsage;" \
    -C -N
```

---

## 🎯 **1. APACHE SUPERSET - Business Intelligence Dashboards**

### **Step 1: Initial Setup**
1. Navigate to: http://localhost:8088
2. Login: `admin` / `admin`
3. You'll see the Superset welcome screen

### **Step 2: Add Database Connection**
1. Click **Settings** → **Database Connections**
2. Click **+ DATABASE** 
3. Select **Microsoft SQL Server**
4. Enter SQLAlchemy URI:
```
mssql+pymssql://sa:PTXYZSecure123!@sqlserver:1433/PTXYZ_DataWarehouse
```
5. Click **TEST CONNECTION** → should show "Connection looks good!"
6. Click **CONNECT**

### **Step 3: Create Datasets**
Add these key tables as datasets:

**Fact Tables:**
- `fact.FactEquipmentUsage`
- `fact.FactProduction`
- `fact.FactFinancialTransaction`

**Dimension Tables:**
- `dim.DimTime`
- `dim.DimSite`
- `dim.DimEquipment`
- `dim.DimMaterial`
- `dim.DimProject`

### **Step 4: Create Executive Dashboard**

#### **Chart 1: Equipment Efficiency KPI**
- **Chart Type**: Big Number
- **Dataset**: `fact.FactEquipmentUsage`
- **SQL**: 
```sql
SELECT AVG(CAST(efficiency_ratio AS FLOAT)) * 100 as efficiency
FROM fact.FactEquipmentUsage f
JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE t.date >= DATEADD(day, -30, GETDATE())
```

#### **Chart 2: Production by Site (Bar Chart)**
- **Chart Type**: Bar Chart
- **Dataset**: `fact.FactProduction`
- **SQL**:
```sql
SELECT 
    s.site_name,
    SUM(f.produced_volume) as total_production
FROM fact.FactProduction f
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE t.date >= DATEADD(day, -30, GETDATE())
GROUP BY s.site_name
ORDER BY total_production DESC
```

#### **Chart 3: Equipment Utilization (Pie Chart)**
- **Chart Type**: Pie Chart
- **Dataset**: `fact.FactEquipmentUsage`
- **SQL**:
```sql
SELECT 
    e.equipment_type,
    SUM(f.operating_hours) as total_hours
FROM fact.FactEquipmentUsage f
JOIN dim.DimEquipment e ON f.equipment_key = e.equipment_key
JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE t.date >= DATEADD(day, -7, GETDATE())
GROUP BY e.equipment_type
```

#### **Chart 4: Budget Performance (Time Series)**
- **Chart Type**: Time Series Line Chart
- **Dataset**: `fact.FactFinancialTransaction`
- **SQL**:
```sql
SELECT 
    t.date as time,
    SUM(f.budgeted_cost) as budgeted,
    SUM(f.actual_cost) as actual
FROM fact.FactFinancialTransaction f
JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE t.date >= DATEADD(day, -30, GETDATE())
GROUP BY t.date
ORDER BY t.date
```

### **Step 5: Build Operations Dashboard**

#### **Chart 5: Daily Production Trend**
```sql
SELECT 
    t.date as time,
    SUM(f.produced_volume) as daily_production
FROM fact.FactProduction f
JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE t.date >= DATEADD(day, -30, GETDATE())
GROUP BY t.date
ORDER BY t.date
```

#### **Chart 6: Equipment Maintenance Costs**
```sql
SELECT 
    e.equipment_type,
    SUM(f.maintenance_cost) as total_maintenance
FROM fact.FactEquipmentUsage f
JOIN dim.DimEquipment e ON f.equipment_key = e.equipment_key
JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE t.date >= DATEADD(day, -30, GETDATE())
GROUP BY e.equipment_type
ORDER BY total_maintenance DESC
```

---

## 📊 **2. GRAFANA - Real-Time Monitoring Dashboards**

### **Step 1: Initial Setup**
1. Navigate to: http://localhost:3000
2. Login: `admin` / `admin`
3. Change password when prompted

### **Step 2: Add Data Source**
1. Go to **Configuration** → **Data Sources**
2. Click **Add data source**
3. Select **Microsoft SQL Server**
4. Configure:
```
Host: sqlserver:1433
Database: PTXYZ_DataWarehouse
User: sa
Password: PTXYZSecure123!
```
5. Click **Save & Test** → should show "Database Connection OK"

### **Step 3: Create Real-Time Dashboard**

#### **Panel 1: Current Equipment Efficiency (Gauge)**
```sql
SELECT 
    AVG(CAST(efficiency_ratio AS FLOAT)) * 100 as current_efficiency
FROM fact.FactEquipmentUsage f
JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE t.date = CAST(GETDATE() AS DATE)
```

#### **Panel 2: Equipment Efficiency Over Time (Time Series)**
```sql
SELECT 
    $__time(t.date),
    e.equipment_type as metric,
    AVG(CAST(f.efficiency_ratio AS FLOAT)) * 100 as efficiency
FROM fact.FactEquipmentUsage f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimEquipment e ON f.equipment_key = e.equipment_key
WHERE $__timeFilter(t.date)
GROUP BY t.date, e.equipment_type
ORDER BY t.date
```

#### **Panel 3: Active Equipment Count (Stat)**
```sql
SELECT 
    COUNT(DISTINCT equipment_key) as active_equipment
FROM fact.FactEquipmentUsage f
JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE t.date = CAST(GETDATE() AS DATE) 
AND f.operating_hours > 0
```

#### **Panel 4: Production by Site (Bar Gauge)**
```sql
SELECT 
    s.site_name as metric,
    SUM(f.produced_volume) as production
FROM fact.FactProduction f
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE $__timeFilter(t.date)
GROUP BY s.site_name
ORDER BY production DESC
```

#### **Panel 5: Fuel Consumption Trend (Time Series)**
```sql
SELECT 
    $__time(t.date),
    SUM(f.fuel_consumption) as fuel_consumption
FROM fact.FactEquipmentUsage f
JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE $__timeFilter(t.date)
GROUP BY t.date
ORDER BY t.date
```

### **Step 4: Set Up Alerts**
1. In any panel, click **Alert** tab
2. Create alert rules for:
   - Equipment efficiency < 80%
   - Production below target
   - High fuel consumption

---

## 📈 **3. METABASE - Self-Service Analytics**

### **Step 1: Initial Setup**
1. Navigate to: http://localhost:3001
2. Complete the setup wizard
3. Create admin account

### **Step 2: Add Database**
1. Click **Add a database**
2. Select **SQL Server**
3. Configure:
```
Host: sqlserver
Port: 1433
Database name: PTXYZ_DataWarehouse
Username: sa
Password: PTXYZSecure123!
```
4. Click **Save**

### **Step 3: Auto-Discovery**
Metabase will automatically:
- Scan all tables
- Create field descriptions
- Suggest chart types
- Generate sample questions

### **Step 4: Create Business Questions**

#### **Question 1: "Which equipment types are most efficient?"**
- Table: `fact.FactEquipmentUsage`
- Summarize: Average of `efficiency_ratio`
- Group by: `equipment_type` (from joined `dim.DimEquipment`)
- Visualization: Bar chart

#### **Question 2: "What's our production trend over time?"**
- Table: `fact.FactProduction`
- Summarize: Sum of `produced_volume`
- Group by: `date` (from joined `dim.DimTime`)
- Visualization: Line chart

#### **Question 3: "Which sites have the highest costs?"**
- Table: `fact.FactFinancialTransaction`
- Summarize: Sum of `actual_cost`
- Group by: `site_name` (from joined `dim.DimSite`)
- Visualization: Bar chart

---

## 🔬 **4. JUPYTER LABS - Advanced Analytics**

### **Step 1: Access Jupyter**
1. Navigate to: http://localhost:8888
2. Enter token: `ptxyz123`

### **Step 2: Create Analysis Notebook**

```python
import pandas as pd
import pymssql
import matplotlib.pyplot as plt
import seaborn as sns

# Connect to database
conn = pymssql.connect(
    server='sqlserver',
    port=1433,
    database='PTXYZ_DataWarehouse',
    user='sa',
    password='PTXYZSecure123!'
)

# Equipment efficiency analysis
efficiency_query = """
SELECT 
    e.equipment_type,
    e.equipment_name,
    s.site_name,
    f.operating_hours,
    f.downtime_hours,
    f.efficiency_ratio,
    f.fuel_consumption,
    f.maintenance_cost
FROM fact.FactEquipmentUsage f
JOIN dim.DimEquipment e ON f.equipment_key = e.equipment_key
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE t.date >= DATEADD(day, -30, GETDATE())
"""

df_equipment = pd.read_sql(efficiency_query, conn)

# Create visualizations
plt.figure(figsize=(12, 8))

# Equipment efficiency by type
plt.subplot(2, 2, 1)
df_equipment.groupby('equipment_type')['efficiency_ratio'].mean().plot(kind='bar')
plt.title('Average Equipment Efficiency by Type')
plt.ylabel('Efficiency Ratio')

# Fuel consumption vs efficiency
plt.subplot(2, 2, 2)
plt.scatter(df_equipment['fuel_consumption'], df_equipment['efficiency_ratio'])
plt.xlabel('Fuel Consumption')
plt.ylabel('Efficiency Ratio')
plt.title('Fuel Consumption vs Efficiency')

# Production analysis
production_query = """
SELECT 
    s.site_name,
    s.region,
    m.material_type,
    SUM(f.produced_volume) as total_production,
    AVG(f.unit_cost) as avg_unit_cost
FROM fact.FactProduction f
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimMaterial m ON f.material_key = m.material_key
JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE t.date >= DATEADD(day, -30, GETDATE())
GROUP BY s.site_name, s.region, m.material_type
"""

df_production = pd.read_sql(production_query, conn)

# Production by region
plt.subplot(2, 2, 3)
df_production.groupby('region')['total_production'].sum().plot(kind='pie')
plt.title('Production by Region')

# Cost analysis
plt.subplot(2, 2, 4)
df_production.plot.scatter(x='total_production', y='avg_unit_cost')
plt.title('Production Volume vs Unit Cost')

plt.tight_layout()
plt.show()

conn.close()
```

---

## 🎯 **5. Advanced OLAP Queries for Deep Analysis**

### **Multi-Dimensional Equipment Analysis**
```sql
SELECT 
    t.year,
    t.quarter,
    t.month,
    s.region,
    s.site_name,
    e.equipment_type,
    COUNT(*) as usage_count,
    AVG(f.efficiency_ratio) * 100 as avg_efficiency,
    SUM(f.operating_hours) as total_operating_hours,
    SUM(f.fuel_consumption) as total_fuel,
    SUM(f.maintenance_cost) as total_maintenance_cost
FROM fact.FactEquipmentUsage f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimEquipment e ON f.equipment_key = e.equipment_key
GROUP BY ROLLUP(t.year, t.quarter, t.month, s.region, s.site_name, e.equipment_type)
ORDER BY t.year, t.quarter, t.month, s.region, s.site_name, e.equipment_type
```

### **Production Performance Cube**
```sql
SELECT 
    t.year,
    t.quarter,
    s.region,
    s.site_name,
    m.material_type,
    emp.department,
    SUM(f.produced_volume) as total_production,
    AVG(f.unit_cost) as avg_unit_cost,
    COUNT(*) as production_sessions
FROM fact.FactProduction f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimMaterial m ON f.material_key = m.material_key
JOIN dim.DimEmployee emp ON f.employee_key = emp.employee_key
GROUP BY CUBE(t.year, t.quarter, s.region, s.site_name, m.material_type, emp.department)
ORDER BY t.year, t.quarter, s.region, s.site_name
```

### **Financial Performance Analysis**
```sql
SELECT 
    t.year,
    t.quarter,
    s.region,
    p.project_name,
    a.account_type,
    SUM(f.budgeted_cost) as total_budgeted,
    SUM(f.actual_cost) as total_actual,
    SUM(f.budgeted_cost - f.actual_cost) as total_variance,
    AVG(CASE WHEN f.budgeted_cost > 0 
        THEN ((f.budgeted_cost - f.actual_cost) / f.budgeted_cost) * 100 
        ELSE 0 END) as avg_variance_pct
FROM fact.FactFinancialTransaction f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimProject p ON f.project_key = p.project_key
JOIN dim.DimAccount a ON f.account_key = a.account_key
GROUP BY ROLLUP(t.year, t.quarter, s.region, p.project_name, a.account_type)
ORDER BY t.year, t.quarter, ABS(SUM(f.budgeted_cost - f.actual_cost)) DESC
```

---

## 🚀 **6. Dashboard Best Practices**

### **Performance Optimization:**
1. **Use Proper Indexes**: Already created in schema
2. **Limit Date Ranges**: Use recent data for real-time dashboards
3. **Aggregate Data**: Use SUM, AVG, COUNT for better performance
4. **Cache Results**: Enable caching in Superset and Grafana

### **Visual Design:**
1. **Consistent Colors**: Use your company brand colors
2. **Clear Titles**: Descriptive chart and panel titles
3. **Proper Scaling**: Ensure axes are appropriately scaled
4. **Responsive Layout**: Design for different screen sizes

### **User Experience:**
1. **Role-Based Access**: Create different dashboards for different roles
2. **Interactive Filters**: Add date, site, and equipment filters
3. **Drill-Down Capability**: Allow users to explore details
4. **Export Options**: Enable PDF and Excel exports

---

## 🔧 **7. Troubleshooting Guide**

### **Common Connection Issues:**
```bash
# Test SQL Server connectivity
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P 'PTXYZSecure123!' \
    -Q "SELECT 1" -C -N

# Restart services if needed
docker compose restart
```

### **Query Performance Issues:**
```sql
-- Check table sizes
SELECT 
    t.name as TableName,
    p.rows as RowCount
FROM sys.tables t
INNER JOIN sys.dm_db_partition_stats p ON t.object_id = p.object_id
WHERE p.index_id < 2
ORDER BY p.rows DESC
```

### **Data Validation:**
```sql
-- Verify data quality
SELECT 
    'Equipment Usage' as TableName,
    COUNT(*) as TotalRows,
    COUNT(DISTINCT equipment_key) as UniqueEquipment,
    MIN(operating_hours) as MinOperatingHours,
    MAX(operating_hours) as MaxOperatingHours
FROM fact.FactEquipmentUsage

UNION ALL

SELECT 
    'Production',
    COUNT(*),
    COUNT(DISTINCT material_key),
    MIN(produced_volume),
    MAX(produced_volume)
FROM fact.FactProduction
```

---

## ✅ **8. Final Verification Checklist**

```bash
# Run comprehensive test
./test_dashboard_queries.sh

# Check all services
docker compose ps

# Verify dashboard access
curl -s http://localhost:3000/api/health
curl -s http://localhost:8088/health
curl -s http://localhost:3001/api/health
```

---

## 🎉 **Congratulations!**

Your PT XYZ Data Warehouse now has:
- ✅ **Apache Superset**: Executive and business intelligence dashboards
- ✅ **Grafana**: Real-time operational monitoring
- ✅ **Metabase**: Self-service analytics for business users  
- ✅ **Jupyter**: Advanced data science and analytics
- ✅ **Comprehensive OLAP Queries**: Multi-dimensional analysis capabilities

**All queries are schema-aligned and tested working! 🚀📊**
