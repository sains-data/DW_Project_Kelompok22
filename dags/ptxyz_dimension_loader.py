from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
import pandas as pd
import pyodbc
import logging

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
    conn_str = (
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=sqlserver,1433;"
        "DATABASE=DW_PTXYZ;"
        "UID=sa;"
        "PWD=PTXYZDataWarehouse2025!;"
    )
    return pyodbc.connect(conn_str)

def load_dim_time():
    """Load time dimension with date range"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        # Generate time dimension data
        start_date = datetime(2020, 1, 1)
        end_date = datetime(2030, 12, 31)
        date_range = pd.date_range(start=start_date, end=end_date, freq='D')
        
        for date in date_range:
            time_key = int(date.strftime('%Y%m%d'))
            cursor.execute("""
                IF NOT EXISTS (SELECT 1 FROM dim_time WHERE time_key = ?)
                INSERT INTO dim_time (time_key, full_date, day, month, year, day_name)
                VALUES (?, ?, ?, ?, ?, ?)
            """, time_key, time_key, date, date.day, date.month, date.year, date.strftime('%A'))
        
        conn.commit()
        conn.close()
        logging.info("Time dimension loaded successfully")
        
    except Exception as e:
        logging.error(f"Error loading time dimension: {e}")
        raise

def load_dim_site():
    """Load site dimension from configuration"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        # Sample site data - replace with actual data source
        sites = [
            ('Site A - Main Pit', 'Central Region', -6.2088, 106.8456),
            ('Site B - North Pit', 'Northern Region', -6.1500, 106.8000),
            ('Site C - Processing Plant', 'Central Region', -6.2200, 106.8600),
        ]
        
        for site_name, region, lat, lng in sites:
            cursor.execute("""
                IF NOT EXISTS (SELECT 1 FROM dim_site WHERE site_name = ?)
                INSERT INTO dim_site (site_name, region, latitude, longitude)
                VALUES (?, ?, ?, ?)
            """, site_name, site_name, region, lat, lng)
        
        conn.commit()
        conn.close()
        logging.info("Site dimension loaded successfully")
        
    except Exception as e:
        logging.error(f"Error loading site dimension: {e}")
        raise

def load_dim_material():
    """Load material dimension"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        # Sample material data
        materials = [
            ('Coal', 'Bituminous', 'Tons'),
            ('Iron Ore', 'Hematite', 'Tons'),
            ('Copper Ore', 'Chalcopyrite', 'Tons'),
            ('Gold Ore', 'Native Gold', 'Ounces'),
            ('Limestone', 'Calcite', 'Tons'),
        ]
        
        for material_name, material_type, unit in materials:
            cursor.execute("""
                IF NOT EXISTS (SELECT 1 FROM dim_material WHERE material_name = ?)
                INSERT INTO dim_material (material_name, material_type, unit_of_measure)
                VALUES (?, ?, ?)
            """, material_name, material_name, material_type, unit)
        
        conn.commit()
        conn.close()
        logging.info("Material dimension loaded successfully")
        
    except Exception as e:
        logging.error(f"Error loading material dimension: {e}")
        raise

def load_dim_shift():
    """Load shift dimension"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        # Standard mining shifts
        shifts = [
            ('Day Shift', '06:00', '14:00'),
            ('Evening Shift', '14:00', '22:00'),
            ('Night Shift', '22:00', '06:00'),
        ]
        
        for shift_name, start_time, end_time in shifts:
            cursor.execute("""
                IF NOT EXISTS (SELECT 1 FROM dim_shift WHERE shift_name = ?)
                INSERT INTO dim_shift (shift_name, start_time, end_time)
                VALUES (?, ?, ?)
            """, shift_name, shift_name, start_time, end_time)
        
        conn.commit()
        conn.close()
        logging.info("Shift dimension loaded successfully")
        
    except Exception as e:
        logging.error(f"Error loading shift dimension: {e}")
        raise

def load_dim_equipment():
    """Load equipment dimension"""
    try:
        conn = get_sql_connection()
        cursor = conn.cursor()
        
        # Sample equipment data
        equipment = [
            ('EXC-001', 'Excavator', 'CAT 390F', 2.5),
            ('EXC-002', 'Excavator', 'Komatsu PC800', 3.2),
            ('TRK-001', 'Haul Truck', 'CAT 777G', 100.0),
            ('TRK-002', 'Haul Truck', 'Komatsu HD785', 91.0),
            ('DRL-001', 'Drill', 'Atlas Copco ROC T35', 0.0),
        ]
        
        for eq_name, eq_type, model, capacity in equipment:
            cursor.execute("""
                IF NOT EXISTS (SELECT 1 FROM dim_equipment WHERE equipment_name = ?)
                INSERT INTO dim_equipment (equipment_name, equipment_type, model, capacity)
                VALUES (?, ?, ?, ?)
            """, eq_name, eq_name, eq_type, model, capacity)
        
        conn.commit()
        conn.close()
        logging.info("Equipment dimension loaded successfully")
        
    except Exception as e:
        logging.error(f"Error loading equipment dimension: {e}")
        raise

# Define tasks
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

# Validation task
validate_dimensions = BashOperator(
    task_id='validate_dimensions',
    bash_command="""
    echo "Validating dimension tables..."
    # Add SQL validation queries here
    """,
    dag=dag,
)

# Set task dependencies
[load_time_task, load_site_task, load_material_task, load_shift_task, load_equipment_task] >> validate_dimensions
