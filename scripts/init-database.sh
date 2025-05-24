#!/bin/bash

# PT XYZ Data Warehouse - Database Initialization Script
# This script can be run manually or via Docker to initialize the database

set -e

# Load environment variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Default values if not set
SQLSERVER_HOST=${SQLSERVER_HOST:-localhost}
SQLSERVER_PORT=${SQLSERVER_PORT:-1433}
SA_PASSWORD=${MSSQL_SA_PASSWORD:-YourSecurePassword123!}

echo "🚀 PT XYZ Data Warehouse - Database Initialization"
echo "=================================================="
echo "Host: $SQLSERVER_HOST:$SQLSERVER_PORT"
echo "Database: PTXYZ_DataWarehouse"
echo ""

# Function to test SQL Server connection
test_connection() {
    docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "SELECT 1" -C -N > /dev/null 2>&1
    return $?
}

# Function to run SQL command via Docker
run_sql() {
    local query="$1"
    docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C -N -Q "$query"
}

# Function to run SQL file via Docker
run_sql_file() {
    local file="$1"
    local database="$2"
    
    if [ -n "$database" ]; then
        docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -d "$database" -C -N -i "$file"
    else
        docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C -N -i "$file"
    fi
}

# Check if SQL Server container is running
if ! docker ps | grep -q ptxyz_sqlserver; then
    echo "❌ SQL Server container (ptxyz_sqlserver) is not running!"
    echo "Please start the Docker services first: docker-compose up -d sqlserver"
    exit 1
fi

# Test connection
echo "🔍 Testing SQL Server connection..."
MAX_RETRIES=10
RETRY_COUNT=0

while ! test_connection && [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "   Attempt $RETRY_COUNT/$MAX_RETRIES - SQL Server not ready yet, waiting 5 seconds..."
    sleep 5
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "❌ Failed to connect to SQL Server after $MAX_RETRIES attempts"
    exit 1
fi

echo "✅ SQL Server connection successful!"

# Create the PTXYZ_DataWarehouse database
echo ""
echo "📊 Creating PTXYZ_DataWarehouse database..."
run_sql "
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'PTXYZ_DataWarehouse')
BEGIN
    CREATE DATABASE PTXYZ_DataWarehouse;
    PRINT 'Database PTXYZ_DataWarehouse created successfully';
END
ELSE
BEGIN
    PRINT 'Database PTXYZ_DataWarehouse already exists';
END
"

if [ $? -eq 0 ]; then
    echo "✅ Database creation completed"
else
    echo "❌ Database creation failed"
    exit 1
fi

# Copy schema file to container and execute it
echo ""
echo "🏗️  Creating database schema..."
docker cp ./init-scripts/create-schema.sql ptxyz_sqlserver:/tmp/create-schema.sql
docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -d PTXYZ_DataWarehouse -C -N -i /tmp/create-schema.sql

if [ $? -eq 0 ]; then
    echo "✅ Schema creation completed successfully"
else
    echo "❌ Schema creation failed"
    exit 1
fi

# Verify the schema was created
echo ""
echo "🔍 Verifying schema creation..."
run_sql "
USE PTXYZ_DataWarehouse;
SELECT 
    'Schema: ' + s.name as info
FROM sys.schemas s 
WHERE s.name IN ('dim', 'fact', 'staging')
UNION ALL
SELECT 
    'Table: ' + s.name + '.' + t.name as info
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name IN ('dim', 'fact', 'staging')
ORDER BY info;
"

echo ""
echo "🎉 PT XYZ Data Warehouse initialization completed successfully!"
echo ""
echo "📈 Next steps:"
echo "   1. Run ETL pipeline: python standalone_etl.py"
echo "   2. Access Airflow UI: http://localhost:8080"
echo "   3. Access dashboards:"
echo "      - Grafana: http://localhost:3000"
echo "      - Superset: http://localhost:8088" 
echo "      - Metabase: http://localhost:3001"
echo ""
