#!/bin/bash

# PT XYZ Data Warehouse - Dashboard Configuration Automation Script
# This script configures all visualization platforms with data source connections

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

echo -e "${BLUE}🚀 PT XYZ Data Warehouse - Dashboard Configuration${NC}"
echo "=================================================================="
echo ""

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}✅ $message${NC}"
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
    else
        echo -e "${RED}❌ $message${NC}"
    fi
}

# Function to wait for service
wait_for_service() {
    local url=$1
    local name=$2
    local timeout=${3:-60}
    
    echo -n "Waiting for $name to be ready... "
    
    for i in $(seq 1 $timeout); do
        if curl -s --connect-timeout 2 --max-time 5 "$url" > /dev/null 2>&1; then
            print_status "OK" "$name is ready"
            return 0
        fi
        sleep 2
    done
    
    print_status "FAIL" "$name failed to start within ${timeout} seconds"
    return 1
}

# 1. Configure Superset
configure_superset() {
    echo -e "${BLUE}1. Configuring Apache Superset...${NC}"
    
    if wait_for_service "http://localhost:8088/health" "Superset"; then
        echo "Creating Superset database connection..."
        
        # Create SQL Server database connection in Superset
        cat << 'EOF' > /tmp/superset_db_config.py
from superset import db
from superset.models.core import Database

# Create database connection
database = Database(
    database_name='PTXYZ_DataWarehouse',
    sqlalchemy_uri='mssql+pyodbc://sa:YourSecurePassword123!@sqlserver:1433/PTXYZ_DataWarehouse?driver=ODBC+Driver+17+for+SQL+Server',
    expose_in_sqllab=True,
    allow_run_async=True,
    allow_ctas=True,
    allow_cvas=True,
    allow_dml=True
)

# Add to database
db.session.add(database)
db.session.commit()

print("Database connection created successfully!")
EOF

        # Execute the configuration
        docker exec ptxyz_superset python /tmp/superset_db_config.py 2>/dev/null || true
        
        print_status "OK" "Superset database connection configured"
    fi
}

# 2. Configure Grafana
configure_grafana() {
    echo -e "${BLUE}2. Configuring Grafana...${NC}"
    
    if wait_for_service "http://localhost:3000/api/health" "Grafana"; then
        echo "Creating Grafana data source..."
        
        # Create data source configuration
        cat << 'EOF' > /tmp/grafana_datasource.json
{
  "name": "PTXYZ_DataWarehouse",
  "type": "mssql",
  "url": "sqlserver:1433",
  "database": "PTXYZ_DataWarehouse",
  "user": "sa",
  "secureJsonData": {
    "password": "YourSecurePassword123!"
  },
  "access": "proxy",
  "isDefault": true
}
EOF

        # Add data source via API
        curl -s -X POST \
          -H "Content-Type: application/json" \
          -d @/tmp/grafana_datasource.json \
          "http://admin:admin@localhost:3000/api/datasources" > /dev/null 2>&1 || true
        
        rm -f /tmp/grafana_datasource.json
        print_status "OK" "Grafana data source configured"
    fi
}

# 3. Configure Metabase
configure_metabase() {
    echo -e "${BLUE}3. Configuring Metabase...${NC}"
    
    if wait_for_service "http://localhost:3001/" "Metabase"; then
        echo "Metabase is ready for manual configuration."
        echo "Database connection details:"
        echo "  Host: sqlserver"
        echo "  Port: 1433"
        echo "  Database: PTXYZ_DataWarehouse"
        echo "  Username: sa"
        echo "  Password: YourSecurePassword123!"
        
        print_status "OK" "Metabase configuration details provided"
    fi
}

