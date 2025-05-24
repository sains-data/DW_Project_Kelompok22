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
