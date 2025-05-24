#!/bin/bash
# Advanced Dashboard Configuration with Real Business Intelligence
# PT XYZ Data Warehouse - Advanced Analytics Integration
# Date: 2025-05-24

echo "🚀 PT XYZ Advanced Analytics Dashboard Setup"
echo "============================================="
echo

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📊 Creating Advanced Analytics Dashboards...${NC}"
echo

# 1. Create Executive Dashboard JSON for Grafana
echo "1. Creating Executive Dashboard Configuration..."
cat > /tmp/executive-dashboard.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "PT XYZ Executive Dashboard",
    "tags": ["executive", "kpi", "overview"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Monthly Production Volume",
        "type": "stat",
        "targets": [
          {
            "rawSql": "SELECT SUM(produced_volume) as total_production FROM fact.FactProduction fp JOIN dim.DimTime dt ON fp.time_key = dt.time_key WHERE dt.month = MONTH(GETDATE()) AND dt.year = YEAR(GETDATE())",
            "format": "table"
          }
        ],
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Equipment Efficiency Trend",
        "type": "timeseries",
        "targets": [
          {
            "rawSql": "SELECT dt.date, AVG(feu.efficiency_ratio) as avg_efficiency FROM fact.FactEquipmentUsage feu JOIN dim.DimTime dt ON feu.time_key = dt.time_key WHERE dt.date >= DATEADD(month, -3, GETDATE()) GROUP BY dt.date ORDER BY dt.date",
            "format": "time_series"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 6, "y": 0}
      },
      {
        "id": 3,
        "title": "Budget vs Actual Spending",
        "type": "bargauge",
        "targets": [
          {
            "rawSql": "SELECT 'Budget' as metric, SUM(budgeted_cost) as value FROM fact.FactFinancialTransaction UNION ALL SELECT 'Actual' as metric, SUM(actual_cost) as value FROM fact.FactFinancialTransaction",
            "format": "table"
          }
        ],
        "gridPos": {"h": 8, "w": 6, "x": 18, "y": 0}
      },
      {
        "id": 4,
        "title": "Site Performance Heatmap",
        "type": "heatmap",
        "targets": [
          {
            "rawSql": "SELECT ds.site_name, dt.month_name, AVG(feu.efficiency_ratio) as efficiency FROM fact.FactEquipmentUsage feu JOIN dim.DimSite ds ON feu.site_key = ds.site_key JOIN dim.DimTime dt ON feu.time_key = dt.time_key WHERE dt.year = YEAR(GETDATE()) GROUP BY ds.site_name, dt.month_name",
            "format": "table"
          }
        ],
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
      }
    ],
    "time": {
      "from": "now-90d",
      "to": "now"
    },
    "refresh": "30s"
  }
}
EOF

