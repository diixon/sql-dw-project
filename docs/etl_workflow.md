# 🔄 ETL Workflow

This document describes the end-to-end Extract, Transform, and Load (ETL) process for the data warehouse. It covers the sequence of operations, dependencies, expected outputs, and error handling.

---

## Process Overview

```text
CSV Files → Bronze Layer → Silver Layer → Gold Layer → Quality Checks
(Raw)      (Ingestion)     (Cleansing)     (Views)      (Validation)
```

| Phase | Layer | What Happens | Script |
|-------|-------|--------------|--------|
| 1. Setup | – | Database and schemas are created | `Init database.sql` |
| 2. Table Creation | Bronze & Silver | All staging and cleansed tables are created | `create_bronze_tables.sql`, `create_silver_tables.sql` |
| 3. Ingestion | Bronze | Raw CSV data is bulk-loaded into bronze tables | `load_data_into_bronze.sql` |
| 4. Transformation | Silver | Data is cleansed, standardised, and loaded into silver tables | `load_data_into_silver.sql` |
| 5. Presentation | Gold | Dimensional views are created (always up-to-date) | `create_gold_views.sql` |
| 6. Validation | Silver & Gold | Quality checks run to verify data integrity | `check_quality_silver.sql`, `check_quality_gold.sql` |

---

## Phase 1: Database & Schema Setup

**Script:** `scripts/Init database.sql`

### Actions

- Drops the `data_warehouse` database if it already exists (forces disconnection).
- Creates a new `data_warehouse` database.
- Creates three schemas:
  - `bronze`
  - `silver`
  - `gold`

### Expected Output

```text
Data Warehouse database initialized successfully!
Schemas created: bronze, silver, gold
Ready for ETL processes.
```

**Dependencies:** None — this is always run first.

**Re-run Safety:** ⚠️ Destructive. Drops the entire database. Ensure no active connections before running.

---

## Phase 2: Table Creation

**Scripts**

- `scripts/bronze/create_bronze_tables.sql`
- `scripts/silver/create_silver_tables.sql`

### Actions

- Creates six raw tables in the `bronze` schema:
  - `crm_cust_info`
  - `crm_prd_info`
  - `crm_sales_details`
  - `erp_CUST_AZ12`
  - `erp_LOC_A101`
  - `erp_PX_CAT_G1V2`
- Creates six cleansed tables in the `silver` schema, each containing a `dwh_create_date` audit column.

### Expected Output

No messages are printed unless an error occurs.

**Dependencies:** Phase 1 must be completed.

**Re-run Safety:** Safe. Tables are dropped and recreated, so existing data will be lost and must be reloaded.

---

## Phase 3: Bronze Ingestion (`bronze.load_bronze`)

**Script:** `scripts/bronze/load_data_into_bronze.sql`

### Actions

1. Truncates all six Bronze tables.
2. Bulk loads data from CSV files.

**CRM Source Files**

- `cust_info.csv`
- `prd_info.csv`
- `sales_details.csv`

**ERP Source Files**

- `CUST_AZ12.csv`
- `LOC_A101.csv`
- `PX_CAT_G1V2.csv`

**CSV Location:** Update the file paths manually inside the script (see Installation & Setup).

### Expected Output

```text
=============================================
STARTING BRONZE LAYER LOAD
=============================================
Overall Start Time: 2026-06-15 10:00:00

=============================================
Starting CRM Data Load
=============================================

crm_cust_info loaded successfully! (Duration: 5 seconds)
crm_prd_info loaded successfully! (Duration: 3 seconds)
crm_sales_details loaded successfully! (Duration: 12 seconds)

=============================================
CRM Data Load Completed!
CRM Total Duration: 20 seconds
=============================================

=============================================
Starting ERP Data Load
=============================================

erp_CUST_AZ12 loaded successfully! (Duration: 2 seconds)
erp_LOC_A101 loaded successfully! (Duration: 1 second)
erp_PX_CAT_G1V2 loaded successfully! (Duration: 1 second)

=============================================
ERP Data Load Completed!
ERP Total Duration: 4 seconds
=============================================

=============================================
ALL BRONZE TABLES LOADED SUCCESSFULLY!
=============================================
Overall Total Duration: 24 seconds
=============================================
```

**Dependencies**

- Phases 1 and 2 completed.
- CSV files must be accessible by the SQL Server service account.

**Error Handling**

If any `BULK INSERT` fails, the `CATCH` block prints:

- Error message
- Error number
- Procedure name
- Line number
- Time elapsed

The error is then re-thrown.

**Re-run Safety:** Safe. Tables are truncated before every load.

