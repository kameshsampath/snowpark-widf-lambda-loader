--jinja
-- =============================================================================
-- 🔑 Snowflake WIDF Setup for AWS Lambda
-- =============================================================================
-- This creates a SERVICE user that authenticates via Lambda's IAM role.
-- NO passwords, NO secrets - just IAM trust!
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- Variables
SET aws_account_id = '<%aws_account_id%>';
SET lambda_role_name = '<%lambda_role_name%>';
SET snowflake_user = '<%snowflake_user%>';
SET snowflake_role = '<%sa_role%>';
SET snowflake_warehouse = '<%snowflake_warehouse%>';
SET demo_database = '<%demo_database%>';
SET demo_schema = '<%demo_schema%>';

-- =============================================================================
-- Create WIDF Service User
-- =============================================================================
-- 🔑 THE MAGIC: This user trusts the Lambda's IAM role ARN

CREATE USER IF NOT EXISTS IDENTIFIER($snowflake_user)
    WORKLOAD_IDENTITY = (
        TYPE = AWS
        AWS_ROLE_ARN = CONCAT('arn:aws:iam::', $aws_account_id, ':role/', $lambda_role_name)
    )
    TYPE = SERVICE
    DEFAULT_ROLE = IDENTIFIER($snowflake_role)
    DEFAULT_WAREHOUSE = IDENTIFIER($snowflake_warehouse)
    COMMENT = '🔑 WIDF service user for AWS Lambda - keyless authentication!';

-- Grant role to service user
GRANT ROLE IDENTIFIER($snowflake_role) TO USER IDENTIFIER($snowflake_user);

-- Grant warehouse usage
GRANT USAGE ON WAREHOUSE IDENTIFIER($snowflake_warehouse) TO ROLE IDENTIFIER($snowflake_role);

-- =============================================================================
-- Verify
-- =============================================================================

DESCRIBE USER IDENTIFIER($snowflake_user);
SHOW USER WORKLOAD IDENTITY AUTHENTICATION METHODS FOR USER IDENTIFIER($snowflake_user);

SELECT 
    '✅ WIDF user created!' AS status,
    $snowflake_user AS service_user,
    CONCAT('arn:aws:iam::', $aws_account_id, ':role/', $lambda_role_name) AS trusted_role_arn;
