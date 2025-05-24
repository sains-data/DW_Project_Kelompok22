#!/bin/bash

# PT XYZ Data Warehouse - Custom SQL Server Entrypoint
# This script starts SQL Server and runs initialization scripts

echo "🚀 Starting PT XYZ SQL Server container..."

# Start SQL Server in the background
echo "📊 Starting SQL Server..."
/opt/mssql/bin/sqlservr &

# Store the SQL Server process ID
SQLSERVER_PID=$!

# Function to cleanup on exit
cleanup() {
    echo "🛑 Shutting down SQL Server..."
    kill $SQLSERVER_PID
    wait $SQLSERVER_PID
    echo "✅ SQL Server stopped"
}

# Set up signal handling
trap cleanup SIGTERM SIGINT

# Wait a bit for SQL Server to start
sleep 30

# Run initialization scripts if they exist
if [ -f "/docker-entrypoint-initdb.d/init-db.sh" ]; then
    echo "🔧 Running initialization scripts..."
    bash /docker-entrypoint-initdb.d/init-db.sh
    
    if [ $? -eq 0 ]; then
        echo "✅ Initialization completed successfully"
    else
        echo "❌ Initialization failed"
    fi
else
    echo "⚠️  No initialization scripts found"
fi

# Keep the container running
echo "🎯 SQL Server is ready and running..."
wait $SQLSERVER_PID
