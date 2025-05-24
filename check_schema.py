#!/usr/bin/env python3
import pymssql
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def check_schema():
    """Check the actual column names in dimension and fact tables"""
    try:
        # Connect to SQL Server
        conn = pymssql.connect(
            server='localhost',
            port=1433,
            database='PTXYZ_DataWarehouse',
            user='sa',
            password='PTXYZDataWarehouse2025',
            timeout=30
        )
        cursor = conn.cursor()
        
        # Check dimension table schemas
        tables_to_check = [
            'dim.Equipment',
            'dim.Site', 
            'dim.Material',
            'dim.Employee',
            'dim.Time',
            'dim.Shift',
            'dim.Project',
            'dim.Account',
            'fact.EquipmentUsage',
            'fact.Production',
            'fact.FinancialTransaction'
        ]
        
        for table in tables_to_check:
            logger.info(f"\n=== Checking {table} ===")
            try:
                cursor.execute(f"""
                    SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT
                    FROM INFORMATION_SCHEMA.COLUMNS 
                    WHERE TABLE_SCHEMA = '{table.split('.')[0]}' 
                    AND TABLE_NAME = '{table.split('.')[1]}'
                    ORDER BY ORDINAL_POSITION
                """)
                
                columns = cursor.fetchall()
                if columns:
                    for col in columns:
                        logger.info(f"  {col[0]} ({col[1]}) - Nullable: {col[2]}")
                else:
                    logger.warning(f"  No columns found for {table}")
                    
            except Exception as e:
                logger.error(f"  Error checking {table}: {e}")
        
        # Check current data counts
        logger.info("\n=== Data Counts ===")
        count_queries = [
            ("staging.EquipmentUsage", "SELECT COUNT(*) FROM staging.EquipmentUsage"),
            ("staging.Production", "SELECT COUNT(*) FROM staging.Production"),
            ("staging.FinancialTransaction", "SELECT COUNT(*) FROM staging.FinancialTransaction"),
            ("dim.Equipment", "SELECT COUNT(*) FROM dim.Equipment"),
            ("dim.Site", "SELECT COUNT(*) FROM dim.Site"),
            ("dim.Material", "SELECT COUNT(*) FROM dim.Material"),
            ("dim.Employee", "SELECT COUNT(*) FROM dim.Employee"),
            ("dim.Time", "SELECT COUNT(*) FROM dim.Time"),
            ("fact.EquipmentUsage", "SELECT COUNT(*) FROM fact.EquipmentUsage"),
            ("fact.Production", "SELECT COUNT(*) FROM fact.Production"),
            ("fact.FinancialTransaction", "SELECT COUNT(*) FROM fact.FinancialTransaction")
        ]
        
        for table_name, query in count_queries:
            try:
                cursor.execute(query)
                count = cursor.fetchone()[0]
                logger.info(f"{table_name}: {count} records")
            except Exception as e:
                logger.error(f"Error counting {table_name}: {e}")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        logger.error(f"Schema check failed: {e}")

if __name__ == "__main__":
    check_schema()
