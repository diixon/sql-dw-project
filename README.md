## 🧭 Project Overview

**SQL Data Warehouse Project** is an end-to-end SQL Server project that demonstrates how to build a modern data warehouse using the **Medallion Architecture (Bronze → Silver → Gold)**.

The project covers the complete data warehousing workflow, including:

- Ingesting raw CRM and ERP data from CSV files
- Loading data into the Bronze layer
- Cleaning, standardizing, and transforming data in the Silver layer
- Building analytical views in the Gold layer using a dimensional model
- Validating data quality with automated SQL checks

This repository serves as a practical portfolio project for data engineering and data analytics, showcasing ETL development, data modeling, SQL best practices, and data quality validation.

---

## 📁 Project Structure

```text
sql-dw-project/
├── README.md
├── datasets/                              # Raw CSV source files
│   ├── source_crm/
│   │   ├── cust_info.csv
│   │   ├── prd_info.csv
│   │   └── sales_details.csv
│   └── source_erp/
│       ├── CUST_AZ12.csv
│       ├── LOC_A101.csv
│       └── PX_CAT_G1V2.csv
├── docs/                                  # Additional documentation (optional)
├── scripts/
│   ├── Init database.sql                  # Creates database and schemas
│   ├── create_proper_function.sql         # Helper function for proper-casing
│   ├── bronze/
│   │   ├── create_bronze_tables.sql       # Creates raw staging tables
│   │   └── load_data_into_bronze.sql      # Bulk-loads CSV data into bronze
│   ├── silver/
│   │   ├── create_silver_tables.sql       # Creates cleansed silver tables
│   │   └── load_data_into_silver.sql      # Transforms and loads data into silver
│   └── gold/
│       └── create_gold_views.sql          # Creates dimensional views (star schema)
└── tests/
    ├── check_quality_silver.sql           # Data quality checks for the Silver layer
    └── check_quality_gold.sql             # Data quality checks for the Gold layer
```

---

## ✨ Features

- **Complete Medallion Pipeline** – Implements the Bronze → Silver → Gold architecture, from raw CSV ingestion to analytical views.
- **Idempotent & Re-runnable** – Scripts can be safely re-executed by dropping/recreating objects or truncating tables before loading.
- **CRM & ERP Integration** – Combines six source datasets from CRM and ERP systems into a unified data warehouse.
- **Robust Bronze Loading** – Uses `BULK INSERT` with progress logging, execution timing, and `TRY...CATCH` error handling.
- **Comprehensive Silver Transformations** – Includes data cleansing, deduplication, code mapping, data type conversions, date validation, business rule enforcement, ERP ID standardization, and proper-case formatting.
- **Analytics-Ready Gold Layer** – Provides two dimension views (`dim_customers`, `dim_products`) and one fact view (`fact_sales`) using a star schema for BI and reporting.
- **Built-in Data Quality Validation** – SQL quality checks verify duplicates, referential integrity, data consistency, and business rules with clear PASS/FAIL/WARN results.
- **Production-Oriented Design** – Includes configurable file paths, detailed execution logs, error handling, and guidance for safe execution.

---

## 🏛️ Architecture

This project follows the **Medallion Architecture**, a three-layer data architecture that progressively improves data quality from raw ingestion to business-ready analytics.

```text
┌────────────┐     ┌────────────┐     ┌──────────────┐
│   BRONZE   │ ──> │   SILVER   │ ──> │     GOLD     │
│  Raw Data  │     │ Clean Data │     │ Business Data│
└────────────┘     └────────────┘     └──────────────┘
```

### Bronze Layer
Stores raw data exactly as it is received from the CRM and ERP CSV files. No transformations are applied, preserving the original source data for traceability and reprocessing.

### Silver Layer
Contains cleansed, standardized, and deduplicated data. This layer applies business rules such as data type conversions, date validation, code mapping, ERP ID standardization, and other data quality improvements.

### Gold Layer
Provides business-ready dimensional views (`dim_customers`, `dim_products`, and `fact_sales`) organized in a star schema. These views are optimized for analytics and can be directly consumed by BI tools such as Power BI, Tableau, and SSRS.

---

## 🚀 Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/diixon/sql-dw-project.git
cd sql-dw-project
```

### 2. Execute the Setup Scripts

Open the SQL files in SQL Server Management Studio (SSMS) or Azure Data Studio and execute them against your SQL Server instance in the following order.

| Step | Script | Purpose |
|------|--------|---------|
| 1 | `scripts/Init database.sql` | Creates the `data_warehouse` database and the `bronze`, `silver`, and `gold` schemas. |
| 2 | `scripts/bronze/create_bronze_tables.sql` | Creates the raw staging tables in the Bronze layer. |
| 3 | `scripts/bronze/load_data_into_bronze.sql` | Creates the `bronze.load_bronze` stored procedure. |
| 4 | `scripts/silver/create_silver_tables.sql` | Creates the cleansed tables in the Silver layer. |
| 5 | `scripts/create_proper_function.sql` | Creates the `dbo.fn_ProperCase` helper function. |
| 6 | `scripts/silver/load_data_into_silver.sql` | Creates the `silver.load_silver` stored procedure. |
| 7 | `scripts/gold/create_gold_views.sql` | Creates the `gold.dim_customers`, `gold.dim_products`, and `gold.fact_sales` views. |
| 8 | `tests/check_quality_silver.sql` | Creates the `silver.check_silver_quality` stored procedure. |
| 9 | `tests/check_quality_gold.sql` | Creates the `gold.check_gold_quality` stored procedure. |

> **⚠️ Important**
>
> Complete **Steps 1–7** before loading any data. The quality-check procedures (Steps 8–9) can be created at any time.

---

### 3. Update the CSV File Paths

Open `scripts/bronze/load_data_into_bronze.sql` and locate the `BULK INSERT` statements.

Replace the placeholder paths with the actual location of your CSV files. Ensure the SQL Server service account has permission to access those files.

Example:

```sql
BULK INSERT bronze.crm_cust_info
FROM 'C:\data\source_crm\cust_info.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);
```

---

### 4. Load Data into the Bronze Layer

```sql
USE data_warehouse;
GO

EXEC bronze.load_bronze;
```

This procedure truncates the Bronze tables and loads the source CSV files using `BULK INSERT`. Execution progress is displayed in the **Messages** tab.

---

### 5. Load Data into the Silver Layer

```sql
EXEC silver.load_silver;
```

This procedure performs all cleansing, standardization, validation, and transformation logic before populating the Silver tables.

---

### 6. Run Data Quality Checks (Optional)

```sql
EXEC silver.check_silver_quality;
EXEC gold.check_gold_quality;
```

Review the output and investigate any **FAIL** or **WARN** messages.

---

### 7. Query the Gold Layer

```sql
SELECT * FROM gold.dim_customers;
SELECT * FROM gold.fact_sales;
```

These views are ready to be connected to BI tools such as Power BI, Tableau, or SSRS.
