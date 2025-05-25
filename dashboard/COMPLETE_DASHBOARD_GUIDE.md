# 🚀 PT XYZ Data Warehouse - Complete Dashboard Setup Guide
## With Schema-Aligned OLAP Queries

### ⚠️ **FIXED SCHEMA ISSUES**
- Corrected column names to match actual database schema
- Fixed `maintenance_hours` → `maintenance_cost` 
- Updated all fact table column references
- Aligned with `dim.*` and `fact.*` schema structure

---

## 🎯 **1. Quick Environment Setup**

### Start All Services:
```bash
# Navigate to project directory
cd /home/egistr/Documents/kuliah/semester6/dw/DW_Project_Kelompok22

# Start all dashboard services
./quick-start.sh
```

### Service Access URLs:
- **Grafana**: http://localhost:3000 (admin/admin)
- **Superset**: http://localhost:8088 (admin/admin)  
- **Metabase**: http://localhost:3001 (setup required)
- **Jupyter**: http://localhost:8888 (token: ptxyz123)

---

## 📊 **2. Schema-Aligned Dashboard Queries**

### **Equipment Performance Dashboard**
```sql
-- Equipment Utilization (CORRECTED)
SELECT 
    e.equipment_type,
    e.model,
    s.site_name,
    s.region,
    COUNT(*) as usage_sessions,
    AVG(f.operating_hours) as avg_operating_hours,
    AVG(f.downtime_hours) as avg_downtime_hours,
    SUM(f.fuel_consumption) as total_fuel_consumption,
    AVG(f.maintenance_cost) as avg_maintenance_cost,
    AVG(f.efficiency_ratio) as avg_efficiency_ratio
FROM fact.FactEquipmentUsage f
JOIN dim.DimEquipment e ON f.equipment_key = e.equipment_key
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE t.year = 2024
GROUP BY e.equipment_type, e.model, s.site_name, s.region
ORDER BY total_fuel_consumption DESC;
```

### **Production Analytics Dashboard**
```sql
-- Production Performance (CORRECTED)
SELECT 
    t.year,
    t.month,
    t.month_name,
    s.site_name,
    s.region,
    m.material_type,
    SUM(f.produced_volume) as total_production,
    AVG(f.unit_cost) as avg_unit_cost,
    SUM(f.total_cost) as total_cost,
    COUNT(*) as production_sessions
FROM fact.FactProduction f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimMaterial m ON f.material_key = m.material_key
GROUP BY t.year, t.month, t.month_name, s.site_name, s.region, m.material_type
ORDER BY t.year DESC, t.month DESC, total_production DESC;
```

### **Financial Performance Dashboard**
```sql
-- Budget vs Actual Analysis (CORRECTED)
SELECT 
    t.year,
    t.quarter,
    s.site_name,
    s.region,
    p.project_name,
    a.account_type,
    SUM(f.budgeted_cost) as total_budgeted,
    SUM(f.actual_cost) as total_actual,
    SUM(f.variance_amount) as total_variance,
    AVG(f.variance_percentage) as avg_variance_percentage
FROM fact.FactFinancialTransaction f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimProject p ON f.project_key = p.project_key
JOIN dim.DimAccount a ON f.account_key = a.account_key
WHERE t.year = 2024
GROUP BY t.year, t.quarter, s.site_name, s.region, p.project_name, a.account_type
ORDER BY total_variance DESC;
```

---

## 🔧 **3. Grafana Dashboard Setup**

### **Step 1: Connect to SQL Server**
1. Access Grafana: http://localhost:3000
2. Login: admin/admin
3. Go to **Configuration** → **Data Sources**
4. Add **Microsoft SQL Server**:
```
Host: sqlserver:1433
Database: PTXYZ_DataWarehouse
User: sa  
Password: PTXYZSecure123!
```

### **Step 2: Create Dashboard Panels**

#### **Equipment Efficiency Panel**
```sql
SELECT 
    $__time(t.date),
    e.equipment_type as metric,
    AVG(f.efficiency_ratio) * 100 as efficiency_percentage
FROM fact.FactEquipmentUsage f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimEquipment e ON f.equipment_key = e.equipment_key
WHERE $__timeFilter(t.date)
GROUP BY t.date, e.equipment_type
ORDER BY t.date
```

#### **Production Trends Panel**
```sql
SELECT 
    $__time(t.date),
    s.site_name as metric,
    SUM(f.produced_volume) as production_volume
FROM fact.FactProduction f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimSite s ON f.site_key = s.site_key
WHERE $__timeFilter(t.date)
GROUP BY t.date, s.site_name
ORDER BY t.date
```

#### **Cost Variance Gauge**
```sql
SELECT 
    AVG(f.variance_percentage) as variance_pct
FROM fact.FactFinancialTransaction f
JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE t.year = YEAR(GETDATE())
```

---

## 📈 **4. Apache Superset Dashboard Setup**

### **Step 1: Database Connection**
1. Access Superset: http://localhost:8088
2. Login: admin/admin
3. **Settings** → **Database Connections** → **+ DATABASE**
4. Choose **Microsoft SQL Server**
5. SQLAlchemy URI:
```
mssql+pymssql://sa:PTXYZSecure123!@sqlserver:1433/PTXYZ_DataWarehouse
```

### **Step 2: Create Datasets**
Add these key datasets:
- `fact.FactEquipmentUsage`
- `fact.FactProduction`
- `fact.FactFinancialTransaction`
- `dim.DimSite`
- `dim.DimTime`
- `dim.DimEquipment`
- `dim.DimMaterial`

### **Step 3: Build Charts**

#### **Equipment Utilization Chart**
- **Chart Type**: Time Series Line Chart
- **Dataset**: fact.FactEquipmentUsage
- **Metrics**: AVG(efficiency_ratio)
- **Group By**: equipment_type
- **Time Column**: date (from dim.DimTime)