# 2. Create Operations Dashboard JSON
echo "2. Creating Real-Time Operations Dashboard..."
cat > /tmp/operations-dashboard.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "PT XYZ Real-Time Operations",
    "tags": ["operations", "realtime", "monitoring"],
    "panels": [
      {
        "id": 1,
        "title": "Active Equipment Status",
        "type": "table",
        "targets": [
          {
            "rawSql": "SELECT de.equipment_name, de.equipment_type, ds.site_name, AVG(feu.efficiency_ratio) as current_efficiency, SUM(feu.operating_hours) as operating_hours, SUM(feu.downtime_hours) as downtime_hours FROM fact.FactEquipmentUsage feu JOIN dim.DimEquipment de ON feu.equipment_key = de.equipment_key JOIN dim.DimSite ds ON feu.site_key = ds.site_key JOIN dim.DimTime dt ON feu.time_key = dt.time_key WHERE dt.date >= DATEADD(day, -7, GETDATE()) GROUP BY de.equipment_name, de.equipment_type, ds.site_name",
            "format": "table"
          }
        ],
        "gridPos": {"h": 10, "w": 24, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Production Rate by Hour",
        "type": "timeseries",
        "targets": [
          {
            "rawSql": "SELECT dt.date, DATEPART(hour, dt.date) as hour, SUM(fp.produced_volume) as hourly_production FROM fact.FactProduction fp JOIN dim.DimTime dt ON fp.time_key = dt.time_key WHERE dt.date >= DATEADD(day, -1, GETDATE()) GROUP BY dt.date, DATEPART(hour, dt.date) ORDER BY dt.date",
            "format": "time_series"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 10}
      },
      {
        "id": 3,
        "title": "Maintenance Alerts",
        "type": "stat",
        "targets": [
          {
            "rawSql": "SELECT COUNT(*) as high_maintenance_items FROM fact.FactEquipmentUsage feu JOIN dim.DimTime dt ON feu.time_key = dt.time_key WHERE dt.date >= DATEADD(day, -7, GETDATE()) AND feu.maintenance_cost > (SELECT AVG(maintenance_cost) * 1.5 FROM fact.FactEquipmentUsage)",
            "format": "table"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 10}
      }
    ],
    "refresh": "10s"
  }
}
EOF

# 3. Create Financial Analytics Dashboard
echo "3. Creating Financial Analytics Dashboard..."
cat > /tmp/financial-dashboard.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "PT XYZ Financial Analytics",
    "tags": ["financial", "budget", "costs"],
    "panels": [
      {
        "id": 1,
        "title": "Cost Center Analysis",
        "type": "piechart",
        "targets": [
          {
            "rawSql": "SELECT da.account_type, SUM(fft.actual_cost) as total_cost FROM fact.FactFinancialTransaction fft JOIN dim.DimAccount da ON fft.account_key = da.account_key GROUP BY da.account_type",
            "format": "table"
          }
        ],
        "gridPos": {"h": 8, "w": 8, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Budget Variance by Month",
        "type": "timeseries",
        "targets": [
          {
            "rawSql": "SELECT dt.date, SUM(fft.budgeted_cost) as budget, SUM(fft.actual_cost) as actual FROM fact.FactFinancialTransaction fft JOIN dim.DimTime dt ON fft.time_key = dt.time_key WHERE dt.year = YEAR(GETDATE()) GROUP BY dt.date ORDER BY dt.date",
            "format": "time_series"
          }
        ],
        "gridPos": {"h": 8, "w": 16, "x": 8, "y": 0}
      },
      {
        "id": 3,
        "title": "Site-wise Cost Analysis",
        "type": "bargauge",
        "targets": [
          {
            "rawSql": "SELECT ds.site_name, SUM(fft.actual_cost) as site_cost FROM fact.FactFinancialTransaction fft JOIN dim.DimSite ds ON fft.site_key = ds.site_key GROUP BY ds.site_name ORDER BY site_cost DESC",
            "format": "table"
          }
        ],
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
      }
    ]
  }
}
EOF

# 4. Upload dashboards to Grafana
echo "4. Uploading dashboards to Grafana..."

# Wait for Grafana to be ready
echo "Waiting for Grafana to be ready..."
timeout 30 bash -c 'until curl -s http://localhost:3000/api/health >/dev/null; do sleep 1; done'

if curl -s http://localhost:3000/api/health | grep -q "ok"; then
    echo "✅ Grafana is ready"
    
    # Upload Executive Dashboard
    echo "Uploading Executive Dashboard..."
    curl -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer admin" \
        -d @/tmp/executive-dashboard.json \
        http://admin:admin@localhost:3000/api/dashboards/db
    
    # Upload Operations Dashboard  
    echo "Uploading Operations Dashboard..."
    curl -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer admin" \
        -d @/tmp/operations-dashboard.json \
        http://admin:admin@localhost:3000/api/dashboards/db
    
    # Upload Financial Dashboard
    echo "Uploading Financial Dashboard..."
    curl -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer admin" \
        -d @/tmp/financial-dashboard.json \
        http://admin:admin@localhost:3000/api/dashboards/db
    
    echo "✅ Advanced dashboards uploaded to Grafana"
else
    echo "❌ Grafana is not responding"
fi

# 5. Create Jupyter Advanced Analytics Notebook
echo
echo "5. Creating Advanced Analytics Jupyter Notebook..."

