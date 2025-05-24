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
