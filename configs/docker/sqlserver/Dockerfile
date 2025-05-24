# PT XYZ Data Warehouse - SQL Server Container
FROM mcr.microsoft.com/mssql/server:2022-latest

# Set environment variables
ENV ACCEPT_EULA=Y
ENV MSSQL_PID=Developer

# Create directories for initialization
USER root
RUN mkdir -p /docker-entrypoint-initdb.d
RUN mkdir -p /data
RUN mkdir -p /scripts

# Copy initialization scripts
COPY ./init-scripts/ /docker-entrypoint-initdb.d/
COPY ./custom-entrypoint.sh /custom-entrypoint.sh

# Make scripts executable
RUN chmod +x /docker-entrypoint-initdb.d/*.sh
RUN chmod +x /custom-entrypoint.sh

# Switch back to mssql user
USER mssql

# Use custom entrypoint
ENTRYPOINT ["/custom-entrypoint.sh"]
