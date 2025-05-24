#!/usr/bin/env python3
"""
Test script for PT XYZ ETL Pipeline
This script tests the database connection and runs a simple ETL test
"""

import pandas as pd
import pymssql
import logging
import time

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def test_sql_connection():
    """Test SQL Server connection"""
    try:
        conn = pymssql.connect(
            server='localhost',
            port=1433,
            database='PTXYZ_DataWarehouse',
            user='sa',
            password='PTXYZDataWarehouse2025',
            timeout=30
        )
        cursor = conn.cursor()
        
        # Test basic query
        cursor.execute("SELECT @@VERSION")
        version = cursor.fetchone()[0]
        logging.info(f"SQL Server connection successful: {version}")
        
        # Check if database exists
        cursor.execute("SELECT DB_NAME()")
        db_name = cursor.fetchone()[0]
        logging.info(f"Connected to database: {db_name}")
        
        # Check schemas
        cursor.execute("""
            SELECT SCHEMA_NAME 
            FROM INFORMATION_SCHEMA.SCHEMATA 
            WHERE SCHEMA_NAME IN ('staging', 'dim', 'fact')
        """)
        schemas = [row[0] for row in cursor.fetchall()]
        logging.info(f"Available schemas: {schemas}")
        
        # Check if staging tables exist
        cursor.execute("""
            SELECT TABLE_NAME 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = 'staging'
        """)
        staging_tables = [row[0] for row in cursor.fetchall()]
        logging.info(f"Staging tables: {staging_tables}")
        
        conn.close()
        return True
        
    except Exception as e:
        logging.error(f"Error connecting to SQL Server: {str(e)}")
        return False

def test_csv_data():
    """Test CSV data loading"""
    try:
        # Test Equipment data
        equipment_df = pd.read_csv('Dataset/dataset_alat_berat_dw.csv')
        logging.info(f"Equipment data: {len(equipment_df)} records")
        logging.info(f"Equipment columns: {list(equipment_df.columns)}")
        
        # Test Production data
        production_df = pd.read_csv('Dataset/dataset_production.csv')
        logging.info(f"Production data: {len(production_df)} records")
        logging.info(f"Production columns: {list(production_df.columns)}")
        
        # Test Transaction data
        transaction_df = pd.read_csv('Dataset/dataset_transaksi.csv')
        logging.info(f"Transaction data: {len(transaction_df)} records")
        logging.info(f"Transaction columns: {list(transaction_df.columns)}")
        
        return True
        
    except Exception as e:
        logging.error(f"Error reading CSV data: {str(e)}")
        return False

def load_sample_data():
    """Load sample data to staging tables"""
    try:
        conn = pymssql.connect(
            server='localhost',
            port=1433,
            database='PTXYZ_DataWarehouse',
            user='sa',
            password='PTXYZDataWarehouse2025',
            timeout=30
        )
        cursor = conn.cursor()
        
        # Load a few sample records from equipment data
        equipment_df = pd.read_csv('Dataset/dataset_alat_berat_dw.csv')
        equipment_sample = equipment_df.head(10)  # Load first 10 records
        
        # Convert date columns
        equipment_sample['purchase_date'] = pd.to_datetime(equipment_sample['purchase_date']).dt.date
        equipment_sample['date'] = pd.to_datetime(equipment_sample['date']).dt.date
        equipment_sample['created_at'] = pd.to_datetime(equipment_sample['created_at'])
        
        # Clear staging table first
        cursor.execute("DELETE FROM staging.EquipmentUsage")
        
        # Insert sample data
        for _, row in equipment_sample.iterrows():
            cursor.execute("""
                INSERT INTO staging.EquipmentUsage (
                    equipment_usage_id, time_id, date, day, day_name, month, year,
                    site_name, region, latitude, longitude, equipment_name, 
                    equipment_type, manufacture, model, capacity, purchase_date,
                    operating_hours, downtime_hours, fuel_consumption, 
                    maintenance_cost, created_at, created_by
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, tuple(row))
        
        conn.commit()
        
        # Verify data was loaded
        cursor.execute("SELECT COUNT(*) FROM staging.EquipmentUsage")
        count = cursor.fetchone()[0]
        logging.info(f"Successfully loaded {count} records to staging.EquipmentUsage")
        
        conn.close()
        return True
        
    except Exception as e:
        logging.error(f"Error loading sample data: {str(e)}")
        return False

def main():
    """Main test function"""
    logging.info("=== PT XYZ ETL Pipeline Test ===")
    
    # Wait for SQL Server to be ready
    logging.info("Waiting for SQL Server to be ready...")
    time.sleep(30)
    
    # Test 1: SQL Server Connection
    logging.info("1. Testing SQL Server connection...")
    if test_sql_connection():
        logging.info("✅ SQL Server connection test passed")
    else:
        logging.error("❌ SQL Server connection test failed")
        return
    
    # Test 2: CSV Data
    logging.info("2. Testing CSV data loading...")
    if test_csv_data():
        logging.info("✅ CSV data test passed")
    else:
        logging.error("❌ CSV data test failed")
        return
    
    # Test 3: Sample Data Loading
    logging.info("3. Testing sample data loading...")
    if load_sample_data():
        logging.info("✅ Sample data loading test passed")
    else:
        logging.error("❌ Sample data loading test failed")
        return
    
    logging.info("🎉 All tests passed! ETL pipeline is ready.")

if __name__ == "__main__":
    main()
