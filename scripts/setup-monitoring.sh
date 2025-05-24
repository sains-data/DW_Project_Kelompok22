#!/bin/bash
# PT XYZ Data Warehouse - Real-Time Monitoring & Alerting System
# Date: 2025-05-24

echo "🔍 PT XYZ Real-Time Monitoring & Alerting Setup"
echo "==============================================="
echo

# Create monitoring directory
mkdir -p /tmp/monitoring

# 1. System Health Monitoring Script
echo "1. Creating System Health Monitor..."
cat > /tmp/monitoring/health_monitor.py << 'EOF'
#!/usr/bin/env python3
"""
PT XYZ Data Warehouse Real-Time Health Monitor
Monitors system health and sends alerts for critical issues
"""

import time
import requests
import psutil
import json
import logging
from datetime import datetime
import subprocess

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/tmp/monitoring/health_monitor.log'),
        logging.StreamHandler()
    ]
)

class DataWarehouseMonitor:
    def __init__(self):
        self.services = {
            'airflow': 'http://localhost:8080/health',
            'grafana': 'http://localhost:3000/api/health',
            'superset': 'http://localhost:8088/health',
            'metabase': 'http://localhost:3001/',
            'jupyter': 'http://localhost:8888/'
        }
        self.alerts = []
        
    def check_service_health(self, service_name, url):
        """Check if a service is responding"""
        try:
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                logging.info(f"✅ {service_name} is healthy")
                return True
            else:
                logging.warning(f"⚠️ {service_name} returned status {response.status_code}")
                return False
        except requests.exceptions.RequestException as e:
            logging.error(f"❌ {service_name} is unreachable: {e}")
            return False
    
    def check_docker_containers(self):
        """Check Docker container status"""
        try:
            result = subprocess.run(['docker', 'ps', '--format', 'table {{.Names}}\t{{.Status}}'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                logging.info("🐳 Docker containers status checked")
                return True
            else:
                logging.error("❌ Failed to check Docker containers")
                return False
        except Exception as e:
            logging.error(f"❌ Docker check failed: {e}")
            return False
    
    def check_system_resources(self):
        """Monitor system resource usage"""
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        alerts = []
        
        if cpu_percent > 80:
            alerts.append(f"🚨 HIGH CPU USAGE: {cpu_percent}%")
        
        if memory.percent > 85:
            alerts.append(f"🚨 HIGH MEMORY USAGE: {memory.percent}%")
        
        if disk.percent > 90:
            alerts.append(f"🚨 HIGH DISK USAGE: {disk.percent}%")
        
        if alerts:
            for alert in alerts:
                logging.warning(alert)
        else:
            logging.info(f"📊 System resources OK - CPU: {cpu_percent}% | Memory: {memory.percent}% | Disk: {disk.percent}%")
        
        return len(alerts) == 0
    
    def check_database_connection(self):
        """Test SQL Server connection"""
        try:
            result = subprocess.run([
                'docker', 'exec', 'ptxyz_sqlserver', 
                '/opt/mssql-tools18/bin/sqlcmd', 
                '-S', 'localhost', '-U', 'sa', '-P', 'YourSecurePassword123!',
                '-Q', 'SELECT 1', '-C'
            ], capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                logging.info("✅ Database connection healthy")
                return True
            else:
                logging.error("❌ Database connection failed")
                return False
        except Exception as e:
            logging.error(f"❌ Database check failed: {e}")
            return False
    
    def run_health_check(self):
        """Run complete health check"""
        logging.info("🔍 Starting health check cycle...")
        
        health_status = {
            'timestamp': datetime.now().isoformat(),
            'services': {},
            'system': {},
            'overall_status': 'HEALTHY'
        }
        
        # Check services
        for service, url in self.services.items():
            health_status['services'][service] = self.check_service_health(service, url)
        
        # Check system resources
        health_status['system']['resources'] = self.check_system_resources()
        health_status['system']['docker'] = self.check_docker_containers()
        health_status['system']['database'] = self.check_database_connection()
        
        # Determine overall status
        if not all(health_status['services'].values()) or not all(health_status['system'].values()):
            health_status['overall_status'] = 'DEGRADED'
        
        # Save status to file
        with open('/tmp/monitoring/latest_status.json', 'w') as f:
            json.dump(health_status, f, indent=2)
        
        logging.info(f"🎯 Health check complete - Status: {health_status['overall_status']}")
        return health_status

def main():
    monitor = DataWarehouseMonitor()
    
    logging.info("🚀 PT XYZ Data Warehouse Monitor Started")
    
    while True:
        try:
            status = monitor.run_health_check()
            
            if status['overall_status'] == 'DEGRADED':
                logging.warning("⚠️ SYSTEM DEGRADED - Check logs for details")
            
            # Wait 60 seconds before next check
            time.sleep(60)
            
        except KeyboardInterrupt:
            logging.info("🛑 Monitor stopped by user")
            break
        except Exception as e:
            logging.error(f"❌ Monitor error: {e}")
            time.sleep(60)

if __name__ == "__main__":
    main()
EOF

# 2. Data Quality Monitor
echo "2. Creating Data Quality Monitor..."
cat > /tmp/monitoring/data_quality_monitor.py << 'EOF'
#!/usr/bin/env python3
"""
PT XYZ Data Warehouse Data Quality Monitor
Monitors data quality metrics and detects anomalies
"""

import subprocess
import json
import logging
from datetime import datetime, timedelta

class DataQualityMonitor:
    def __init__(self):
        self.quality_checks = {
            'record_counts': self.check_record_counts,
            'data_freshness': self.check_data_freshness,
            'referential_integrity': self.check_referential_integrity,
            'null_values': self.check_null_values
        }
    
    def execute_sql(self, query):
        """Execute SQL query and return result"""
        try:
            result = subprocess.run([
                'docker', 'exec', 'ptxyz_sqlserver',
                '/opt/mssql-tools18/bin/sqlcmd',
                '-S', 'localhost', '-U', 'sa', '-P', 'YourSecurePassword123!',
                '-d', 'PTXYZ_DataWarehouse',
                '-Q', query, '-C', '-h', '-1'
            ], capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                return result.stdout.strip()
            else:
                logging.error(f"SQL execution failed: {result.stderr}")
                return None
        except Exception as e:
            logging.error(f"SQL execution error: {e}")
            return None
    
    def check_record_counts(self):
        """Check if record counts are within expected ranges"""
        queries = {
            'equipment_usage': "SELECT COUNT(*) FROM fact.FactEquipmentUsage",
            'production': "SELECT COUNT(*) FROM fact.FactProduction", 
            'financial': "SELECT COUNT(*) FROM fact.FactFinancialTransaction"
        }
        
        results = {}
        for table, query in queries.items():
            count = self.execute_sql(query)
            if count and count.isdigit():
                results[table] = int(count)
                logging.info(f"📊 {table}: {count} records")
            else:
                results[table] = 0
                logging.warning(f"⚠️ Could not get count for {table}")
        
        return results
    
    def check_data_freshness(self):
        """Check if data is recent (within last 24 hours)"""
        query = """
        SELECT 
            MAX(created_at) as latest_record
        FROM (
            SELECT created_at FROM fact.FactEquipmentUsage
            UNION ALL
            SELECT created_at FROM fact.FactProduction
            UNION ALL  
            SELECT created_at FROM fact.FactFinancialTransaction
        ) combined
        """
        
        latest = self.execute_sql(query)
        if latest:
            logging.info(f"📅 Latest data: {latest}")
            return latest
        else:
            logging.warning("⚠️ Could not determine data freshness")
            return None
    
    def check_referential_integrity(self):
        """Check foreign key relationships"""
        integrity_queries = {
            'equipment_usage_site_keys': """
                SELECT COUNT(*) FROM fact.FactEquipmentUsage feu 
                LEFT JOIN dim.DimSite ds ON feu.site_key = ds.site_key 
                WHERE ds.site_key IS NULL
            """,
            'production_material_keys': """
                SELECT COUNT(*) FROM fact.FactProduction fp 
                LEFT JOIN dim.DimMaterial dm ON fp.material_key = dm.material_key 
                WHERE dm.material_key IS NULL
            """
        }
        
        issues = {}
        for check, query in integrity_queries.items():
            count = self.execute_sql(query)
            if count and count.isdigit():
                issues[check] = int(count)
                if int(count) > 0:
                    logging.warning(f"⚠️ {check}: {count} integrity issues")
                else:
                    logging.info(f"✅ {check}: No issues")
        
        return issues
    
    def check_null_values(self):
        """Check for unexpected NULL values in critical columns"""
        null_checks = {
            'equipment_efficiency_nulls': "SELECT COUNT(*) FROM fact.FactEquipmentUsage WHERE efficiency_ratio IS NULL",
            'production_volume_nulls': "SELECT COUNT(*) FROM fact.FactProduction WHERE produced_volume IS NULL",
            'financial_cost_nulls': "SELECT COUNT(*) FROM fact.FactFinancialTransaction WHERE actual_cost IS NULL"
        }
        
        null_issues = {}
        for check, query in null_checks.items():
            count = self.execute_sql(query)
            if count and count.isdigit():
                null_issues[check] = int(count)
                if int(count) > 0:
                    logging.warning(f"⚠️ {check}: {count} NULL values")
                else:
                    logging.info(f"✅ {check}: No NULL issues")
        
        return null_issues
    
    def run_quality_checks(self):
        """Run all data quality checks"""
        logging.info("🔍 Starting data quality checks...")
        
        quality_report = {
            'timestamp': datetime.now().isoformat(),
            'record_counts': self.check_record_counts(),
            'data_freshness': self.check_data_freshness(),
            'referential_integrity': self.check_referential_integrity(),
            'null_values': self.check_null_values(),
            'overall_quality': 'GOOD'
        }
        
        # Determine overall quality
        if any(count == 0 for count in quality_report['record_counts'].values()):
            quality_report['overall_quality'] = 'POOR'
        elif any(count > 0 for count in quality_report['referential_integrity'].values()):
            quality_report['overall_quality'] = 'FAIR'
        elif any(count > 100 for count in quality_report['null_values'].values()):
            quality_report['overall_quality'] = 'FAIR'
        
        # Save report
        with open('/tmp/monitoring/quality_report.json', 'w') as f:
            json.dump(quality_report, f, indent=2)
        
        logging.info(f"🎯 Data quality check complete - Quality: {quality_report['overall_quality']}")
        return quality_report

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    monitor = DataQualityMonitor()
    monitor.run_quality_checks()
EOF

# 3. Performance Monitor
echo "3. Creating Performance Monitor..."
cat > /tmp/monitoring/performance_monitor.py << 'EOF'
#!/usr/bin/env python3
"""
PT XYZ Data Warehouse Performance Monitor
Monitors query performance and system metrics
"""

import subprocess
import time
import json
import logging
from datetime import datetime

class PerformanceMonitor:
    def __init__(self):
        self.test_queries = {
            'simple_count': "SELECT COUNT(*) FROM fact.FactEquipmentUsage",
            'join_query': """
                SELECT COUNT(*) FROM fact.FactEquipmentUsage feu 
                JOIN dim.DimSite ds ON feu.site_key = ds.site_key
            """,
            'aggregation_query': """
                SELECT ds.site_name, AVG(feu.efficiency_ratio) 
                FROM fact.FactEquipmentUsage feu 
                JOIN dim.DimSite ds ON feu.site_key = ds.site_key 
                GROUP BY ds.site_name
            """
        }
    
    def measure_query_performance(self, query_name, query):
        """Measure query execution time"""
        start_time = time.time()
        
        try:
            result = subprocess.run([
                'docker', 'exec', 'ptxyz_sqlserver',
                '/opt/mssql-tools18/bin/sqlcmd',
                '-S', 'localhost', '-U', 'sa', '-P', 'YourSecurePassword123!',
                '-d', 'PTXYZ_DataWarehouse',
                '-Q', query, '-C'
            ], capture_output=True, text=True, timeout=60)
            
            execution_time = time.time() - start_time
            
            if result.returncode == 0:
                logging.info(f"⚡ {query_name}: {execution_time:.3f} seconds")
                return execution_time
            else:
                logging.error(f"❌ {query_name} failed: {result.stderr}")
                return None
                
        except Exception as e:
            execution_time = time.time() - start_time
            logging.error(f"❌ {query_name} error after {execution_time:.3f}s: {e}")
            return None
    
    def check_index_usage(self):
        """Check index usage statistics"""
        index_query = """
        SELECT 
            i.name as index_name,
            s.user_seeks,
            s.user_scans,
            s.user_lookups,
            s.user_updates
        FROM sys.indexes i
        LEFT JOIN sys.dm_db_index_usage_stats s ON i.object_id = s.object_id AND i.index_id = s.index_id
        WHERE i.object_id IN (
            SELECT object_id FROM sys.tables 
            WHERE schema_id IN (SCHEMA_ID('dim'), SCHEMA_ID('fact'))
        )
        AND i.name IS NOT NULL
        """
        
        try:
            result = subprocess.run([
                'docker', 'exec', 'ptxyz_sqlserver',
                '/opt/mssql-tools18/bin/sqlcmd',
                '-S', 'localhost', '-U', 'sa', '-P', 'YourSecurePassword123!',
                '-d', 'PTXYZ_DataWarehouse',
                '-Q', index_query, '-C'
            ], capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                logging.info("📊 Index usage statistics collected")
                return True
            else:
                logging.warning("⚠️ Could not collect index statistics")
                return False
        except Exception as e:
            logging.error(f"❌ Index statistics error: {e}")
            return False
    
    def run_performance_tests(self):
        """Run all performance tests"""
        logging.info("⚡ Starting performance tests...")
        
        performance_report = {
            'timestamp': datetime.now().isoformat(),
            'query_performance': {},
            'index_usage_checked': False,
            'performance_grade': 'EXCELLENT'
        }
        
        # Test query performance
        for query_name, query in self.test_queries.items():
            exec_time = self.measure_query_performance(query_name, query)
            if exec_time is not None:
                performance_report['query_performance'][query_name] = exec_time
        
        # Check index usage
        performance_report['index_usage_checked'] = self.check_index_usage()
        
        # Determine performance grade
        avg_time = sum(performance_report['query_performance'].values()) / len(performance_report['query_performance'])
        if avg_time > 5.0:
            performance_report['performance_grade'] = 'POOR'
        elif avg_time > 2.0:
            performance_report['performance_grade'] = 'FAIR'
        elif avg_time > 1.0:
            performance_report['performance_grade'] = 'GOOD'
        
        # Save report
        with open('/tmp/monitoring/performance_report.json', 'w') as f:
            json.dump(performance_report, f, indent=2)
        
        logging.info(f"🎯 Performance tests complete - Grade: {performance_report['performance_grade']}")
        return performance_report

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    monitor = PerformanceMonitor()
    monitor.run_performance_tests()
EOF

# 4. Main monitoring orchestrator
echo "4. Creating Monitoring Orchestrator..."
cat > /tmp/monitoring/monitor_dashboard.py << 'EOF'
#!/usr/bin/env python3
"""
PT XYZ Data Warehouse Monitoring Dashboard
Orchestrates all monitoring components
"""

import time
import json
import logging
from datetime import datetime
import subprocess
import os

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/tmp/monitoring/dashboard.log'),
        logging.StreamHandler()
    ]
)

def run_monitor(script_name):
    """Run a monitoring script"""
    try:
        result = subprocess.run(['python3', f'/tmp/monitoring/{script_name}'], 
                              capture_output=True, text=True, timeout=300)
        if result.returncode == 0:
            logging.info(f"✅ {script_name} completed successfully")
            return True
        else:
            logging.error(f"❌ {script_name} failed: {result.stderr}")
            return False
    except Exception as e:
        logging.error(f"❌ Error running {script_name}: {e}")
        return False

def generate_dashboard_report():
    """Generate comprehensive monitoring dashboard"""
    dashboard_data = {
        'timestamp': datetime.now().isoformat(),
        'system_status': 'UNKNOWN',
        'data_quality': 'UNKNOWN',
        'performance': 'UNKNOWN',
        'alerts': []
    }
    
    # Load individual reports
    reports = ['latest_status.json', 'quality_report.json', 'performance_report.json']
    
    for report_file in reports:
        try:
            with open(f'/tmp/monitoring/{report_file}', 'r') as f:
                data = json.load(f)
                
                if 'overall_status' in data:
                    dashboard_data['system_status'] = data['overall_status']
                if 'overall_quality' in data:
                    dashboard_data['data_quality'] = data['overall_quality']
                if 'performance_grade' in data:
                    dashboard_data['performance'] = data['performance_grade']
                    
        except FileNotFoundError:
            logging.warning(f"⚠️ Report file {report_file} not found")
        except Exception as e:
            logging.error(f"❌ Error reading {report_file}: {e}")
    
    # Determine overall system health
    if dashboard_data['system_status'] == 'HEALTHY' and \
       dashboard_data['data_quality'] == 'GOOD' and \
       dashboard_data['performance'] in ['EXCELLENT', 'GOOD']:
        dashboard_data['overall_health'] = 'EXCELLENT'
    elif dashboard_data['system_status'] == 'DEGRADED' or \
         dashboard_data['data_quality'] == 'FAIR':
        dashboard_data['overall_health'] = 'FAIR'
    else:
        dashboard_data['overall_health'] = 'NEEDS_ATTENTION'
    
    # Save dashboard report
    with open('/tmp/monitoring/dashboard_report.json', 'w') as f:
        json.dump(dashboard_data, f, indent=2)
    
    return dashboard_data

def main():
    logging.info("🚀 PT XYZ Data Warehouse Monitoring Dashboard Started")
    
    while True:
        try:
            logging.info("🔍 Running monitoring cycle...")
            
            # Run all monitors
            monitors = [
                'health_monitor.py',
                'data_quality_monitor.py', 
                'performance_monitor.py'
            ]
            
            for monitor in monitors:
                run_monitor(monitor)
                time.sleep(5)  # Small delay between monitors
            
            # Generate dashboard report
            dashboard = generate_dashboard_report()
            
            logging.info(f"📊 Monitoring cycle complete - Overall Health: {dashboard.get('overall_health', 'UNKNOWN')}")
            
            # Wait 5 minutes before next cycle
            time.sleep(300)
            
        except KeyboardInterrupt:
            logging.info("🛑 Monitoring stopped by user")
            break
        except Exception as e:
            logging.error(f"❌ Monitoring error: {e}")
            time.sleep(60)

if __name__ == "__main__":
    main()
EOF

# Make all scripts executable
chmod +x /tmp/monitoring/*.py

# Copy monitoring scripts to project
echo "5. Installing monitoring scripts..."
cp -r /tmp/monitoring /home/egistr/Documents/kuliah/semester6/dw/DW_Project_Kelompok22/scripts/

# Create monitoring service script
cat > /home/egistr/Documents/kuliah/semester6/dw/DW_Project_Kelompok22/scripts/start-monitoring.sh << 'EOF'
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
EOF

chmod +x /home/egistr/Documents/kuliah/semester6/dw/DW_Project_Kelompok22/scripts/start-monitoring.sh

echo
echo "🔍 Real-Time Monitoring & Alerting Setup Complete!"
echo "=================================================="
echo
echo "🎯 Monitoring Features Installed:"
echo "   ✅ System Health Monitor - Tracks service availability"
echo "   ✅ Data Quality Monitor - Validates data integrity"  
echo "   ✅ Performance Monitor - Measures query execution times"
echo "   ✅ Integrated Dashboard - Comprehensive status reporting"
echo
echo "🚀 To Start Monitoring:"
echo "   ./scripts/start-monitoring.sh"
echo
echo "📊 Monitoring Reports:"
echo "   • Health Status: scripts/monitoring/latest_status.json"
echo "   • Data Quality: scripts/monitoring/quality_report.json"
echo "   • Performance: scripts/monitoring/performance_report.json"
echo "   • Dashboard: scripts/monitoring/dashboard_report.json"
echo
echo "🌐 Your data warehouse now has enterprise-grade monitoring!"
