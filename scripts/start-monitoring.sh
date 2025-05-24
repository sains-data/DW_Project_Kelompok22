#!/bin/bash
# Start PT XYZ Data Warehouse Monitoring System

echo "🔍 Starting PT XYZ Data Warehouse Monitoring System"
echo "==================================================="

# Install required Python packages
echo "Installing monitoring dependencies..."
pip3 install psutil requests > /dev/null 2>&1

# Start monitoring dashboard
echo "🚀 Starting monitoring dashboard..."
cd /home/egistr/Documents/kuliah/semester6/dw/DW_Project_Kelompok22/scripts/monitoring

# Run monitoring in background
nohup python3 monitor_dashboard.py > monitoring.log 2>&1 &
MONITOR_PID=$!

echo "✅ Monitoring system started with PID: $MONITOR_PID"
echo "📊 Monitor logs: /home/egistr/Documents/kuliah/semester6/dw/DW_Project_Kelompok22/scripts/monitoring/monitoring.log"
echo "📋 Dashboard reports available in: /home/egistr/Documents/kuliah/semester6/dw/DW_Project_Kelompok22/scripts/monitoring/"
echo ""
echo "🌐 To view real-time monitoring:"
echo "   tail -f /home/egistr/Documents/kuliah/semester6/dw/DW_Project_Kelompok22/scripts/monitoring/monitoring.log"
echo ""
echo "🛑 To stop monitoring:"
echo "   kill $MONITOR_PID"

# Save PID for later
echo $MONITOR_PID > /home/egistr/Documents/kuliah/semester6/dw/DW_Project_Kelompok22/scripts/monitoring/monitor.pid
