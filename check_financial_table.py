#!/usr/bin/env python3
import pymssql
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def check_financial_table():
    """Check FactFinancialTransaction table structure including computed columns"""
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
        
        # Check for computed columns
        logger.info("=== FactFinancialTransaction Column Details ===")
        cursor.execute("""
            SELECT 
                c.COLUMN_NAME, 
                c.DATA_TYPE, 
                c.IS_NULLABLE,
                c.COLUMN_DEFAULT,
                cc.is_computed,
                cc.definition
            FROM INFORMATION_SCHEMA.COLUMNS c
            LEFT JOIN sys.computed_columns cc ON c.COLUMN_NAME = cc.name
            WHERE c.TABLE_SCHEMA = 'fact' AND c.TABLE_NAME = 'FactFinancialTransaction'
            ORDER BY c.ORDINAL_POSITION
        """)
        
        columns = cursor.fetchall()
        for col_name, data_type, nullable, default, is_computed, definition in columns:
            computed_info = f" (COMPUTED: {definition})" if is_computed else ""
            logger.info(f"  {col_name} ({data_type}) - Nullable: {nullable}{computed_info}")
        
        # Check what columns can actually be inserted
        logger.info("\n=== Testing INSERT capabilities ===")
        try:
            cursor.execute("""
                SELECT COLUMN_NAME 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = 'fact' AND TABLE_NAME = 'FactFinancialTransaction'
                AND COLUMNPROPERTY(OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME), COLUMN_NAME, 'IsComputed') = 0
                AND COLUMN_NAME != 'transaction_key'
                ORDER BY ORDINAL_POSITION
            """)
            insertable_columns = [row[0] for row in cursor.fetchall()]
            logger.info(f"Insertable columns: {insertable_columns}")
        except Exception as e:
            logger.error(f"Error checking insertable columns: {e}")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        logger.error(f"Error: {e}")

if __name__ == "__main__":
    check_financial_table()
