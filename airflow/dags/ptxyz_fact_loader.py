"""
PT XYZ Data Warehouse - Fact Table Loading DAG
==============================================
Loads fact tables after dimensions are populated
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.sensors.external_task import ExternalTaskSensor
import pandas as pd
import pymssql
import logging
import os

default_args = {
    'owner': 'ptxyz_dw',
    'depends_on_past': False,
    'start_date': datetime(2025, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'ptxyz_fact_loader',
    default_args=default_args,
    description='Load fact tables for PT XYZ Data Warehouse',
    schedule_interval='@daily',
    catchup=False,
    tags=['ptxyz', 'facts', 'etl'],
)

def get_sql_connection():
    """Get SQL Server connection"""
    sql_password = os.getenv('MSSQL_SA_PASSWORD', 'PTXYZSecure123!')
    
    return pymssql.connect(
        server='ptxyz_sqlserver',
        port=1433,
        database='PTXYZ_DataWarehouse',
        user='sa',
        password=sql_password,
        timeout=30
    )

def load_fact_equipment_usage():
    """Load equipment usage fact table"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        logging.info("Loading FactEquipmentUsage...")
        cursor.execute("""
            INSERT INTO fact.FactEquipmentUsage (
                equipment_usage_id, time_key, site_key, equipment_key, 
                operating_hours, downtime_hours, fuel_consumption, maintenance_cost
            )
            SELECT DISTINCT
                e.equipment_usage_id,
                t.time_key,
                s.site_key,
                eq.equipment_key,
                e.operating_hours,
                e.downtime_hours,
                e.fuel_consumption,
                e.maintenance_cost
            FROM staging.EquipmentUsage e
            INNER JOIN dim.DimTime t ON e.time_id = t.time_id
            INNER JOIN dim.DimSite s ON e.site_name = s.site_name
            INNER JOIN dim.DimEquipment eq ON e.equipment_name = eq.equipment_name
            WHERE NOT EXISTS (
                SELECT 1 FROM fact.FactEquipmentUsage f 
                WHERE f.equipment_usage_id = e.equipment_usage_id
            )
        """)
        
        conn.commit()
        conn.close()
        logging.info("FactEquipmentUsage loaded successfully")
        
    except Exception as e:
        logging.error(f"Error loading FactEquipmentUsage: {e}")
        raise

def load_fact_production():
    """Load production fact table"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        logging.info("Loading FactProduction...")
        cursor.execute("""
            INSERT INTO fact.FactProduction (
                production_id, time_key, site_key, material_key, employee_key, shift_key,
                produced_volume, unit_cost, material_quantity
            )
            SELECT DISTINCT
                p.production_id,
                t.time_key,
                s.site_key,
                m.material_key,
                e.employee_key,
                sh.shift_key,
                p.produced_volume,
                p.unit_cost,
                p.quantity as material_quantity
            FROM staging.Production p
            INNER JOIN dim.DimTime t ON p.time_id = t.time_id
            INNER JOIN dim.DimSite s ON p.site_id = s.site_id
            INNER JOIN dim.DimMaterial m ON p.material_id = m.material_id
            INNER JOIN dim.DimEmployee e ON p.employee_id = e.employee_id
            INNER JOIN dim.DimShift sh ON p.shift_id = sh.shift_id
            WHERE NOT EXISTS (
                SELECT 1 FROM fact.FactProduction f 
                WHERE f.production_id = p.production_id
            )
        """)
        
        conn.commit()
        conn.close()
        logging.info("FactProduction loaded successfully")
        
    except Exception as e:
        logging.error(f"Error loading FactProduction: {e}")
        raise

def load_fact_financial():
    """Load financial transaction fact table"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        logging.info("Loading FactFinancialTransaction...")
        cursor.execute("""
            INSERT INTO fact.FactFinancialTransaction (
                transaction_id, time_key, site_key, project_key, account_key,
                budgeted_cost, actual_cost, variance_status, account_cost
            )
            SELECT DISTINCT
                f.id,
                t.time_key,
                s.site_key,
                p.project_key,
                a.account_key,
                f.budgeted_cost,
                f.actual_cost,
                CASE 
                    WHEN f.actual_cost > f.budgeted_cost THEN 'Over Budget'
                    WHEN f.actual_cost < f.budgeted_cost THEN 'Under Budget'
                    ELSE 'On Budget'
                END as variance_status,
                f.cost as account_cost
            FROM staging.FinancialTransaction f
            INNER JOIN dim.DimTime t ON f.time_id = t.time_id
            INNER JOIN dim.DimSite s ON f.site_id = s.site_id
            INNER JOIN dim.DimProject p ON f.project_id = p.project_id
            INNER JOIN dim.DimAccount a ON f.account_id = a.account_id
            WHERE NOT EXISTS (
                SELECT 1 FROM fact.FactFinancialTransaction ft 
                WHERE ft.transaction_id = f.id
            )
        """)
        
        conn.commit()
        conn.close()
        logging.info("FactFinancialTransaction loaded successfully")
        
    except Exception as e:
        logging.error(f"Error loading FactFinancialTransaction: {e}")
        raise

