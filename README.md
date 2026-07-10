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
