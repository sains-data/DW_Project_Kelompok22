#!/usr/bin/env python3
import pymssql
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def check_actual_tables():
    """Check what tables actually exist in the database"""
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
        
        # Get all tables in all schemas
        logger.info("=== All Tables in Database ===")
        cursor.execute("""
            SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_TYPE 
            FROM INFORMATION_SCHEMA.TABLES 
            ORDER BY TABLE_SCHEMA, TABLE_NAME
        """)
        
        tables = cursor.fetchall()
        current_schema = None
        for schema, table_name, table_type in tables:
            if schema != current_schema:
                logger.info(f"\n--- Schema: {schema} ---")
                current_schema = schema
            logger.info(f"  {table_name} ({table_type})")
        
        # Check columns for existing dimension tables
        dim_tables = [row for row in tables if row[0] == 'dim']
        for schema, table_name, _ in dim_tables:
            logger.info(f"\n=== Columns in {schema}.{table_name} ===")
            cursor.execute(f"""
                SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = '{schema}' AND TABLE_NAME = '{table_name}'
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
    check_actual_tables()