def validate_fact_tables():
    """Validate that fact tables have been loaded correctly"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        # Get counts for each fact table
        cursor.execute("SELECT COUNT(*) FROM fact.FactEquipmentUsage")
        equipment_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM fact.FactProduction")
        production_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM fact.FactFinancialTransaction")
        financial_count = cursor.fetchone()[0]
        
        logging.info(f"Fact table validation:")
        logging.info(f"  FactEquipmentUsage: {equipment_count} records")
        logging.info(f"  FactProduction: {production_count} records")
        logging.info(f"  FactFinancialTransaction: {financial_count} records")
        
        # Basic data quality checks
        cursor.execute("""
            SELECT 
                COUNT(*) as total_records,
                COUNT(CASE WHEN operating_hours < 0 THEN 1 END) as negative_hours,
                COUNT(CASE WHEN fuel_consumption < 0 THEN 1 END) as negative_fuel,
                COUNT(CASE WHEN maintenance_cost < 0 THEN 1 END) as negative_cost
            FROM fact.FactEquipmentUsage
        """)
        
        equipment_quality = cursor.fetchone()
        logging.info(f"Equipment Usage Data Quality:")
        logging.info(f"  Total records: {equipment_quality[0]}")
        logging.info(f"  Records with negative operating hours: {equipment_quality[1]}")
        logging.info(f"  Records with negative fuel consumption: {equipment_quality[2]}")
        logging.info(f"  Records with negative maintenance cost: {equipment_quality[3]}")
        
        conn.close()
        
        if equipment_count > 0 and production_count > 0 and financial_count > 0:
            logging.info("✅ All fact tables loaded successfully!")
            return True
        else:
            logging.error("❌ Some fact tables are empty!")
            return False
        
    except Exception as e:
        logging.error(f"Error validating fact tables: {e}")
        raise

# Wait for dimension loading to complete
wait_for_dimensions = ExternalTaskSensor(
    task_id='wait_for_dimension_loader',
    external_dag_id='ptxyz_dimension_loader',
    external_task_id='validate_dimensions',
    timeout=300,
    allowed_states=['success'],
    failed_states=['failed', 'skipped'],
    dag=dag,
)

# Fact table loading tasks
load_equipment_fact_task = PythonOperator(
    task_id='load_fact_equipment_usage',
    python_callable=load_fact_equipment_usage,
    dag=dag,
)

load_production_fact_task = PythonOperator(
    task_id='load_fact_production',
    python_callable=load_fact_production,
    dag=dag,
)

load_financial_fact_task = PythonOperator(
    task_id='load_fact_financial',
    python_callable=load_fact_financial,
    dag=dag,
)

validate_facts_task = PythonOperator(
    task_id='validate_fact_tables',
    python_callable=validate_fact_tables,
    dag=dag,
)

# Final completion task
completion_task = BashOperator(
    task_id='etl_completion',
    bash_command="""
    echo "🎉 PT XYZ Data Warehouse ETL Pipeline Completed Successfully!"
    echo "All staging, dimension, and fact tables have been loaded."
    echo "Data is now ready for analytics and reporting."
    """,
    dag=dag,
)

# Set task dependencies
[load_equipment_fact_task, load_production_fact_task, load_financial_fact_task] >> validate_facts_task >> completion_task
