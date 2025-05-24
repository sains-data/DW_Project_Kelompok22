#!/usr/bin/env python3
import pymssql
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def check_fact_tables():
    """Check fact table structures"""
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
        
        # Check fact tables
        fact_tables = ['FactEquipmentUsage', 'FactProduction', 'FactFinancialTransaction']
        
        for table_name in fact_tables:
            logger.info(f"\n=== Columns in fact.{table_name} ===")
            cursor.execute(f"""
                SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = 'fact' AND TABLE_NAME = '{table_name}'
                ORDER BY ORDINAL_POSITION
            """)
            columns = cursor.fetchall()
            for col_name, data_type, nullable in columns:
                logger.info(f"  {col_name} ({data_type}) - Nullable: {nullable}")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        logger.error(f"Error: {e}")

if __name__ == "__main__":
    check_fact_tables()
