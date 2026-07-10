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

## 📚 Table of Contents

- [🧭 Project Overview](#-project-overview)
- [📁 Project Structure](#-project-structure)
- [✨ Features](#-features)
- [🏛️ Architecture](#️-architecture)
- [🚀 Installation & Setup](#-installation--setup)
- [🧪 Usage](#-usage)
- [📜 Scripts & Components](#-scripts--components)
- [🔍 Data Quality Checks](#-data-quality-checks)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)
- [👤 Author](#-author)

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

---

## 🧪 Usage

After completing the installation, the typical workflow is shown below.

### Full Refresh (Truncate & Reload)

```sql
USE data_warehouse;
GO

-- 1. Load raw source data into the Bronze layer
EXEC bronze.load_bronze;

-- 2. Cleanse and transform data into the Silver layer
EXEC silver.load_silver;

-- 3. Validate data quality
EXEC silver.check_silver_quality;
EXEC gold.check_gold_quality;
```

### Incremental Loads

The current implementation performs a **full truncate-and-reload** for each execution.

For production environments, you can extend the `load_*` procedures to support incremental loading using techniques such as:

- `MERGE` statements
- Change detection (CDC or timestamps)
- Append-only loading
- Slowly Changing Dimensions (SCD)

### Querying the Gold Layer

After loading the Silver layer, the Gold views are immediately available for reporting and analytics.

```sql
-- Top 10 customers by total sales
SELECT TOP 10
    c.first_name + ' ' + c.last_name AS customer_name,
    SUM(f.sales_amount) AS total_spent
FROM gold.fact_sales AS f
JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY c.first_name, c.last_name
ORDER BY total_spent DESC;

-- Monthly sales trend
SELECT
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    SUM(sales_amount) AS monthly_sales
FROM gold.fact_sales
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY year, month;

-- Product category performance
SELECT
    p.category,
    p.subcategory,
    COUNT(*) AS transaction_count,
    SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales AS f
JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY p.category, p.subcategory
ORDER BY total_sales DESC;
```

### Understanding the Data Quality Checks

Both `silver.check_silver_quality` and `gold.check_gold_quality` produce detailed validation results.

- ✅ **PASS** – No issues were found.
- ❌ **FAIL** – A critical issue was detected (such as duplicate keys or broken relationships) and should be resolved.
- ⚠️ **WARN** – A non-critical issue was detected that should be reviewed.

At the end of each execution, a summary of all detected issues is displayed. If no failures are reported, the data is ready for analysis and reporting.

---

## 📜 Scripts & Components

### Database Initialization

| Script | Description |
|--------|-------------|
| `scripts/Init database.sql` | Drops and recreates the `data_warehouse` database, then creates the `bronze`, `silver`, and `gold` schemas. |

### Utility

| Script | Description |
|--------|-------------|
| `scripts/create_proper_function.sql` | Creates the `dbo.fn_ProperCase` scalar function, which converts text to proper case (for example, `'o''brien-smith'` → `'O''Brien-Smith'`). Used to standardize country names. |

### Bronze Layer (Raw Data)

| Script | Description |
|--------|-------------|
| `scripts/bronze/create_bronze_tables.sql` | Creates the six raw staging tables in the `bronze` schema that mirror the source CSV files. |
| `scripts/bronze/load_data_into_bronze.sql` | Creates the `bronze.load_bronze` stored procedure, which truncates the Bronze tables and loads data using `BULK INSERT` with execution logging and error handling. |

### Silver Layer (Clean & Standardized Data)

| Script | Description |
|--------|-------------|
| `scripts/silver/create_silver_tables.sql` | Creates the six Silver tables with appropriate data types and the `dwh_create_date` audit column. |
| `scripts/silver/load_data_into_silver.sql` | Creates the `silver.load_silver` stored procedure, which cleans, standardizes, validates, and loads data from the Bronze layer into the Silver layer. |

### Gold Layer (Business Views)

| Script | Description |
|--------|-------------|
| `scripts/gold/create_gold_views.sql` | Creates the `dim_customers`, `dim_products`, and `fact_sales` views, implementing a star schema optimized for analytics and reporting. |

### Data Quality Validation

| Script | Description |
|--------|-------------|
| `tests/check_quality_silver.sql` | Creates the `silver.check_silver_quality` stored procedure to validate duplicates, invalid codes, whitespace issues, date logic, and sales calculations in the Silver layer. |
| `tests/check_quality_gold.sql` | Creates the `gold.check_gold_quality` stored procedure to validate surrogate keys, referential integrity, business rules, and data consistency in the Gold layer. |

---

## 🔍 Data Quality Checks

Two stored procedures provide automated data validation at key stages of the pipeline. Both procedures print clear **PASS**, **FAIL**, and **WARN** messages, followed by a summary of the validation results.

### Silver Layer (`silver.check_silver_quality`)

Run this procedure after `silver.load_silver` to verify that the transformation and cleansing logic completed successfully.

| Check | Validation |
|-------|------------|
| Duplicate business keys | Ensures `cst_id` and `prd_id` are unique. |
| Trimmed text fields | Detects leading or trailing whitespace in text columns. |
| Code validity | Verifies marital status, gender, and product line values are mapped to valid descriptions. |
| Product cost validation | Ensures `prd_cost` is not `NULL` or negative. |
| Date validation | Confirms `prd_start_dt ≤ prd_end_dt` and `order_date ≤ shipping_date ≤ due_date`. |
| Sales validation | Verifies `sls_sales = sls_quantity × sls_price` and checks for invalid or negative values. |
| Country standardization | Identifies country codes or values that may require additional mapping. |
| Birth date validation | Detects birth dates that occur in the future. |

### Gold Layer (`gold.check_gold_quality`)

Run this procedure after creating the Gold views to verify that the dimensional model is consistent and reliable.

| Check | Validation |
|-------|------------|
| Surrogate key uniqueness | Ensures `customer_key` and `product_key` are unique. |
| Business key uniqueness | Ensures `customer_id` and `product_id` are not duplicated. |
| Referential integrity | Confirms every record in `fact_sales` references valid dimension records. |
| Gender and country validation | Verifies only expected gender values are present and country values are populated. |
| Date validation | Confirms `order_date ≤ shipping_date ≤ due_date`. |
| Sales validation | Verifies `sales_amount = quantity × price` and checks for invalid values. |

### Running the Quality Checks

```sql
EXEC silver.check_silver_quality;
EXEC gold.check_gold_quality;
```

Review the output for any **FAIL** or **WARN** messages. Each procedure prints a summary of the validation results, and the scripts include commented diagnostic queries that can help identify problematic records when issues are detected.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

Whether it's a bug fix, a new transformation rule, or a documentation improvement, your help is appreciated.

### How to Contribute

1. **Fork** the repository.

2. **Create** a feature branch:

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Commit** your changes with clear, descriptive messages:

   ```bash
   git commit -m "Add: description of the change"
   ```

4. **Push** your branch:

   ```bash
   git push origin feature/your-feature-name
   ```

5. **Open** a Pull Request against the `main` branch and describe what you changed and why.

---

### Before You Submit

- Ensure your SQL scripts are idempotent (they can be safely re-run) and follow the existing code style.

- Add or update data quality checks if you introduce new transformation logic.

- Test your changes on a clean database to confirm everything works from scratch.

---

### Reporting Issues

If you find a bug or have a suggestion, please use the **Issues** page and include:

- A clear description of the problem or idea.

- Steps to reproduce the issue (if applicable).

- The SQL Server version you are using.

---

Thank you for contributing! All submissions are reviewed, and constructive collaboration is always welcome.

---

## 📄 License

This project is licensed under the **MIT License**, which allows you to use, modify, and distribute the code freely.

For more details, see the [LICENSE](LICENSE) file.

---

## 👤 Author

**Mohamed Ahmed**

- GitHub: [@diixon](https://github.com/diixon)
- LinkedIn: [linkedin.com/in/mohamed-ahmed-421b9541b](https://www.linkedin.com/in/mohamed-ahmed-421b9541b)
- Email: mmoohamedahmed1@gmail.com

---

*Built with ❤️ to simplify data warehouse development and setup.*