cat > /tmp/advanced_analytics.ipynb << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# PT XYZ Data Warehouse - Advanced Analytics\n",
    "## Predictive Analytics and Business Intelligence\n",
    "\n",
    "This notebook provides advanced analytics capabilities for the PT XYZ Data Warehouse including:\n",
    "- Predictive modeling\n",
    "- Trend analysis\n",
    "- Cost optimization insights\n",
    "- Performance forecasting"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "from sqlalchemy import create_engine\n",
    "import warnings\n",
    "warnings.filterwarnings('ignore')\n",
    "\n",
    "# Database connection\n",
    "connection_string = 'mssql+pyodbc://sa:YourSecurePassword123!@sqlserver:1433/PTXYZ_DataWarehouse?driver=ODBC+Driver+17+for+SQL+Server'\n",
    "engine = create_engine(connection_string)\n",
    "\n",
    "print('📊 Advanced Analytics Environment Ready!')"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 1. Equipment Performance Predictive Analysis"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Load equipment performance data\n",
    "equipment_query = \"\"\"\n",
    "SELECT \n",
    "    de.equipment_name,\n",
    "    de.equipment_type,\n",
    "    dt.date,\n",
    "    feu.efficiency_ratio,\n",
    "    feu.operating_hours,\n",
    "    feu.downtime_hours,\n",
    "    feu.maintenance_cost,\n",
    "    feu.fuel_consumption\n",
    "FROM fact.FactEquipmentUsage feu\n",
    "JOIN dim.DimEquipment de ON feu.equipment_key = de.equipment_key\n",
    "JOIN dim.DimTime dt ON feu.time_key = dt.time_key\n",
    "WHERE dt.year >= 2024\n",
    "ORDER BY de.equipment_name, dt.date\n",
    "\"\"\"\n",
    "\n",
    "equipment_df = pd.read_sql(equipment_query, engine)\n",
    "equipment_df['date'] = pd.to_datetime(equipment_df['date'])\n",
    "\n",
    "print(f'📈 Loaded {len(equipment_df)} equipment performance records')\n",
    "equipment_df.head()"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 2. Production Efficiency Trends"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Production efficiency analysis\n",
    "production_query = \"\"\"\n",
    "SELECT \n",
    "    ds.site_name,\n",
    "    dm.material_name,\n",
    "    dt.date,\n",
    "    dt.month_name,\n",
    "    fp.produced_volume,\n",
    "    fp.unit_cost,\n",
    "    fp.total_cost\n",
    "FROM fact.FactProduction fp\n",
    "JOIN dim.DimSite ds ON fp.site_key = ds.site_key\n",
    "JOIN dim.DimMaterial dm ON fp.material_key = dm.material_key\n",
    "JOIN dim.DimTime dt ON fp.time_key = dt.time_key\n",
    "WHERE dt.year >= 2024\n",
    "ORDER BY ds.site_name, dt.date\n",
    "\"\"\"\n",
    "\n",
    "production_df = pd.read_sql(production_query, engine)\n",
    "production_df['date'] = pd.to_datetime(production_df['date'])\n",
    "\n",
    "# Calculate production efficiency metrics\n",
    "production_df['efficiency_ratio'] = production_df['produced_volume'] / production_df['total_cost']\n",
    "\n",
    "print(f'🏭 Loaded {len(production_df)} production records')\n",
    "production_df.head()"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 3. Financial Performance Analysis"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Financial performance visualization\n",
    "plt.figure(figsize=(15, 10))\n",
    "\n",
    "# Equipment efficiency trends\n",
    "plt.subplot(2, 2, 1)\n",
    "monthly_efficiency = equipment_df.groupby(equipment_df['date'].dt.to_period('M'))['efficiency_ratio'].mean()\n",
    "monthly_efficiency.plot(kind='line', title='Monthly Equipment Efficiency Trend')\n",
    "plt.ylabel('Efficiency Ratio')\n",
    "\n",
    "# Production volume by site\n",
    "plt.subplot(2, 2, 2)\n",
    "site_production = production_df.groupby('site_name')['produced_volume'].sum().sort_values(ascending=False)\n",
    "site_production.head(10).plot(kind='bar', title='Top 10 Sites by Production Volume')\n",
    "plt.xticks(rotation=45)\n",
    "\n",
    "# Cost efficiency scatter\n",
    "plt.subplot(2, 2, 3)\n",
    "plt.scatter(production_df['total_cost'], production_df['produced_volume'], alpha=0.6)\n",
    "plt.xlabel('Total Cost')\n",
    "plt.ylabel('Produced Volume')\n",
    "plt.title('Cost vs Production Volume')\n",
    "\n",
    "# Equipment type performance\n",
    "plt.subplot(2, 2, 4)\n",
    "equipment_performance = equipment_df.groupby('equipment_type')['efficiency_ratio'].mean().sort_values(ascending=False)\n",
    "equipment_performance.plot(kind='bar', title='Average Efficiency by Equipment Type')\n",
    "plt.xticks(rotation=45)\n",
    "\n",
    "plt.tight_layout()\n",
    "plt.show()\n",
    "\n",
    "print('📊 Advanced Analytics Visualizations Generated!')"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 4. Predictive Modeling for Maintenance"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Simple predictive model for maintenance costs\n",
    "from sklearn.linear_model import LinearRegression\n",
    "from sklearn.model_selection import train_test_split\n",
    "from sklearn.metrics import mean_squared_error, r2_score\n",
    "\n",
    "# Prepare data for modeling\n",
    "model_data = equipment_df.dropna()\n",
    "features = ['operating_hours', 'downtime_hours', 'fuel_consumption', 'efficiency_ratio']\n",
    "target = 'maintenance_cost'\n",
    "\n",
    "X = model_data[features]\n",
    "y = model_data[target]\n",
    "\n",
    "# Split data\n",
    "X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)\n",
    "\n",
    "# Train model\n",
    "model = LinearRegression()\n",
    "model.fit(X_train, y_train)\n",
    "\n",
    "# Predictions\n",
    "y_pred = model.predict(X_test)\n",
    "\n",
    "# Model performance\n",
    "mse = mean_squared_error(y_test, y_pred)\n",
    "r2 = r2_score(y_test, y_pred)\n",
    "\n",
    "print(f'🤖 Predictive Model Performance:')\n",
    "print(f'   Mean Squared Error: {mse:.2f}')\n",
    "print(f'   R² Score: {r2:.3f}')\n",
    "print(f'   Model can explain {r2*100:.1f}% of maintenance cost variation')\n",
    "\n",
    "# Feature importance\n",
    "feature_importance = pd.DataFrame({\n",
    "    'feature': features,\n",
    "    'importance': abs(model.coef_)\n",
    "}).sort_values('importance', ascending=False)\n",
    "\n",
    "print('\\n📈 Feature Importance for Maintenance Cost Prediction:')\n",
    "print(feature_importance)"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

# Copy notebook to Jupyter container
echo "Copying advanced analytics notebook to Jupyter..."
docker cp /tmp/advanced_analytics.ipynb ptxyz_jupyter:/home/jovyan/work/

echo
echo "📊 Advanced Analytics Dashboard Setup Complete!"
echo "=============================================="
echo
echo "🌐 Access Your Advanced Dashboards:"
echo "   • Grafana Executive Dashboard: http://localhost:3000/d/executive"
echo "   • Grafana Operations Dashboard: http://localhost:3000/d/operations"  
echo "   • Grafana Financial Analytics: http://localhost:3000/d/financial"
echo "   • Jupyter Advanced Analytics: http://localhost:8888/notebooks/advanced_analytics.ipynb"
echo
echo "🎯 New Features Available:"
echo "   ✅ Executive KPI Dashboard with real-time metrics"
echo "   ✅ Real-time operational monitoring"
echo "   ✅ Financial analytics with budget variance tracking"
echo "   ✅ Predictive analytics in Jupyter notebook"
echo "   ✅ Equipment maintenance forecasting"
echo
echo "🚀 Your data warehouse now has enterprise-grade analytics capabilities!"
