#!/bin/bash

# PT XYZ Data Warehouse - Database Initialization Script
# This script initializes the data warehouse database and schema

echo "🚀 Starting PT XYZ Data Warehouse initialization..."

# Wait for SQL Server to be ready
echo "⏳ Waiting for SQL Server to be ready..."
sleep 45

# Maximum retry attempts
MAX_RETRIES=10
RETRY_COUNT=0

# Function to test SQL Server connection
test_connection() {
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -Q "SELECT 1" -C -N > /dev/null 2>&1
    return $?
}

# Wait for SQL Server to be fully ready
echo "🔍 Testing SQL Server connection..."
while ! test_connection && [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "   Attempt $RETRY_COUNT/$MAX_RETRIES - SQL Server not ready yet, waiting 10 seconds..."
    sleep 10
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "❌ Failed to connect to SQL Server after $MAX_RETRIES attempts"
    exit 1
fi

echo "✅ SQL Server is ready!"

# Create the PTXYZ_DataWarehouse database
echo "📊 Creating PTXYZ_DataWarehouse database..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -C -N -Q "
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

# Execute the schema creation script
echo "🏗️  Creating database schema..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -d PTXYZ_DataWarehouse -C -N -i /docker-entrypoint-initdb.d/create-schema.sql

if [ $? -eq 0 ]; then
    echo "✅ Schema creation completed successfully"
else
    echo "❌ Schema creation failed"
    exit 1
fi

# Verify the schema was created
echo "🔍 Verifying schema creation..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -d PTXYZ_DataWarehouse -C -N -Q "
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

echo "🎉 PT XYZ Data Warehouse initialization completed successfully!"
echo "📈 Ready for ETL operations!"
