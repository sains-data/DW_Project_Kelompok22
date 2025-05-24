#!/bin/bash

# PT XYZ Data Warehouse - Quick Access Script
# Opens all dashboard services in browser

echo "🚀 PT XYZ Data Warehouse - Opening Dashboard Services"
echo "======================================================"

# Function to open URL
open_url() {
    local service=$1
    local url=$2
    local description=$3
    
    echo "🔗 Opening $service: $url"
    echo "   ℹ️  $description"
    
    # Try different methods to open browser
    if command -v xdg-open &> /dev/null; then
        xdg-open "$url" &
    elif command -v open &> /dev/null; then
        open "$url" &
    elif command -v firefox &> /dev/null; then
        firefox "$url" &
    elif command -v google-chrome &> /dev/null; then
        google-chrome "$url" &
    else
        echo "   ⚠️  Please manually open: $url"
    fi
    
    sleep 2
}

echo ""
echo "📊 Opening Visualization Services..."
echo "----------------------------------------"

# Grafana - Primary monitoring dashboard
open_url "Grafana" "http://localhost:3000" "Mining Operations Dashboard (admin/admin)"

# Apache Superset - Advanced analytics
open_url "Apache Superset" "http://localhost:8088" "Advanced Analytics Platform (admin/admin)"

# Metabase - Business intelligence
open_url "Metabase" "http://localhost:3001" "Business Intelligence & Reporting"

# Jupyter Notebooks - Data science
open_url "Jupyter Notebooks" "http://localhost:8888" "Data Science & Analysis Environment"

echo ""
echo "🔧 Opening Management Services..."
echo "----------------------------------------"

# Apache Airflow - ETL orchestration
open_url "Apache Airflow" "http://localhost:8080" "ETL Pipeline Management (admin/admin)"

echo ""
echo "✅ All services opened! Check your browser tabs."
echo ""
echo "🔑 LOGIN CREDENTIALS:"
echo "   • Grafana: admin / admin"
echo "   • Superset: admin / admin" 
echo "   • Airflow: admin / admin"
echo "   • Metabase: Setup required on first access"
echo "   • Jupyter: Token-based authentication"
echo ""
echo "🗄️ DATABASE CONNECTION:"
echo "   • Server: localhost:1433"
echo "   • Database: PTXYZ_DataWarehouse"
echo "   • Username: sa"
echo "   • Password: PTXYZDataWarehouse2025"
echo ""
echo "📋 For detailed information, see:"
echo "   • FINAL_DEPLOYMENT_REPORT.md"
echo "   • DASHBOARD_CONNECTION_GUIDE.json"
echo "   • DASHBOARD_SQL_QUERIES.json"
echo ""
echo "🎉 PT XYZ Data Warehouse is ready for use!"
