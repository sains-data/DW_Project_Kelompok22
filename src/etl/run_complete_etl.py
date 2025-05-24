#!/usr/bin/env python3
"""
Complete ETL Pipeline Execution Script
This script runs the full ETL pipeline to load all data into the PT XYZ Data Warehouse
"""

import logging
import sys
import os
import time

# Add the dags directory to Python path
sys.path.append('/home/egistr/Documents/kuliah/semester6/dw/DW_Project_Kelompok22/dags')

from ptxyz_etl_dag import (
    extract_and_load_to_staging,
    transform_and_load_dimensions,
    load_fact_tables,
    data_quality_check
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('etl_execution.log'),
        logging.StreamHandler()
    ]
)

def run_complete_etl():
    """Execute the complete ETL pipeline"""
    try:
        logging.info("🚀 Starting PT XYZ Complete ETL Pipeline...")
        
        # Step 1: Extract and Load to Staging
        logging.info("📥 Step 1: Extracting and loading data to staging tables...")
        result1 = extract_and_load_to_staging()
        logging.info(f"✅ Step 1 completed: {result1}")
        
        time.sleep(2)  # Brief pause between steps
        
        # Step 2: Transform and Load Dimensions
        logging.info("🔄 Step 2: Transforming and loading dimension tables...")
        result2 = transform_and_load_dimensions()
        logging.info(f"✅ Step 2 completed: {result2}")
        
        time.sleep(2)
        
        # Step 3: Load Fact Tables
        logging.info("📊 Step 3: Loading fact tables...")
        result3 = load_fact_tables()
        logging.info(f"✅ Step 3 completed: {result3}")
        
        time.sleep(2)
        
        # Step 4: Data Quality Check
        logging.info("🔍 Step 4: Running data quality checks...")
        result4 = data_quality_check()
        logging.info(f"✅ Step 4 completed: {result4}")
        
        logging.info("🎉 Complete ETL Pipeline Successfully Executed!")
        logging.info("📈 Data Warehouse is now ready for analytics and visualization!")
        
        return True
        
    except Exception as e:
        logging.error(f"❌ ETL Pipeline failed: {str(e)}")
        return False

if __name__ == "__main__":
    logging.info("=" * 80)
    logging.info("PT XYZ Data Warehouse - Complete ETL Pipeline Execution")
    logging.info("=" * 80)
    
    success = run_complete_etl()
    
    if success:
        logging.info("✅ ETL Pipeline completed successfully!")
        logging.info("🌐 You can now access:")
        logging.info("   - Airflow UI: http://localhost:8080")
        logging.info("   - Grafana: http://localhost:3000")
        logging.info("   - Superset: http://localhost:8088")
        logging.info("   - Metabase: http://localhost:3001")
        logging.info("   - Jupyter: http://localhost:8888")
        sys.exit(0)
    else:
        logging.error("❌ ETL Pipeline failed!")
        sys.exit(1)
