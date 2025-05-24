#!/usr/bin/env python3
"""
Test Dashboard Queries - Validate that Grafana dashboard queries work with actual data
"""

import pyodbc
import pandas as pd
from datetime import datetime, timedelta
import logging

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Database connection configuration
SERVER = 'localhost,1433'
DATABASE = 'PTXYZ_DataWarehouse'
USERNAME = 'sa'
PASSWORD = 'PTXYZDataWarehouse2025'

def get_connection():
    """Create database connection"""
    try:
        connection_string = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};UID={USERNAME};PWD={PASSWORD}'
        return pyodbc.connect(connection_string)
    except Exception as e:
        logger.error(f"Failed to connect to database: {e}")
        return None

def test_equipment_efficiency_query():
    """Test Equipment Efficiency Over Time query"""
    logger.info("Testing Equipment Efficiency query...")
    
    query = """
    SELECT 
      dt.date as time,
      eq.equipment_type,
      AVG(CAST(feu.operating_hours AS FLOAT) / (feu.operating_hours + feu.downtime_hours) * 100) as efficiency
    FROM fact.FactEquipmentUsage feu
    JOIN dim.DimTime dt ON feu.time_key = dt.time_key
    JOIN dim.DimEquipment eq ON feu.equipment_key = eq.equipment_key
    WHERE dt.date >= DATEADD(day, -30, GETDATE())
    GROUP BY dt.date, eq.equipment_type
    ORDER BY dt.date
    """
    
    try:
        conn = get_connection()
        if conn:
            df = pd.read_sql(query, conn)
            logger.info(f"Equipment Efficiency query returned {len(df)} rows")
            if len(df) > 0:
                logger.info(f"Sample data:\n{df.head()}")
                logger.info(f"Equipment types: {df['equipment_type'].unique()}")
                logger.info(f"Date range: {df['time'].min()} to {df['time'].max()}")
            conn.close()
            return True
    except Exception as e:
        logger.error(f"Equipment Efficiency query failed: {e}")
        return False

def test_production_by_material_query():
    """Test Production by Material Type query"""
    logger.info("Testing Production by Material query...")
    
    query = """
    SELECT 
      dm.material_type,
      SUM(fp.produced_volume) as total_production
    FROM fact.FactProduction fp
    JOIN dim.DimMaterial dm ON fp.material_key = dm.material_key
    JOIN dim.DimTime dt ON fp.time_key = dt.time_key
    WHERE dt.date >= DATEADD(day, -30, GETDATE())
    GROUP BY dm.material_type
    ORDER BY total_production DESC
    """
    
    try:
        conn = get_connection()
        if conn:
            df = pd.read_sql(query, conn)
            logger.info(f"Production by Material query returned {len(df)} rows")
            if len(df) > 0:
                logger.info(f"Sample data:\n{df.head()}")
                logger.info(f"Material types: {df['material_type'].unique()}")
                logger.info(f"Total production range: {df['total_production'].min()} to {df['total_production'].max()}")
            conn.close()
            return True
    except Exception as e:
        logger.error(f"Production by Material query failed: {e}")
        return False

def test_budget_variance_query():
    """Test Top Projects by Budget Variance query"""
    logger.info("Testing Budget Variance query...")
    
    query = """
    SELECT TOP 10
      dp.project_name,
      ds.site_name,
      ds.region,
      SUM(fft.budgeted_cost) as budgeted_cost,
      SUM(fft.actual_cost) as actual_cost,
      SUM(fft.variance_amount) as variance,
      CASE 
        WHEN SUM(fft.budgeted_cost) > 0 
        THEN (SUM(fft.variance_amount) / SUM(fft.budgeted_cost)) * 100 
        ELSE 0 
      END as variance_percentage
    FROM fact.FactFinancialTransaction fft
    JOIN dim.DimProject dp ON fft.project_key = dp.project_key
    JOIN dim.DimSite ds ON fft.site_key = ds.site_key
    JOIN dim.DimTime dt ON fft.time_key = dt.time_key
    WHERE dt.date >= DATEADD(day, -30, GETDATE())
    GROUP BY dp.project_name, ds.site_name, ds.region
    ORDER BY ABS(variance) DESC
    """
    
    try:
        conn = get_connection()
        if conn:
            df = pd.read_sql(query, conn)
            logger.info(f"Budget Variance query returned {len(df)} rows")
            if len(df) > 0:
                logger.info(f"Sample data:\n{df.head()}")
                logger.info(f"Projects: {df['project_name'].unique()}")
                logger.info(f"Variance range: {df['variance'].min()} to {df['variance'].max()}")
            conn.close()
            return True
    except Exception as e:
        logger.error(f"Budget Variance query failed: {e}")
        return False

def test_daily_production_query():
    """Test Daily Production by Region query"""
    logger.info("Testing Daily Production query...")
    
    query = """
    SELECT 
      dt.date as time,
      ds.region,
      SUM(fp.produced_volume) as total_production
    FROM fact.FactProduction fp
    JOIN dim.DimTime dt ON fp.time_key = dt.time_key
    JOIN dim.DimSite ds ON fp.site_key = ds.site_key
    WHERE dt.date >= DATEADD(day, -30, GETDATE())
    GROUP BY dt.date, ds.region
    ORDER BY dt.date
    """
    
    try:
        conn = get_connection()
        if conn:
            df = pd.read_sql(query, conn)
            logger.info(f"Daily Production query returned {len(df)} rows")
            if len(df) > 0:
                logger.info(f"Sample data:\n{df.head()}")
                logger.info(f"Regions: {df['region'].unique()}")
                logger.info(f"Date range: {df['time'].min()} to {df['time'].max()}")
            conn.close()
            return True
    except Exception as e:
        logger.error(f"Daily Production query failed: {e}")
        return False

def test_overall_efficiency_query():
    """Test Overall Equipment Efficiency query"""
    logger.info("Testing Overall Efficiency query...")
    
    query = """
    SELECT 
      AVG(CAST(feu.operating_hours AS FLOAT) / (feu.operating_hours + feu.downtime_hours) * 100) as overall_efficiency
    FROM fact.FactEquipmentUsage feu
    JOIN dim.DimTime dt ON feu.time_key = dt.time_key
    WHERE dt.date >= DATEADD(day, -7, GETDATE())
    """
    
    try:
        conn = get_connection()
        if conn:
            df = pd.read_sql(query, conn)
            logger.info(f"Overall Efficiency query returned {len(df)} rows")
            if len(df) > 0:
                logger.info(f"Overall efficiency: {df['overall_efficiency'].iloc[0]:.2f}%")
            conn.close()
            return True
    except Exception as e:
        logger.error(f"Overall Efficiency query failed: {e}")
        return False

def main():
    """Run all dashboard query tests"""
    logger.info("Starting Dashboard Query Tests")
    logger.info("=" * 50)
    
    tests = [
        test_equipment_efficiency_query,
        test_production_by_material_query,
        test_budget_variance_query,
        test_daily_production_query,
        test_overall_efficiency_query
    ]
    
    results = []
    for test in tests:
        result = test()
        results.append(result)
        logger.info("-" * 30)
    
    logger.info("=" * 50)
    logger.info("DASHBOARD QUERY TEST SUMMARY")
    logger.info(f"Passed: {sum(results)}/{len(results)}")
    
    if all(results):
        logger.info("✅ All dashboard queries are working correctly!")
        logger.info("🎉 Grafana dashboard is ready for use!")
    else:
        logger.error("❌ Some dashboard queries failed. Check logs above.")
    
    return all(results)

if __name__ == "__main__":
    main()
