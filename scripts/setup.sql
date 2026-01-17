--jinja
-- Snowpark WIDF Lambda Loader - Database Setup
-- Creates role, database, schema, table, and dynamic table

-- Create Role
CREATE ROLE IF NOT EXISTS <%sa_role%>
    COMMENT = 'Role for WIDF Lambda Loader demo';

SET current_user = (SELECT CURRENT_USER());
GRANT ROLE <%sa_role%> TO USER IDENTIFIER($current_user);

-- Create Database
CREATE DATABASE IF NOT EXISTS <%db_name%>
    COMMENT = 'Database for WIDF keyless ETL demo';

GRANT OWNERSHIP ON DATABASE <%db_name%> TO ROLE <%sa_role%>;

-- Grant Warehouse Usage (needed for Dynamic Table)
GRANT USAGE ON WAREHOUSE <%warehouse%> TO ROLE <%sa_role%>;

-- Setup Schema and Tables with SA_ROLE
USE ROLE <%sa_role%>;
USE DATABASE <%db_name%>;
USE WAREHOUSE <%warehouse%>;

CREATE SCHEMA IF NOT EXISTS <%schema_name%>;
USE SCHEMA <%schema_name%>;

-- Create Target Table (Landing Zone)
CREATE TABLE IF NOT EXISTS RAW_DATA (
    id              INTEGER AUTOINCREMENT,
    source_file     VARCHAR,
    payload         VARIANT,
    loaded_at       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    loaded_by       VARCHAR DEFAULT CURRENT_USER()
)
COMMENT = 'Raw data loaded via Lambda WIDF';

-- Dynamic Table: Real-time analytics on data landing
-- Auto-refreshes when new data arrives in RAW_DATA
CREATE OR REPLACE DYNAMIC TABLE DAILY_SUMMARY
    TARGET_LAG = '1 minute'
    WAREHOUSE = <%warehouse%>
AS
SELECT
    DATE(loaded_at) AS load_date,
    COUNT(DISTINCT source_file) AS files_loaded,
    COUNT(*) AS total_events,
    payload:action::STRING AS action,
    COUNT(DISTINCT payload:user_id::STRING) AS unique_users,
    SUM(payload:amount::FLOAT) AS total_amount
FROM RAW_DATA
GROUP BY DATE(loaded_at), payload:action::STRING;

-- Verify Setup
SHOW TABLES;
SHOW DYNAMIC TABLES;

SELECT 
    'Setup complete' AS status,
    '<%db_name%>' AS database,
    '<%schema_name%>' AS schema,
    '<%sa_role%>' AS role;