#### **Production by Material Pie Chart**
- **Chart Type**: Pie Chart
- **Dataset**: fact.FactProduction
- **Metrics**: SUM(produced_volume)
- **Group By**: material_type (from dim.DimMaterial)

#### **Budget Variance Bar Chart**
- **Chart Type**: Bar Chart
- **Dataset**: fact.FactFinancialTransaction
- **Metrics**: SUM(variance_amount)
- **Group By**: project_name (from dim.DimProject)

---

## 🔍 **5. Metabase Quick Setup**

### **Step 1: Initial Configuration**
1. Access Metabase: http://localhost:3001
2. Complete setup wizard
3. Add SQL Server database:
```
Host: sqlserver
Port: 1433
Database: PTXYZ_DataWarehouse
Username: sa
Password: PTXYZSecure123!
```

### **Step 2: Auto-Generated Dashboards**
Metabase will auto-scan and create:
- **Equipment Usage Overview**
- **Production Metrics**
- **Financial Performance**
- **Site Comparisons**

---

## 📊 **6. Advanced OLAP Queries**

### **Equipment Performance OLAP Cube**
```sql
SELECT 
    t.year,
    t.quarter,
    t.month,
    e.equipment_type,
    s.site_name,
    SUM(f.operating_hours) as total_operating_hours,
    AVG(f.efficiency_ratio) as avg_efficiency,
    SUM(f.fuel_consumption) as total_fuel,
    SUM(f.maintenance_cost) as total_maintenance_cost
FROM fact.FactEquipmentUsage f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimEquipment e ON f.equipment_key = e.equipment_key
JOIN dim.DimSite s ON f.site_key = s.site_key
GROUP BY ROLLUP(t.year, t.quarter, t.month, e.equipment_type, s.site_name)
ORDER BY t.year, t.quarter, t.month;
```

### **Production Drill-Down Analysis**
```sql
SELECT 
    s.region,
    s.site_name,
    m.material_type,
    t.year,
    t.quarter,
    SUM(f.produced_volume) as total_production,
    AVG(f.unit_cost) as avg_unit_cost,
    SUM(f.total_cost) as total_cost
FROM fact.FactProduction f
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimMaterial m ON f.material_key = m.material_key
JOIN dim.DimTime t ON f.time_key = t.time_key
GROUP BY ROLLUP(s.region, s.site_name, m.material_type, t.year, t.quarter)
ORDER BY s.region, s.site_name, m.material_type;
```

---

## 🎯 **7. Key Performance Indicators (KPI)**

### **Real-Time KPI Dashboard Query**
```sql
WITH CurrentMonth AS (
    SELECT time_key 
    FROM dim.DimTime 
    WHERE year = YEAR(GETDATE()) 
    AND month = MONTH(GETDATE())
)
SELECT 
    'Equipment Efficiency' as KPI,
    CAST(AVG(f.efficiency_ratio) * 100 AS DECIMAL(5,2)) as Value,
    '%' as Unit
FROM fact.FactEquipmentUsage f
WHERE f.time_key IN (SELECT time_key FROM CurrentMonth)

UNION ALL

SELECT 
    'Total Production' as KPI,
    CAST(SUM(f.produced_volume) AS DECIMAL(12,2)) as Value,
    'Tons' as Unit
FROM fact.FactProduction f
WHERE f.time_key IN (SELECT time_key FROM CurrentMonth)

UNION ALL

SELECT 
    'Budget Variance' as KPI,
    CAST(AVG(f.variance_percentage) AS DECIMAL(5,2)) as Value,
    '%' as Unit
FROM fact.FactFinancialTransaction f
WHERE f.time_key IN (SELECT time_key FROM CurrentMonth);
```

---

## 🔧 **8. Troubleshooting**

### **Common Issues & Fixes:**

#### **Column Name Errors:**
- ✅ Use `maintenance_cost` (not `maintenance_hours`)
- ✅ Use `produced_volume` (not `tonnage_produced`)
- ✅ Use `efficiency_ratio` (calculated field)
- ✅ Use `variance_amount` (not `transaction_amount`)

#### **Connection Issues:**
```bash
# Check SQL Server status
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'PTXYZSecure123!' -Q "SELECT 1" -C -N

# Restart services if needed
docker compose restart sqlserver
```

#### **Data Validation:**
```sql
-- Check table row counts
SELECT 'FactEquipmentUsage' as TableName, COUNT(*) as RowCount FROM fact.FactEquipmentUsage
UNION ALL
SELECT 'FactProduction', COUNT(*) FROM fact.FactProduction
UNION ALL
SELECT 'FactFinancialTransaction', COUNT(*) FROM fact.FactFinancialTransaction;
```

---

## 📈 **9. Dashboard Best Practices**

### **Performance Optimization:**
- Use date filters to limit data ranges
- Create indexes on frequently queried columns
- Use aggregated views for complex calculations
- Implement proper caching strategies

### **Visual Design:**
- Group related metrics together
- Use consistent color schemes
- Implement drill-down capabilities
- Add contextual filters

### **User Experience:**
- Create role-based dashboards
- Implement automated refresh schedules
- Add data quality indicators
- Provide export capabilities

---

## 🚀 **10. Next Steps**

1. **Test All Queries**: Run corrected queries to verify data
2. **Create Dashboards**: Build visualizations in each platform
3. **Set Up Alerts**: Configure monitoring and notifications
4. **User Training**: Provide dashboard usage training
5. **Performance Tuning**: Optimize queries and indexes

---

**✅ Your PT XYZ Data Warehouse dashboards are now ready with schema-aligned queries!**

**🎯 Start with Grafana for operational monitoring and Superset for business analytics.**
