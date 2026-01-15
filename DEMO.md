# 🔑 Snowflake WIDF Lambda Demo

> **Keyless ETL: AWS Lambda → Snowflake**  
> No passwords, no secrets, no key pairs - just IAM trust!

---

## Prerequisites

```bash
# Check AWS SAM CLI is installed
task aws:check-sam

# Verify your configuration
task default
```

> **Note:** If SAM CLI is not installed, visit:  
> <https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html>

Ensure `.env` has your AWS and Snowflake settings configured.

---

## Part I: Deploy Lambda (Without WIDF) - Watch It Fail

### 1. Setup Snowflake Database

```bash
task snow:setup
```

This creates the database, schema, role, and RAW_DATA table.

### 2. Deploy AWS Resources

```bash
task aws:deploy
```

This deploys:

- Lambda function
- S3 bucket with trigger
- IAM execution role

### 3. Get the Lambda Role ARN

```bash
task aws:role-arn
```

📝 **Note this ARN** - you'll need it for Part II!

### 4. Upload Test Data

```bash
task aws:test
```

### 5. Watch the Logs - See It FAIL! ❌

```bash
task aws:logs
```

**Expected Error:**

```
❌ Lambda execution failed: 
   Authentication failed - no WIDF service user configured in Snowflake
```

The Lambda has valid IAM credentials, but Snowflake doesn't trust them yet!

---

## Part II: Configure WIDF - Watch It Succeed

### 1. Create Snowflake WIDF Service User

```bash
task snow:lambda-wid
```

This creates a SERVICE user that trusts the Lambda's IAM role:

```sql
CREATE USER LAMBDA_LOADER_BOT
  TYPE = SERVICE
  WORKLOAD_IDENTITY = (
    TYPE = AWS
    AWS_ROLE_ARN = 'arn:aws:iam::123456789012:role/snowpark-widf-lambda-role-dev'
  );
```

### 2. Upload Test Data Again

```bash
task aws:test
```

### 3. Watch the Logs - See It SUCCEED! ✅

```bash
task aws:logs
```

**Expected Success:**

```
🔑 Connecting to Snowflake using WORKLOAD_IDENTITY (keyless!)
✅ Connected as: LAMBDA_LOADER_BOT (role: WIDF_DEMO_ROLE)
✅ Loaded 3 records from s3://...
```

### 4. Verify Data in Snowflake

```bash
task snow:query
```

---

## 🎉 The Magic Explained

```
┌─────────────────┐     WIDF Trust     ┌─────────────────┐
│   AWS Lambda    │ ◄────────────────► │    Snowflake    │
│                 │                     │                 │
│  IAM Role ARN   │    No Secrets!     │  SERVICE User   │
│  (identity)     │    No Passwords!   │  (trusts ARN)   │
└─────────────────┘                     └─────────────────┘
```

**Key Connection Parameter:**

```python
connection_params = {
    "authenticator": "WORKLOAD_IDENTITY",  # 🔑 THE MAGIC!
    # NO password, NO secret key, NO key pair
}
```

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `task default` | Show configuration |
| `task aws:check-sam` | Check AWS SAM CLI is installed |
| `task snow:setup` | Create Snowflake DB/schema/table |
| `task aws:deploy` | Deploy Lambda + S3 |
| `task snow:lambda-wid` | Create WIDF service user |
| `task aws:test` | Upload test data |
| `task aws:logs` | Tail CloudWatch logs |
| `task snow:query` | Query RAW_DATA table |
| `task aws:role-arn` | Get Lambda Role ARN |
| `task deploy` | Full deployment (AWS + WIDF) |
| `task clean:all` | Cleanup everything |

---

## Cleanup

```bash
# Remove AWS resources
task aws:clean

# Or clean everything (AWS + local build)
task clean:all
```

---

## Troubleshooting

### "User not found" Error

```bash
# Verify WIDF user exists
snow sql -q "SHOW USERS LIKE 'LAMBDA_LOADER_BOT';"
```

### "Role not granted" Error

```bash
# Grant role to service user
snow sql -q "GRANT ROLE WIDF_DEMO_ROLE TO USER LAMBDA_LOADER_BOT;"
```

### Check WIDF Configuration

```bash
snow sql -q "SHOW USER WORKLOAD IDENTITY AUTHENTICATION METHODS FOR USER LAMBDA_LOADER_BOT;"
```
