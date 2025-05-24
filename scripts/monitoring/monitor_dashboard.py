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