---

## Phase 4: Silver Transformation (`silver.load_silver`)

**Script:** `scripts/silver/load_data_into_silver.sql`

### Actions

1. Truncates all Silver tables.
2. Cleans and transforms Bronze data before loading.

| Silver Table | Key Transformations |
|--------------|---------------------|
| `crm_cust_info` | Trim names, map marital status and gender codes, deduplicate by `cst_id` (keep latest record) |
| `crm_prd_info` | Extract `cat_id`, map product line codes, derive `prd_end_dt` using `LEAD()` |
| `crm_sales_details` | Convert integer dates to `DATE`, correct sales amount, handle NULL values |
| `erp_CUST_AZ12` | Remove `NA-` prefix from customer IDs, nullify future birthdates, map gender codes |
| `erp_LOC_A101` | Remove hyphens from customer IDs, standardise country names using `dbo.fn_ProperCase` |
| `erp_PX_CAT_G1V2` | Loaded directly (reference data) |

### Expected Output

Similar progress report as the Bronze load, including:

- Per-table duration
- CRM summary
- ERP summary
- Overall execution summary

**Dependencies**

- Bronze tables must contain data.
- `dbo.fn_ProperCase` must already exist (`create_proper_function.sql`).

**Error Handling**

Uses the same `TRY...CATCH` pattern as the Bronze procedure.

**Re-run Safety:** Safe. Tables are truncated before loading.

---

## Phase 5: Gold Views

**Script:** `scripts/gold/create_gold_views.sql`

### Actions

Creates three views inside the `gold` schema:

- `dim_customers` — customer dimension with surrogate keys
- `dim_products` — current product dimension with surrogate keys
- `fact_sales` — sales fact table linked to both dimensions

> **Note:** These are SQL views, not physical tables. They always reflect the latest data available in the Silver layer.

**Dependencies:** Phase 4 completed.

**Re-run Safety:** Safe. Existing views are dropped and recreated.

---

## Phase 6: Quality Checks

**Scripts**

- `tests/check_quality_silver.sql`
- `tests/check_quality_gold.sql`

These scripts create the following stored procedures:

- `silver.check_silver_quality`
- `gold.check_gold_quality`

### Run the Checks

```sql
EXEC silver.check_silver_quality;
EXEC gold.check_gold_quality;
```

### Expected Output

```text
=============================================
     STARTING SILVER LAYER QUALITY CHECKS
=============================================

[PASS] No duplicate cst_id found
[PASS] No NULL cst_id found
[PASS] All name fields properly trimmed
[PASS] All marital status values valid
[PASS] All gender values valid

=============================================
     SILVER QUALITY CHECKS COMPLETED!
=============================================
Total Issues Found: 0
Status: ALL CHECKS PASSED!
=============================================
```

**Dependencies:** Silver and Gold objects must already be populated.

**Re-run Safety:** Completely safe. Read-only validation.

---

# Complete Run Sequence

## Initial Setup

```sql
-- Setup (run once)

-- Execute:
-- Init database.sql
-- create_bronze_tables.sql
-- load_data_into_bronze.sql
-- create_silver_tables.sql
-- create_proper_function.sql
-- load_data_into_silver.sql
-- create_gold_views.sql
-- check_quality_silver.sql
-- check_quality_gold.sql
```

## Full Refresh

```sql
USE data_warehouse;

EXEC bronze.load_bronze;
EXEC silver.load_silver;
EXEC silver.check_silver_quality;
EXEC gold.check_gold_quality;
```

---

# Scheduling with SQL Server Agent (Optional)

For production deployments:

1. Create a SQL Server Agent Job.
2. Add job steps in the following order:

```sql
EXEC bronze.load_bronze;
```

```sql
EXEC silver.load_silver;
```

```sql
EXEC silver.check_silver_quality;
```

```sql
EXEC gold.check_gold_quality;
```

3. Configure each step to fail the job if an error occurs.
4. Schedule execution (for example, every day at **2:00 AM**).

---

# Common Issues & Solutions

| Issue | Likely Cause | Solution |
|------|--------------|----------|
| `Cannot bulk load` | SQL Server service account cannot access the CSV folder | Move the files to an accessible location or grant permissions |
| `Invalid object name dbo.fn_ProperCase` | Function has not been created | Run `create_proper_function.sql` first |
| Gold views return no data | Silver tables are empty | Execute `silver.load_silver` after loading Bronze |
| Quality checks report duplicate keys | Source data contains duplicates | Review the deduplication logic in `load_data_into_silver.sql` |

---

**Last Updated:** June 2026
