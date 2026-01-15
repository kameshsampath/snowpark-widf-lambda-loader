--jinja
-- =============================================================================
-- Snowpark WIDF Lambda Loader - Database Setup
-- =============================================================================
-- Simple setup for the keyless ETL demo
-- =============================================================================

-- =============================================================================
-- Step 1: Create Role
-- =============================================================================

CREATE ROLE IF NOT EXISTS <%sa_role%>
    COMMENT = 'Role for WIDF Lambda Loader demo';

SET current_user = (SELECT CURRENT_USER());
GRANT ROLE <%sa_role%> TO USER IDENTIFIER($current_user);

-- =============================================================================
-- Step 2: Create Database
-- =============================================================================

CREATE DATABASE IF NOT EXISTS <%db_name%>
    COMMENT = 'Database for WIDF keyless ETL demo';

GRANT OWNERSHIP ON DATABASE <%db_name%> TO ROLE <%sa_role%>;

-- =============================================================================
-- Step 3: Setup Schema
-- =============================================================================

USE ROLE <%sa_role%>;
USE DATABASE <%db_name%>;

CREATE SCHEMA IF NOT EXISTS <%schema_name%>;
USE SCHEMA <%schema_name%>;

-- =============================================================================
-- Step 4: Create Target Table
-- =============================================================================

CREATE TABLE IF NOT EXISTS RAW_DATA (
    id              INTEGER AUTOINCREMENT,
    source_file     VARCHAR,
    payload         VARIANT,
    loaded_at       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    loaded_by       VARCHAR DEFAULT CURRENT_USER()
)
COMMENT = 'Raw data loaded via Lambda WIDF (keyless!)';

-- =============================================================================
-- Step 5: Grant Warehouse Usage
-- =============================================================================

USE ROLE ACCOUNTADMIN;
GRANT USAGE ON WAREHOUSE <%warehouse%> TO ROLE <%sa_role%>;

-- =============================================================================
-- Verification
-- =============================================================================

USE ROLE <%sa_role%>;
USE DATABASE <%db_name%>;
USE SCHEMA <%schema_name%>;

SHOW TABLES;

SELECT 
    '✅ Setup complete!' AS status,
    '<%db_name%>' AS database,
    '<%schema_name%>' AS schema,
    '<%sa_role%>' AS role;
