from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
import pandas as pd
import pymssql
import logging
import os

# Default arguments for the DAG
default_args = {
    'owner': 'ptxyz_datawarehouse',
    'depends_on_past': False,
    'start_date': datetime(2025, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Define the DAG
dag = DAG(
    'ptxyz_etl_pipeline',
    default_args=default_args,
    description='PT XYZ Data Warehouse ETL Pipeline',
    schedule_interval=timedelta(hours=6),  # Run every 6 hours
    catchup=False,
    tags=['ptxyz', 'datawarehouse', 'mining'],
)

def get_sql_connection():
    """Create SQL Server connection"""
    try:
        conn = pymssql.connect(
            server='sqlserver',
            port=1433,
            database='PTXYZ_DataWarehouse',
            user='sa',
            password='PTXYZDataWarehouse2025',
            timeout=30
        )
        return conn
    except Exception as e:
        logging.error(f"Error connecting to SQL Server: {str(e)}")
        raise

def extract_and_load_to_staging():
    """Extract data from CSV files and load to staging tables"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        # Clear staging tables
        cursor.execute("TRUNCATE TABLE staging.EquipmentUsage")
        cursor.execute("TRUNCATE TABLE staging.Production") 
        cursor.execute("TRUNCATE TABLE staging.FinancialTransaction")
        
        # Load Equipment Usage data
        equipment_df = pd.read_csv('/opt/airflow/data/dataset_alat_berat_dw.csv')
        equipment_df['purchase_date'] = pd.to_datetime(equipment_df['purchase_date']).dt.date
        equipment_df['date'] = pd.to_datetime(equipment_df['date']).dt.date
        equipment_df['created_at'] = pd.to_datetime(equipment_df['created_at'])
        
        for _, row in equipment_df.iterrows():
            cursor.execute("""
                INSERT INTO staging.EquipmentUsage (
                    equipment_usage_id, time_id, date, day, day_name, month, year,
                    site_name, region, latitude, longitude, equipment_name, 
                    equipment_type, manufacture, model, capacity, purchase_date,
                    operating_hours, downtime_hours, fuel_consumption, 
                    maintenance_cost, created_at, created_by
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, tuple(row))
        
        # Load Production data
        production_df = pd.read_csv('/opt/airflow/data/dataset_production.csv')
        production_df['date'] = pd.to_datetime(production_df['date']).dt.date
        production_df['hire_date'] = pd.to_datetime(production_df['hire_date']).dt.date
        
        for _, row in production_df.iterrows():
            cursor.execute("""
                INSERT INTO staging.Production (
                    production_id, time_id, site_id, material_id, employee_id, shift_id,
                    produced_volume, unit_cost, date, day, month, year, day_name,
                    site_name, region, latitude, longitude, material_name, material_type,
                    unit_of_measure, quantity, employee_name, position, department,
                    status, hire_date, shift_name, start_time, end_time
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, tuple(row))
        
        # Load Financial Transaction data
        transaction_df = pd.read_csv('/opt/airflow/data/dataset_transaksi.csv')
        transaction_df['created_at'] = pd.to_datetime(transaction_df['created_at'])
        transaction_df['date'] = pd.to_datetime(transaction_df['date'], format='%Y%m%d').dt.date
        transaction_df['start_date'] = pd.to_datetime(transaction_df['start_date']).dt.date
        transaction_df['end_date'] = pd.to_datetime(transaction_df['end_date']).dt.date
        
        for _, row in transaction_df.iterrows():
            cursor.execute("""
                INSERT INTO staging.FinancialTransaction (
                    id, time_id, site_id, project_id, account_id, variance,
                    budgeted_cost, actual_cost, created_at, created_by, date,
                    day, day_name, month, year, site_name, region, latitude,
                    longitude, project_name, project_manager, status, start_date,
                    end_date, account_name, account_type, budget_category, cost
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, tuple(row))
        
        conn.commit()
        conn.close()
        
        logging.info("Data successfully loaded to staging tables")
        return "Staging load completed"
        
    except Exception as e:
        logging.error(f"Error in staging load: {str(e)}")
        raise

def transform_and_load_dimensions():
    """Transform and load dimension tables"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        # Load Time Dimension
        cursor.execute("""
            INSERT INTO dim.DimTime (time_id, date, day_of_month, day_name, month, month_name, quarter, year, is_weekend)
            SELECT DISTINCT 
                time_id, 
                date,
                day,
                day_name,
                month,
                DATENAME(MONTH, date) as month_name,
                DATEPART(QUARTER, date) as quarter,
                year,
                CASE WHEN DATENAME(WEEKDAY, date) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END as is_weekend
            FROM staging.EquipmentUsage e
            WHERE NOT EXISTS (SELECT 1 FROM dim.DimTime d WHERE d.time_id = e.time_id)
            UNION
            SELECT DISTINCT 
                time_id, 
                date,
                day,
                day_name,
                month,
                DATENAME(MONTH, date) as month_name,
                DATEPART(QUARTER, date) as quarter,
                year,
                CASE WHEN DATENAME(WEEKDAY, date) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END as is_weekend
            FROM staging.Production p
            WHERE NOT EXISTS (SELECT 1 FROM dim.DimTime d WHERE d.time_id = p.time_id)
            UNION
            SELECT DISTINCT 
                time_id, 
                date,
                day,
                day_name,
                month,
                DATENAME(MONTH, date) as month_name,
                DATEPART(QUARTER, date) as quarter,
                year,
                CASE WHEN DATENAME(WEEKDAY, date) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END as is_weekend
            FROM staging.FinancialTransaction f
            WHERE NOT EXISTS (SELECT 1 FROM dim.DimTime d WHERE d.time_id = f.time_id)
        """)
        
        # Load Site Dimension
        cursor.execute("""
            INSERT INTO dim.DimSite (site_id, site_name, region, latitude, longitude)
            SELECT DISTINCT 
                COALESCE(p.site_id, ROW_NUMBER() OVER (ORDER BY e.site_name)) as site_id,
                COALESCE(e.site_name, p.site_name, f.site_name) as site_name,
                COALESCE(e.region, p.region, f.region) as region,
                COALESCE(e.latitude, p.latitude, f.latitude) as latitude,
                COALESCE(e.longitude, p.longitude, f.longitude) as longitude
            FROM staging.EquipmentUsage e
            FULL OUTER JOIN staging.Production p ON e.site_name = p.site_name
            FULL OUTER JOIN staging.FinancialTransaction f ON COALESCE(e.site_name, p.site_name) = f.site_name
            WHERE NOT EXISTS (
                SELECT 1 FROM dim.DimSite d 
                WHERE d.site_name = COALESCE(e.site_name, p.site_name, f.site_name)
            )
        """)
        
        # Load Equipment Dimension
        cursor.execute("""
            INSERT INTO dim.DimEquipment (equipment_name, equipment_type, manufacture, model, capacity, purchase_date)
            SELECT DISTINCT 
                equipment_name, equipment_type, manufacture, model, capacity, purchase_date
            FROM staging.EquipmentUsage e
            WHERE NOT EXISTS (
                SELECT 1 FROM dim.DimEquipment d 
                WHERE d.equipment_name = e.equipment_name
            )
        """)
        
        # Load Material Dimension
        cursor.execute("""
            INSERT INTO dim.DimMaterial (material_id, material_name, material_type, unit_of_measure)
            SELECT DISTINCT 
                material_id, material_name, material_type, unit_of_measure
            FROM staging.Production p
            WHERE NOT EXISTS (
                SELECT 1 FROM dim.DimMaterial d 
                WHERE d.material_id = p.material_id
            )
        """)
        
        # Load Employee Dimension
        cursor.execute("""
            INSERT INTO dim.DimEmployee (employee_id, employee_name, position, department, status, hire_date)
            SELECT DISTINCT 
                employee_id, employee_name, position, department, status, hire_date
            FROM staging.Production p
            WHERE NOT EXISTS (
                SELECT 1 FROM dim.DimEmployee d 
                WHERE d.employee_id = p.employee_id
            )
        """)
        
        # Load Shift Dimension
        cursor.execute("""
            INSERT INTO dim.DimShift (shift_id, shift_name, start_time, end_time)
            SELECT DISTINCT 
                shift_id, shift_name, start_time, end_time
            FROM staging.Production p
            WHERE NOT EXISTS (
                SELECT 1 FROM dim.DimShift d 
                WHERE d.shift_id = p.shift_id
            )
        """)
        
        # Load Project Dimension
        cursor.execute("""
            INSERT INTO dim.DimProject (project_id, project_name, project_manager, status, start_date, end_date)
            SELECT DISTINCT 
                project_id, project_name, project_manager, status, start_date, end_date
            FROM staging.FinancialTransaction f
            WHERE NOT EXISTS (
                SELECT 1 FROM dim.DimProject d 
                WHERE d.project_id = f.project_id
            )
        """)
        
        # Load Account Dimension
        cursor.execute("""
            INSERT INTO dim.DimAccount (account_id, account_name, account_type, budget_category)
            SELECT DISTINCT 
                account_id, account_name, account_type, budget_category
            FROM staging.FinancialTransaction f
            WHERE NOT EXISTS (
                SELECT 1 FROM dim.DimAccount d 
                WHERE d.account_id = f.account_id
            )
        """)
        
        conn.commit()
        conn.close()
        
        logging.info("Dimension tables loaded successfully")
        return "Dimension load completed"
        
    except Exception as e:
        logging.error(f"Error loading dimensions: {str(e)}")
        raise

def load_fact_tables():
    """Load fact tables from staging data"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        # Load FactEquipmentUsage
        cursor.execute("""
            INSERT INTO fact.FactEquipmentUsage (
                equipment_usage_id, time_id, site_id, equipment_id, 
                operating_hours, downtime_hours, fuel_consumption, maintenance_cost
            )
            SELECT DISTINCT
                e.equipment_usage_id,
                e.time_id,
                s.site_id,
                eq.equipment_id,
                e.operating_hours,
                e.downtime_hours,
                e.fuel_consumption,
                e.maintenance_cost
            FROM staging.EquipmentUsage e
            JOIN dim.DimSite s ON e.site_name = s.site_name
            JOIN dim.DimEquipment eq ON e.equipment_name = eq.equipment_name
            WHERE NOT EXISTS (
                SELECT 1 FROM fact.FactEquipmentUsage f 
                WHERE f.equipment_usage_id = e.equipment_usage_id
            )
        """)
        
        # Load FactProduction
        cursor.execute("""
            INSERT INTO fact.FactProduction (
                production_id, time_id, site_id, material_id, employee_id, shift_id,
                produced_volume, unit_cost
            )
            SELECT DISTINCT
                p.production_id,
                p.time_id,
                s.site_id,
                m.material_id,
                emp.employee_id,
                sh.shift_id,
                p.produced_volume,
                p.unit_cost
            FROM staging.Production p
            JOIN dim.DimSite s ON p.site_name = s.site_name
            JOIN dim.DimMaterial m ON p.material_id = m.material_id
            JOIN dim.DimEmployee emp ON p.employee_id = emp.employee_id
            JOIN dim.DimShift sh ON p.shift_id = sh.shift_id
            WHERE NOT EXISTS (
                SELECT 1 FROM fact.FactProduction f 
                WHERE f.production_id = p.production_id
            )
        """)
        
        # Load FactFinancialTransaction
        cursor.execute("""
            INSERT INTO fact.FactFinancialTransaction (
                transaction_id, time_id, site_id, project_id, account_id,
                budgeted_cost, actual_cost, variance
            )
            SELECT DISTINCT
                f.id,
                f.time_id,
                s.site_id,
                pr.project_id,
                acc.account_id,
                f.budgeted_cost,
                f.actual_cost,
                f.variance
            FROM staging.FinancialTransaction f
            JOIN dim.DimSite s ON f.site_name = s.site_name
            JOIN dim.DimProject pr ON f.project_id = pr.project_id
            JOIN dim.DimAccount acc ON f.account_id = acc.account_id
            WHERE NOT EXISTS (
                SELECT 1 FROM fact.FactFinancialTransaction ft 
                WHERE ft.transaction_id = f.id
            )
        """)
        
        conn.commit()
        conn.close()
        
        logging.info("Fact tables loaded successfully")
        return "Fact tables load completed"
        
    except Exception as e:
        logging.error(f"Error loading fact tables: {str(e)}")
        raise

def data_quality_check():
    """Perform data quality checks"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        # Check record counts
        checks = {
            'DimTime': 'SELECT COUNT(*) FROM dim.DimTime',
            'DimSite': 'SELECT COUNT(*) FROM dim.DimSite',
            'DimEquipment': 'SELECT COUNT(*) FROM dim.DimEquipment',
            'DimMaterial': 'SELECT COUNT(*) FROM dim.DimMaterial',
            'DimEmployee': 'SELECT COUNT(*) FROM dim.DimEmployee',
            'DimShift': 'SELECT COUNT(*) FROM dim.DimShift',
            'DimProject': 'SELECT COUNT(*) FROM dim.DimProject',
            'DimAccount': 'SELECT COUNT(*) FROM dim.DimAccount',
            'FactEquipmentUsage': 'SELECT COUNT(*) FROM fact.FactEquipmentUsage',
            'FactProduction': 'SELECT COUNT(*) FROM fact.FactProduction',
            'FactFinancialTransaction': 'SELECT COUNT(*) FROM fact.FactFinancialTransaction'
        }
        
        results = {}
        for table, query in checks.items():
            cursor.execute(query)
            count = cursor.fetchone()[0]
            results[table] = count
            logging.info(f"{table}: {count} records")
        
        # Check for data quality issues
        cursor.execute("""
            SELECT COUNT(*) as null_sites 
            FROM fact.FactProduction f
            LEFT JOIN dim.DimSite s ON f.site_id = s.site_id
            WHERE s.site_id IS NULL
        """)
        null_sites = cursor.fetchone()[0]
        
        if null_sites > 0:
            logging.warning(f"Found {null_sites} records with invalid site references")
        
        conn.close()
        
        logging.info("Data quality check completed")
        return f"Quality check completed. Results: {results}"
        
    except Exception as e:
        logging.error(f"Error in data quality check: {str(e)}")
        raise

# Define tasks
extract_staging_task = PythonOperator(
    task_id='extract_and_load_to_staging',
    python_callable=extract_and_load_to_staging,
    dag=dag,
)

transform_dimensions_task = PythonOperator(
    task_id='transform_and_load_dimensions',
    python_callable=transform_and_load_dimensions,
    dag=dag,
)

load_facts_task = PythonOperator(
    task_id='load_fact_tables',
    python_callable=load_fact_tables,
    dag=dag,
)

data_quality_task = PythonOperator(
    task_id='data_quality_check',
    python_callable=data_quality_check,
    dag=dag,
)

# Define task dependencies
extract_staging_task >> transform_dimensions_task >> load_facts_task >> data_quality_task