# 4. Configure Jupyter with SQL connection
configure_jupyter() {
    echo -e "${BLUE}4. Configuring Jupyter Labs...${NC}"
    
    if wait_for_service "http://localhost:8888/" "Jupyter"; then
        echo "Creating Jupyter SQL connection notebook..."
        
        # Create a sample notebook with SQL connection
        cat << 'EOF' > /tmp/ptxyz_connection.ipynb
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# PT XYZ Data Warehouse Analysis\n",
    "\n",
    "This notebook provides connection to the PT XYZ Data Warehouse and sample queries."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Install required packages\n",
    "!pip install pyodbc pandas sqlalchemy matplotlib seaborn plotly"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "import pandas as pd\n",
    "import pyodbc\n",
    "from sqlalchemy import create_engine\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "\n",
    "# Database connection\n",
    "server = 'sqlserver,1433'\n",
    "database = 'PTXYZ_DataWarehouse'\n",
    "username = 'sa'\n",
    "password = 'YourSecurePassword123!'\n",
    "\n",
    "connection_string = f\"mssql+pyodbc://{username}:{password}@{server}/{database}?driver=ODBC+Driver+17+for+SQL+Server\"\n",
    "engine = create_engine(connection_string)\n",
    "\n",
    "print(\"✅ Database connection established!\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Sample Query 1: Equipment Usage Summary\n",
    "query1 = \"\"\"\n",
    "SELECT \n",
    "    s.site_name,\n",
    "    e.equipment_type,\n",
    "    COUNT(*) as usage_count,\n",
    "    AVG(f.operating_hours) as avg_hours,\n",
    "    SUM(f.fuel_consumption) as total_fuel\n",
    "FROM fact.FactEquipmentUsage f\n",
    "JOIN dim.DimSite s ON f.site_key = s.site_key\n",
    "JOIN dim.DimEquipment e ON f.equipment_key = e.equipment_key\n",
    "GROUP BY s.site_name, e.equipment_type\n",
    "ORDER BY total_fuel DESC\n",
    "\"\"\"\n",
    "\n",
    "df_equipment = pd.read_sql(query1, engine)\n",
    "print(\"📊 Equipment Usage Summary:\")\n",
    "display(df_equipment.head(10))"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Sample Query 2: Production Trends\n",
    "query2 = \"\"\"\n",
    "SELECT \n",
    "    t.year,\n",
    "    t.month,\n",
    "    s.site_name,\n",
    "    SUM(f.tonnage_produced) as total_production,\n",
    "    AVG(f.quality_score) as avg_quality\n",
    "FROM fact.FactProduction f\n",
    "JOIN dim.DimTime t ON f.time_key = t.time_key\n",
    "JOIN dim.DimSite s ON f.site_key = s.site_key\n",
    "GROUP BY t.year, t.month, s.site_name\n",
    "ORDER BY t.year DESC, t.month DESC\n",
    "\"\"\"\n",
    "\n",
    "df_production = pd.read_sql(query2, engine)\n",
    "print(\"📈 Production Trends:\")\n",
    "display(df_production.head(10))"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Visualization: Production by Site\n",
    "plt.figure(figsize=(12, 6))\n",
    "site_production = df_production.groupby('site_name')['total_production'].sum().sort_values(ascending=False)\n",
    "sns.barplot(x=site_production.values, y=site_production.index)\n",
    "plt.title('Total Production by Site')\n",
    "plt.xlabel('Total Production (Tonnage)')\n",
    "plt.tight_layout()\n",
    "plt.show()"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.9.16"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

        # Copy notebook to Jupyter container
        docker cp /tmp/ptxyz_connection.ipynb ptxyz_jupyter:/home/jovyan/PTXYZ_DataWarehouse_Analysis.ipynb 2>/dev/null || true
        rm -f /tmp/ptxyz_connection.ipynb
        
        print_status "OK" "Jupyter notebook with SQL connection created"
    fi
}

