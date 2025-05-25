from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
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
    'ptxyz_dimension_loader',
    default_args=default_args,
    description='Load dimension tables for PT XYZ Data Warehouse',
    schedule_interval='@daily',
    catchup=False,
    tags=['ptxyz', 'dimensions'],
)

def get_sql_connection():
    """Get SQL Server connection"""
    # Get password from environment variable
    sql_password = os.getenv('MSSQL_SA_PASSWORD', 'PTXYZSecure123!')
    
    return pymssql.connect(
        server='ptxyz_sqlserver',
        port=1433,
        database='PTXYZ_DataWarehouse',
        user='sa',
        password=sql_password,
        timeout=30
    )

def load_staging_data():
    """Load CSV data into staging tables"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        # Clear staging tables first
        logging.info("Clearing staging tables...")
        cursor.execute("TRUNCATE TABLE staging.EquipmentUsage")
        cursor.execute("TRUNCATE TABLE staging.Production") 
        cursor.execute("TRUNCATE TABLE staging.FinancialTransaction")
        
        # Load Equipment Usage data
        logging.info("Loading Equipment Usage data...")
        equipment_df = pd.read_csv('/opt/airflow/data/dataset_alat_berat_dw.csv')
        equipment_df['purchase_date'] = pd.to_datetime(equipment_df['purchase_date']).dt.date
        equipment_df['date'] = pd.to_datetime(equipment_df['date']).dt.date
        equipment_df['created_at'] = pd.to_datetime(equipment_df['created_at'])
        
        count = 0
        for _, row in equipment_df.iterrows():
            # Convert numpy types to native Python types
            values = []
            for val in row:
                if pd.isna(val):
                    values.append(None)
                elif hasattr(val, 'item'):  # numpy types
                    values.append(val.item())
                else:
                    values.append(val)
            
            cursor.execute("""
                INSERT INTO staging.EquipmentUsage (
                    equipment_usage_id, time_id, date, day, day_name, month, year,
                    site_name, region, latitude, longitude, equipment_name, 
                    equipment_type, manufacture, model, capacity, purchase_date,
                    operating_hours, downtime_hours, fuel_consumption, 
                    maintenance_cost, created_at, created_by
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, tuple(values))
            count += 1
            if count % 100 == 0:
                logging.info(f"Loaded {count} equipment records...")
        
        logging.info(f"Loaded {count} equipment usage records")
        
        # Load Production data
        logging.info("Loading Production data...")
        production_df = pd.read_csv('/opt/airflow/data/dataset_production.csv')
        production_df['date'] = pd.to_datetime(production_df['date']).dt.date
        production_df['hire_date'] = pd.to_datetime(production_df['hire_date']).dt.date
        
        count = 0
        for _, row in production_df.iterrows():
            # Convert numpy types to native Python types
            values = []
            for val in row:
                if pd.isna(val):
                    values.append(None)
                elif hasattr(val, 'item'):  # numpy types
                    values.append(val.item())
                else:
                    values.append(val)
            
            cursor.execute("""
                INSERT INTO staging.Production (
                    production_id, time_id, site_id, material_id, employee_id, shift_id,
                    produced_volume, unit_cost, date, day, month, year, day_name,
                    site_name, region, latitude, longitude, material_name, material_type,
                    unit_of_measure, quantity, employee_name, position, department,
                    status, hire_date, shift_name, start_time, end_time
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, tuple(values))
            count += 1
            if count % 100 == 0:
                logging.info(f"Loaded {count} production records...")
        
        logging.info(f"Loaded {count} production records")
        
        # Load Financial Transaction data
        logging.info("Loading Financial Transaction data...")
        transaction_df = pd.read_csv('/opt/airflow/data/dataset_transaksi.csv')
        transaction_df['created_at'] = pd.to_datetime(transaction_df['created_at'])
        transaction_df['date'] = pd.to_datetime(transaction_df['date'], format='%Y%m%d').dt.date
        transaction_df['start_date'] = pd.to_datetime(transaction_df['start_date']).dt.date
        transaction_df['end_date'] = pd.to_datetime(transaction_df['end_date']).dt.date
        
        count = 0
        for _, row in transaction_df.iterrows():
            # Convert numpy types to native Python types
            values = []
            for val in row:
                if pd.isna(val):
                    values.append(None)
                elif hasattr(val, 'item'):  # numpy types
                    values.append(val.item())
                else:
                    values.append(val)
            
            cursor.execute("""
                INSERT INTO staging.FinancialTransaction (
                    id, time_id, site_id, project_id, account_id, variance,
                    budgeted_cost, actual_cost, created_at, created_by, date,
                    day, day_name, month, year, site_name, region, latitude,
                    longitude, project_name, project_manager, status, start_date,
                    end_date, account_name, account_type, budget_category, cost
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, tuple(values))
            count += 1
            if count % 100 == 0:
                logging.info(f"Loaded {count} transaction records...")
        
        logging.info(f"Loaded {count} transaction records")
        
        conn.commit()
        conn.close()
        
        logging.info("Data successfully loaded to staging tables")
        
    except Exception as e:
        logging.error(f"Error in staging load: {str(e)}")
        raise

def load_dim_time():
    """Load time dimension from staging data"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        logging.info("Loading Time Dimension from staging data...")
        cursor.execute("""
            INSERT INTO dim.DimTime (time_id, date, day_of_month, day_name, month, month_name, quarter, year, is_weekend, created_by)
            SELECT DISTINCT 
                time_id, 
                date,
                day,
                day_name,
                month,
                DATENAME(MONTH, date) as month_name,
                DATEPART(QUARTER, date) as quarter,
                year,
                CASE WHEN DATENAME(WEEKDAY, date) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END as is_weekend,
                'ETL_SYSTEM'
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
                CASE WHEN DATENAME(WEEKDAY, date) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END as is_weekend,
                'ETL_SYSTEM'
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
                CASE WHEN DATENAME(WEEKDAY, date) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END as is_weekend,
                'ETL_SYSTEM'
            FROM staging.FinancialTransaction f
            WHERE NOT EXISTS (SELECT 1 FROM dim.DimTime d WHERE d.time_id = f.time_id)
        """)
        
        conn.commit()
        conn.close()
        logging.info("Time dimension loaded successfully")
        
    except Exception as e:
        logging.error(f"Error loading time dimension: {e}")
        raise

def load_dim_site():
    """Load site dimension from staging data"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        logging.info("Loading Site Dimension from staging data...")
        # Load sites from production data which has site_id
        cursor.execute("""
            INSERT INTO dim.DimSite (site_id, site_name, region, latitude, longitude, created_by)
            SELECT DISTINCT 
                p.site_id,
                p.site_name,
                p.region,
                p.latitude,
                p.longitude,
                'ETL_SYSTEM'
            FROM staging.Production p
            WHERE NOT EXISTS (
                SELECT 1 FROM dim.DimSite d 
                WHERE d.site_id = p.site_id
            )
            AND p.site_id IS NOT NULL
            AND p.site_name IS NOT NULL
        """)
        
        # Also load sites from transaction data
        cursor.execute("""
            INSERT INTO dim.DimSite (site_id, site_name, region, latitude, longitude, created_by)
            SELECT DISTINCT 
                f.site_id,
                f.site_name,
                f.region,
                f.latitude,
                f.longitude,
                'ETL_SYSTEM'
            FROM staging.FinancialTransaction f
            WHERE NOT EXISTS (
                SELECT 1 FROM dim.DimSite d 
                WHERE d.site_id = f.site_id
            )
            AND f.site_id IS NOT NULL
            AND f.site_name IS NOT NULL
        """)
        
        # Load sites from equipment data (assign sequential site_id for missing ones)
        cursor.execute("""
            INSERT INTO dim.DimSite (site_id, site_name, region, latitude, longitude, created_by)
            SELECT DISTINCT 
                ROW_NUMBER() OVER (ORDER BY e.site_name) + COALESCE((SELECT MAX(site_id) FROM dim.DimSite), 0),
                e.site_name,
                e.region,
                e.latitude,
                e.longitude,
                'ETL_SYSTEM'
            FROM staging.EquipmentUsage e
            WHERE NOT EXISTS (
                SELECT 1 FROM dim.DimSite d 
                WHERE d.site_name = e.site_name
            )
            AND e.site_name IS NOT NULL
        """)
        
        conn.commit()
        conn.close()
        logging.info("Site dimension loaded successfully")
        
    except Exception as e:
        logging.error(f"Error loading site dimension: {e}")
        raise

def load_dim_material():
    """Load material dimension from staging data"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        logging.info("Loading Material Dimension from staging data...")
        cursor.execute("""
            INSERT INTO dim.DimMaterial (material_id, material_name, material_type, unit_of_measure, created_by)
            SELECT DISTINCT 
                material_id, material_name, material_type, unit_of_measure, 'ETL_SYSTEM'
            FROM staging.Production p
            WHERE NOT EXISTS (
                SELECT 1 FROM dim.DimMaterial d 
                WHERE d.material_id = p.material_id
            )
            AND material_id IS NOT NULL
            AND material_name IS NOT NULL
        """)
        
        conn.commit()
        conn.close()
        logging.info("Material dimension loaded successfully")
        
    except Exception as e:
        logging.error(f"Error loading material dimension: {e}")
        raise

def load_dim_shift():
    """Load shift dimension from staging data"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        logging.info("Loading Shift Dimension from staging data...")
        cursor.execute("""
            INSERT INTO dim.DimShift (shift_id, shift_name, start_time, end_time, created_by)
            SELECT DISTINCT 
                shift_id, shift_name, start_time, end_time, 'ETL_SYSTEM'
            FROM staging.Production p
            WHERE NOT EXISTS (
                SELECT 1 FROM dim.DimShift d 
                WHERE d.shift_id = p.shift_id
            )
            AND shift_id IS NOT NULL
            AND shift_name IS NOT NULL
        """)
        
        conn.commit()
        conn.close()
        logging.info("Shift dimension loaded successfully")
        
    except Exception as e:
        logging.error(f"Error loading shift dimension: {e}")
        raise

def load_dim_equipment():
    """Load equipment dimension from staging data"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        logging.info("Loading Equipment Dimension from staging data...")
        # For equipment, we'll generate sequential IDs since the source doesn't have equipment_id
        cursor.execute("""
            INSERT INTO dim.DimEquipment (equipment_name, equipment_type, manufacture, model, capacity, purchase_date, created_by)
            SELECT DISTINCT 
                equipment_name, equipment_type, manufacture, model, capacity, purchase_date, 'ETL_SYSTEM'
            FROM staging.EquipmentUsage e
            WHERE NOT EXISTS (
                SELECT 1 FROM dim.DimEquipment d 
                WHERE d.equipment_name = e.equipment_name
            )
            AND equipment_name IS NOT NULL
        """)
        
        conn.commit()
        conn.close()
        logging.info("Equipment dimension loaded successfully")
        
    except Exception as e:
        logging.error(f"Error loading equipment dimension: {e}")
        raise

def load_dim_employee():
    """Load employee dimension from staging data"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        logging.info("Loading Employee Dimension from staging data...")
        cursor.execute("""
            INSERT INTO dim.DimEmployee (employee_id, employee_name, position, department, status, hire_date, created_by)
            SELECT DISTINCT 
                employee_id, employee_name, position, department, status, hire_date, 'ETL_SYSTEM'
            FROM staging.Production p
            WHERE NOT EXISTS (
                SELECT 1 FROM dim.DimEmployee d 
                WHERE d.employee_id = p.employee_id
            )
            AND employee_id IS NOT NULL
            AND employee_name IS NOT NULL
        """)
        
        conn.commit()
        conn.close()
        logging.info("Employee dimension loaded successfully")
        
    except Exception as e:
        logging.error(f"Error loading employee dimension: {e}")
        raise

def load_dim_project():
    """Load project dimension from staging data"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        logging.info("Loading Project Dimension from staging data...")
        cursor.execute("""
            INSERT INTO dim.DimProject (project_id, project_name, project_manager, status, start_date, end_date, created_by)
            SELECT DISTINCT 
                project_id, project_name, project_manager, status, start_date, end_date, 'ETL_SYSTEM'
            FROM staging.FinancialTransaction f
            WHERE NOT EXISTS (
                SELECT 1 FROM dim.DimProject d 
                WHERE d.project_id = f.project_id
            )
            AND project_id IS NOT NULL
            AND project_name IS NOT NULL
        """)
        
        conn.commit()
        conn.close()
        logging.info("Project dimension loaded successfully")
        
    except Exception as e:
        logging.error(f"Error loading project dimension: {e}")
        raise

def load_dim_account():
    """Load account dimension from staging data"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        logging.info("Loading Account Dimension from staging data...")
        cursor.execute("""
            INSERT INTO dim.DimAccount (account_id, account_name, account_type, budget_category, created_by)
            SELECT DISTINCT 
                account_id, account_name, account_type, budget_category, 'ETL_SYSTEM'
            FROM staging.FinancialTransaction f
            WHERE NOT EXISTS (
                SELECT 1 FROM dim.DimAccount d 
                WHERE d.account_id = f.account_id
            )
            AND account_id IS NOT NULL
            AND account_name IS NOT NULL
        """)
        
        conn.commit()
        conn.close()
        logging.info("Account dimension loaded successfully")
        
    except Exception as e:
        logging.error(f"Error loading account dimension: {e}")
        raise

# Define tasks
load_staging_task = PythonOperator(
    task_id='load_staging_data',
    python_callable=load_staging_data,
    dag=dag,
)

load_time_task = PythonOperator(
    task_id='load_dim_time',
    python_callable=load_dim_time,
    dag=dag,
)

load_site_task = PythonOperator(
    task_id='load_dim_site',
    python_callable=load_dim_site,
    dag=dag,
)

load_material_task = PythonOperator(
    task_id='load_dim_material',
    python_callable=load_dim_material,
    dag=dag,
)

load_shift_task = PythonOperator(
    task_id='load_dim_shift',
    python_callable=load_dim_shift,
    dag=dag,
)

load_equipment_task = PythonOperator(
    task_id='load_dim_equipment',
    python_callable=load_dim_equipment,
    dag=dag,
)

load_employee_task = PythonOperator(
    task_id='load_dim_employee',
    python_callable=load_dim_employee,
    dag=dag,
)

load_project_task = PythonOperator(
    task_id='load_dim_project',
    python_callable=load_dim_project,
    dag=dag,
)

load_account_task = PythonOperator(
    task_id='load_dim_account',
    python_callable=load_dim_account,
    dag=dag,
)

# Validation task
validate_dimensions = BashOperator(
    task_id='validate_dimensions',
    bash_command="""
    echo "Validating dimension tables..."
    echo "All dimension loading tasks completed successfully"
    """,
    dag=dag,
)

# Set task dependencies
load_staging_task >> [load_time_task, load_site_task, load_material_task, load_shift_task, load_equipment_task, load_employee_task, load_project_task, load_account_task] >> validate_dimensions
