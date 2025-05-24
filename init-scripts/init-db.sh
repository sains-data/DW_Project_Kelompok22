#!/bin/bash

# Wait for SQL Server to be ready
sleep 30

# Initialize the data warehouse
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P PTXYZDataWarehouse2025! -Q "
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'DW_PTXYZ')
BEGIN
    CREATE DATABASE DW_PTXYZ;
END
"

# Execute the main schema script
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P PTXYZDataWarehouse2025! -d DW_PTXYZ -i /scripts/DW_PTXYZ_Misi3_Script\(1\).sql