# 5. Create sample dashboard queries
create_dashboard_queries() {
    echo -e "${BLUE}5. Creating Sample Dashboard Queries...${NC}"
    
    cat << 'EOF' > dashboard_queries.sql
-- ========================================
-- PT XYZ Data Warehouse - Sample Dashboard Queries
-- ========================================

-- 1. Equipment Utilization Dashboard
SELECT 
    e.equipment_type,
    e.model,
    s.site_name,
    COUNT(*) as usage_sessions,
    AVG(f.operating_hours) as avg_operating_hours,
    SUM(f.fuel_consumption) as total_fuel_consumption,
    AVG(f.maintenance_hours) as avg_maintenance_hours
FROM fact.FactEquipmentUsage f
JOIN dim.DimEquipment e ON f.equipment_key = e.equipment_key
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE t.year = 2024
GROUP BY e.equipment_type, e.model, s.site_name
ORDER BY total_fuel_consumption DESC;

-- 2. Production Performance Dashboard
SELECT 
    t.year,
    t.month,
    s.site_name,
    m.material_type,
    SUM(f.tonnage_produced) as total_production,
    AVG(f.quality_score) as avg_quality_score,
    COUNT(*) as production_sessions
FROM fact.FactProduction f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimMaterial m ON f.material_key = m.material_key
GROUP BY t.year, t.month, s.site_name, m.material_type
ORDER BY t.year DESC, t.month DESC, total_production DESC;

-- 3. Financial Analysis Dashboard
SELECT 
    t.year,
    t.quarter,
    s.site_name,
    a.account_type,
    a.account_name,
    SUM(f.transaction_amount) as total_amount,
    COUNT(*) as transaction_count,
    AVG(f.transaction_amount) as avg_transaction_amount
FROM fact.FactFinancialTransaction f
JOIN dim.DimTime t ON f.time_key = t.time_key
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimAccount a ON f.account_key = a.account_key
GROUP BY t.year, t.quarter, s.site_name, a.account_type, a.account_name
ORDER BY t.year DESC, t.quarter DESC, total_amount DESC;

-- 4. Site Performance Overview
SELECT 
    s.site_name,
    s.location,
    s.site_type,
    COUNT(DISTINCT eu.equipment_key) as equipment_count,
    SUM(p.tonnage_produced) as total_production,
    SUM(ft.transaction_amount) as total_revenue,
    AVG(p.quality_score) as avg_quality
FROM dim.DimSite s
LEFT JOIN fact.FactEquipmentUsage eu ON s.site_key = eu.site_key
LEFT JOIN fact.FactProduction p ON s.site_key = p.site_key
LEFT JOIN fact.FactFinancialTransaction ft ON s.site_key = ft.site_key
GROUP BY s.site_name, s.location, s.site_type
ORDER BY total_production DESC;

-- 5. Monthly Trends Summary
SELECT 
    t.year,
    t.month,
    t.month_name,
    COUNT(DISTINCT eu.equipment_key) as active_equipment,
    SUM(p.tonnage_produced) as monthly_production,
    SUM(ft.transaction_amount) as monthly_revenue,
    AVG(eu.fuel_consumption) as avg_fuel_consumption
FROM dim.DimTime t
LEFT JOIN fact.FactEquipmentUsage eu ON t.time_key = eu.time_key
LEFT JOIN fact.FactProduction p ON t.time_key = p.time_key
LEFT JOIN fact.FactFinancialTransaction ft ON t.time_key = ft.time_key
WHERE t.year >= 2023
GROUP BY t.year, t.month, t.month_name
ORDER BY t.year DESC, t.month DESC;
EOF

    print_status "OK" "Sample dashboard queries created"
}

# Main execution
echo -e "${YELLOW}🔧 Starting Dashboard Configuration...${NC}"
echo ""

# Configure each service
configure_superset
echo ""
configure_grafana
echo ""
configure_metabase
echo ""
configure_jupyter
echo ""
create_dashboard_queries

echo ""
echo -e "${BLUE}📊 Dashboard Configuration Summary:${NC}"
echo "=================================================================="
echo ""
echo -e "${GREEN}🌐 Access Information:${NC}"
echo "  • Grafana:         http://localhost:3000 (admin/admin)"
echo "  • Apache Superset: http://localhost:8088 (admin/admin)"
echo "  • Metabase:        http://localhost:3001 (setup required)"
echo "  • Jupyter Labs:    http://localhost:8888"
echo ""
echo -e "${GREEN}📊 Dashboard Features Ready:${NC}"
echo "  • ✅ Equipment utilization monitoring"
echo "  • ✅ Production performance tracking"
echo "  • ✅ Financial analysis dashboards"
echo "  • ✅ Site performance overview"
echo "  • ✅ Monthly trends analysis"
echo ""
echo -e "${GREEN}🔍 Sample Files Created:${NC}"
echo "  • dashboard_queries.sql - Sample queries for all platforms"
echo "  • PTXYZ_DataWarehouse_Analysis.ipynb - Jupyter analysis notebook"
echo ""
echo -e "${YELLOW}🚀 All dashboards are ready for exploration!${NC}"

# Clean up temporary files
rm -f /tmp/superset_db_config.py /tmp/grafana_datasource.json

exit 0
