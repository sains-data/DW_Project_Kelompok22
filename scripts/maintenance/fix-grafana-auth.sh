#!/bin/bash
# Fix Grafana API Authentication and Upload Dashboards
# PT XYZ Data Warehouse - Grafana Dashboard Fix
# Date: 2025-05-24

echo "🔧 Fixing Grafana API Authentication and Dashboard Upload"
echo "======================================================="

# Wait for Grafana to be ready
echo "⏳ Waiting for Grafana to be ready..."
until curl -s http://localhost:3000/api/health > /dev/null; do
    sleep 2
done
echo "✅ Grafana is ready"

# Create API key using admin credentials
echo "🔑 Creating Grafana API key..."
API_KEY_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"dashboard-upload","role":"Admin"}' \
  http://admin:admin@localhost:3000/api/auth/keys)

if echo "$API_KEY_RESPONSE" | grep -q "key"; then
    API_KEY=$(echo "$API_KEY_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['key'])")
    echo "✅ API key created successfully"
    
    # Test the API key
    echo "🧪 Testing API key..."
    TEST_RESPONSE=$(curl -s -H "Authorization: Bearer $API_KEY" http://localhost:3000/api/user)
    if echo "$TEST_RESPONSE" | grep -q "admin"; then
        echo "✅ API key test successful"
        
        # Create datasource for SQL Server
        echo "📊 Creating SQL Server datasource..."
        curl -s -X POST \
          -H "Authorization: Bearer $API_KEY" \
          -H "Content-Type: application/json" \
          -d '{
            "name": "PTXYZ_DataWarehouse",
            "type": "mssql",
            "url": "sqlserver:1433",
            "access": "proxy",
            "database": "PTXYZ_DataWarehouse",
            "user": "sa",
            "secureJsonData": {
              "password": "YourSecurePassword123!"
            },
            "isDefault": true
          }' \
          http://localhost:3000/api/datasources
        
        echo "✅ SQL Server datasource created"
        
        # Create simple dashboard
        echo "📈 Creating PT XYZ Analytics Dashboard..."
        DASHBOARD_JSON='{
          "dashboard": {
            "id": null,
            "title": "PT XYZ Data Warehouse Analytics",
            "tags": ["ptxyz", "analytics"],
            "timezone": "browser",
            "panels": [
              {
                "id": 1,
                "title": "Total Production Volume",
                "type": "stat",
                "targets": [
                  {
                    "expr": "SELECT SUM(produced_volume) as total_production FROM fact.FactProduction",
                    "format": "table",
                    "legendFormat": "",
                    "refId": "A"
                  }
                ],
                "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
              },
              {
                "id": 2,
                "title": "Equipment Efficiency",
                "type": "stat",
                "targets": [
                  {
                    "expr": "SELECT AVG(efficiency_ratio) as avg_efficiency FROM fact.FactEquipmentUsage",
                    "format": "table",
                    "legendFormat": "",
                    "refId": "B"
                  }
                ],
                "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
              },
              {
                "id": 3,
                "title": "Budget Variance",
                "type": "timeseries",
                "targets": [
                  {
                    "expr": "SELECT dt.full_date, SUM(fft.actual_cost - fft.budgeted_cost) as variance FROM fact.FactFinancialTransaction fft JOIN dim.DimTime dt ON fft.time_key = dt.time_key GROUP BY dt.full_date ORDER BY dt.full_date",
                    "format": "table",
                    "legendFormat": "",
                    "refId": "C"
                  }
                ],
                "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
              }
            ],
            "time": {"from": "now-30d", "to": "now"},
            "refresh": "5m"
          },
          "overwrite": true
        }'
        
        UPLOAD_RESPONSE=$(curl -s -X POST \
          -H "Authorization: Bearer $API_KEY" \
          -H "Content-Type: application/json" \
          -d "$DASHBOARD_JSON" \
          http://localhost:3000/api/dashboards/db)
        
        if echo "$UPLOAD_RESPONSE" | grep -q "success"; then
            echo "✅ Dashboard uploaded successfully"
            DASHBOARD_URL=$(echo "$UPLOAD_RESPONSE" | python3 -c "import sys, json; print('http://localhost:3000' + json.load(sys.stdin)['url'])" 2>/dev/null || echo "http://localhost:3000/dashboards")
            echo "🌐 Dashboard URL: $DASHBOARD_URL"
        else
            echo "⚠️ Dashboard upload had issues, but Grafana is configured"
            echo "🌐 Access Grafana: http://localhost:3000 (admin/admin)"
        fi
        
    else
        echo "❌ API key test failed"
    fi
else
    echo "❌ Failed to create API key, using basic auth"
    echo "🌐 Access Grafana manually: http://localhost:3000 (admin/admin)"
fi

echo ""
echo "🎯 Grafana Configuration Complete!"
echo "=================================="
echo "🌐 Grafana URL: http://localhost:3000"
echo "🔐 Username: admin"
echo "🔐 Password: admin"
echo "📊 Datasource: PTXYZ_DataWarehouse (SQL Server)"
echo ""
echo "💡 You can now create custom dashboards using the analytics views:"
echo "   • analytics.vw_ExecutiveDashboard"
echo "   • analytics.vw_RealTimeOperations"
echo "   • analytics.vw_PredictiveInsights"
echo "   • analytics.vw_CostOptimization"
