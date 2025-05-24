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
