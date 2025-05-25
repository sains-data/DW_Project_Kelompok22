#!/usr/bin/env python3
"""
PT XYZ Data Warehouse - Interactive Dashboard Creation Guide
===========================================================
This script provides an interactive step-by-step guide for creating
dashboards in Grafana, Superset, and Metabase using the corrected queries.
"""

import os
import json
import subprocess
import webbrowser
from time import sleep

class DashboardCreationGuide:
    def __init__(self):
        self.base_dir = "/home/egistr/Documents/kuliah/semester6/dw/DW_Project_Kelompok22"
        self.dashboard_urls = {
            "grafana": "http://localhost:3000",
            "superset": "http://localhost:8088", 
            "metabase": "http://localhost:3001",
            "jupyter": "http://localhost:8888"
        }
        
    def print_header(self, title):
        print(f"\n{'='*60}")
        print(f"🚀 {title}")
        print(f"{'='*60}")
        
    def print_step(self, step_num, description):
        print(f"\n📝 Step {step_num}: {description}")
        print("-" * 50)
        
    def wait_for_user(self, message="Press Enter to continue..."):
        input(f"\n⏸️  {message}")
        
    def open_url(self, platform):
        url = self.dashboard_urls[platform]
        print(f"🌐 Opening {platform.title()} at {url}")
        try:
            webbrowser.open(url)
        except:
            print(f"Please manually open: {url}")
            
    def show_sql_query(self, query_name, query_content):
        print(f"\n📋 {query_name}:")
        print("```sql")
        print(query_content)
        print("```")
        
    def grafana_setup_guide(self):
        self.print_header("GRAFANA DASHBOARD SETUP")
        
        self.print_step(1, "Open Grafana and Login")
        print("• URL: http://localhost:3000")
        print("• Username: admin")
        print("• Password: admin")
        print("• Change password when prompted (or skip)")
        self.open_url("grafana")
        self.wait_for_user("Complete Grafana login and press Enter")
        
        self.print_step(2, "Add SQL Server Data Source")
        print("• Click 'Add your first data source'")
        print("• Select 'Microsoft SQL Server'")
        print("• Configure connection:")
        print("  - Host: sqlserver:1433")
        print("  - Database: PTXYZ_DataWarehouse")
        print("  - User: sa")
        print("  - Password: PTXYZSecure123!")
        print("  - Encrypt: false")
        print("• Click 'Save & Test'")
        self.wait_for_user("Complete data source setup and press Enter")
        
        self.print_step(3, "Create Equipment Utilization Dashboard")
        print("• Click '+' -> Dashboard -> Add visualization")
        print("• Select your SQL Server data source")
        print("• Use this query for Equipment Utilization:")
        
        equipment_query = """
        SELECT 
            e.equipment_type,
            s.site_name,
            COUNT(DISTINCT f.usage_session_id) as usage_sessions,
            AVG(CAST(f.operating_hours as float)) as avg_operating_hours,
            AVG(CAST(f.efficiency_percentage as float)) as avg_efficiency_pct
        FROM FactEquipmentUsage f
        JOIN DimEquipment e ON f.equipment_id = e.equipment_id
        JOIN DimSite s ON f.site_id = s.site_id
        GROUP BY e.equipment_type, s.site_name
        ORDER BY usage_sessions DESC;
        """
        self.show_sql_query("Equipment Utilization", equipment_query)
        
        print("\n• Configure visualization:")
        print("  - Visualization: Table or Bar Chart")
        print("  - Title: 'Equipment Utilization by Type and Site'")
        print("• Save panel")
        self.wait_for_user("Create equipment panel and press Enter")
        
        self.print_step(4, "Create Production Performance Panel")
        production_query = """
        SELECT 
            s.site_name,
            m.material_type,
            SUM(CAST(f.produced_volume as float)) as total_production,
            AVG(CAST(f.unit_cost as float)) as avg_unit_cost
        FROM FactProduction f
        JOIN DimSite s ON f.site_id = s.site_id
        JOIN DimMaterial m ON f.material_id = m.material_id
        GROUP BY s.site_name, m.material_type
        ORDER BY total_production DESC;
        """
        self.show_sql_query("Production Performance", production_query)
        
        print("\n• Add another panel with this query")
        print("• Use Bar Chart visualization")
        print("• Title: 'Production Performance by Site and Material'")
        self.wait_for_user("Create production panel and press Enter")
        
        self.print_step(5, "Create Financial Analysis Panel")
        financial_query = """
        SELECT 
            s.site_name,
            p.project_name,
            SUM(CAST(f.budgeted_amount as float)) as total_budgeted,
            SUM(CAST(f.actual_amount as float)) as total_actual,
            SUM(CAST(f.budgeted_amount as float)) - SUM(CAST(f.actual_amount as float)) as total_variance
        FROM FactFinancial f
        JOIN DimSite s ON f.site_id = s.site_id
        JOIN DimProject p ON f.project_id = p.project_id
        GROUP BY s.site_name, p.project_name
        ORDER BY total_variance DESC;
        """
        self.show_sql_query("Financial Analysis", financial_query)
        
        print("\n• Add financial analysis panel")
        print("• Use Stat or Gauge visualization for variance")
        print("• Save dashboard as 'PT XYZ Operations Dashboard'")
        self.wait_for_user("Complete Grafana dashboard and press Enter")
        
    def superset_setup_guide(self):
        self.print_header("APACHE SUPERSET DASHBOARD SETUP")
        
        self.print_step(1, "Open Superset and Login")
        print("• URL: http://localhost:8088")
        print("• Username: admin")
        print("• Password: admin")
        self.open_url("superset")
        self.wait_for_user("Complete Superset login and press Enter")
        
        self.print_step(2, "Add Database Connection")
        print("• Go to Settings -> Database Connections")
        print("• Click '+ DATABASE'")
        print("• Select 'Microsoft SQL Server'")
        print("• SQLAlchemy URI:")
        print("  mssql+pymssql://sa:PTXYZSecure123!@sqlserver:1433/PTXYZ_DataWarehouse")
        print("• Test connection and save")
        self.wait_for_user("Complete database connection and press Enter")
        
        self.print_step(3, "Create Datasets")
        print("• Go to Data -> Datasets")
        print("• Create datasets for:")
        print("  - FactEquipmentUsage")
        print("  - FactProduction") 
        print("  - FactFinancial")
        print("  - All Dimension tables")
        self.wait_for_user("Create datasets and press Enter")
        
        self.print_step(4, "Create Charts")
        print("• Go to Charts -> + CHART")
        print("• Create charts using the corrected queries")
        print("• Suggested chart types:")
        print("  - Equipment: Bar Chart")
        print("  - Production: Line Chart")
        print("  - Financial: Table with metrics")
        self.wait_for_user("Create charts and press Enter")
        
        self.print_step(5, "Build Dashboard")
        print("• Go to Dashboards -> + DASHBOARD")
        print("• Add your created charts")
        print("• Arrange in logical layout")
        print("• Save as 'PT XYZ Analytics Dashboard'")
        self.wait_for_user("Complete Superset dashboard and press Enter")
        
    def metabase_setup_guide(self):
        self.print_header("METABASE DASHBOARD SETUP")
        
        self.print_step(1, "Complete Metabase Setup")
        print("• URL: http://localhost:3001")
        print("• Complete initial setup wizard")
        print("• Create admin account")
        self.open_url("metabase")
        self.wait_for_user("Complete Metabase setup and press Enter")
        
        self.print_step(2, "Add SQL Server Database")
        print("• Click 'Add a database'")
        print("• Select 'SQL Server'")
        print("• Configuration:")
        print("  - Host: sqlserver")
        print("  - Port: 1433")
        print("  - Database: PTXYZ_DataWarehouse")
        print("  - Username: sa")
        print("  - Password: PTXYZSecure123!")
        self.wait_for_user("Complete database setup and press Enter")
        
        self.print_step(3, "Create Questions (Charts)")
        print("• Click 'Ask a question'")
        print("• Use 'Native query (SQL)' for complex queries")
        print("• Create visualizations using corrected queries")
        print("• Save each question with descriptive names")
        self.wait_for_user("Create questions and press Enter")
        
        self.print_step(4, "Build Dashboard")
        print("• Go to Dashboards -> New dashboard")
        print("• Add your saved questions")
        print("• Arrange and resize as needed")
        print("• Save dashboard")
        self.wait_for_user("Complete Metabase dashboard and press Enter")
        
    def jupyter_analysis_guide(self):
        self.print_header("JUPYTER NOTEBOOK ANALYSIS")
        
        self.print_step(1, "Open Jupyter Lab")
        print("• URL: http://localhost:8888")
        print("• Token: ptxyz123")
        self.open_url("jupyter")
        self.wait_for_user("Access Jupyter and press Enter")
        
        self.print_step(2, "Create Analysis Notebook")
        print("• Create new Python 3 notebook")
        print("• Install required packages:")
        
        notebook_code = '''
# Install packages
!pip install pymssql pandas matplotlib seaborn plotly

# Import libraries
import pymssql
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import plotly.express as px

# Database connection
conn = pymssql.connect(
    server='sqlserver',
    user='sa', 
    password='PTXYZSecure123!',
    database='PTXYZ_DataWarehouse'
)

# Load data using corrected queries
equipment_df = pd.read_sql("""
    SELECT 
        e.equipment_type,
        s.site_name,
        COUNT(DISTINCT f.usage_session_id) as usage_sessions,
        AVG(CAST(f.operating_hours as float)) as avg_operating_hours,
        AVG(CAST(f.efficiency_percentage as float)) as avg_efficiency_pct
    FROM FactEquipmentUsage f
    JOIN DimEquipment e ON f.equipment_id = e.equipment_id
    JOIN DimSite s ON f.site_id = s.site_id
    GROUP BY e.equipment_type, s.site_name
""", conn)

# Create visualizations
plt.figure(figsize=(12, 6))
sns.barplot(data=equipment_df, x='equipment_type', y='avg_operating_hours')
plt.title('Average Operating Hours by Equipment Type')
plt.xticks(rotation=45)
plt.show()
'''
        
        print("Sample notebook code:")
        print("```python")
        print(notebook_code)
        print("```")
        self.wait_for_user("Create Jupyter analysis and press Enter")
        
    def run_complete_guide(self):
        self.print_header("PT XYZ DASHBOARD CREATION - COMPLETE GUIDE")
        
        print("🎯 This guide will walk you through creating dashboards in:")
        print("   1. Grafana (Monitoring & Alerting)")
        print("   2. Superset (Business Intelligence)")
        print("   3. Metabase (User-friendly Analytics)")
        print("   4. Jupyter (Data Science Analysis)")
        
        print("\n📊 All queries have been corrected for schema alignment:")
        print("   ✅ maintenance_hours → maintenance_cost")
        print("   ✅ tonnage_produced → produced_volume")
        print("   ✅ transaction_amount → calculated variance")
        
        choice = input("\nWhich platform would you like to set up? (grafana/superset/metabase/jupyter/all): ").lower()
        
        if choice == "grafana" or choice == "all":
            self.grafana_setup_guide()
            
        if choice == "superset" or choice == "all":
            self.superset_setup_guide()
            
        if choice == "metabase" or choice == "all":
            self.metabase_setup_guide()
            
        if choice == "jupyter" or choice == "all":
            self.jupyter_analysis_guide()
            
        self.print_header("DASHBOARD CREATION COMPLETE!")
        print("🎉 Your PT XYZ Data Warehouse dashboards are ready!")
        print("📊 Access your dashboards at:")
        for platform, url in self.dashboard_urls.items():
            print(f"   {platform.title()}: {url}")
            
        print("\n📋 Next Steps:")
        print("   • Configure alerts in Grafana")
        print("   • Set up user permissions")
        print("   • Schedule data refreshes")
        print("   • Create additional custom visualizations")

if __name__ == "__main__":
    guide = DashboardCreationGuide()
    guide.run_complete_guide()
