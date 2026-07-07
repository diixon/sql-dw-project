# Data Architecture

This project follows the **Medallion Architecture**, organizing data into three
layers — Bronze, Silver, and Gold — within a single `data_warehouse` database
on Microsoft SQL Server.

## Overview

```mermaid
flowchart LR
    subgraph Sources["Source Systems"]
        CRM["CRM CSV files\ncust_info, prd_info, sales_details"]
        ERP["ERP CSV files\nCUST_AZ12, LOC_A101, PX_CAT_G1V2"]
    end

    subgraph Bronze["Bronze Layer (raw)"]
        B1["bronze.crm_*"]
        B2["bronze.erp_*"]
    end

    subgraph Silver["Silver Layer (cleansed)"]
        S1["silver.crm_*"]
        S2["silver.erp_*"]
    end

    subgraph Gold["Gold Layer (business-ready)"]
        G1["gold.dim_customers"]
        G2["gold.dim_products"]
        G3["gold.fact_sales"]
    end

    CRM --> B1
    ERP --> B2
    B1 --> S1
    B2 --> S2
    S1 --> G1
    S1 --> G3
    S2 --> G1
    S2 --> G2
    G1 --> G3
    G2 --> G3
```

## Layers

### Bronze — Raw Ingestion
- **Purpose:** land source data with no transformation, exactly as received.
- **Load method:** `bronze.load_bronze` stored procedure, using `BULK INSERT`
  from CSV files, with a `TRUNCATE` before each load.
- **Objects:** `bronze.crm_cust_info`, `bronze.crm_prd_info`,
  `bronze.crm_sales_details`, `bronze.erp_CUST_AZ12`, `bronze.erp_LOC_A101`,
  `bronze.erp_PX_CAT_G1V2`.

### Silver — Cleansed & Standardized
- **Purpose:** fix data quality issues from Bronze — trimming whitespace,
  standardizing coded values (e.g. gender, marital status, product line,
  country), deduplicating on business keys, validating dates, and
  recalculating inconsistent numeric fields.
- **Load method:** `silver.load_silver` stored procedure.
- **Objects:** mirrors the Bronze table names under the `silver` schema.
- **Supporting object:** `dbo.fn_ProperCase`, a scalar function used to
  title-case free-text values (e.g. country names) during cleansing.

### Gold — Business-Ready Model
- **Purpose:** expose a dimensional model for reporting and analytics.
- **Load method:** views (no physical load step); always reflect the current
  contents of Silver.
- **Objects:**
  - `gold.dim_customers` — customer dimension, combining CRM and ERP
    customer attributes, with a surrogate `customer_key`.
  - `gold.dim_products` — product dimension, current products only
    (historical product versions are excluded), with a surrogate
    `product_key`.
  - `gold.fact_sales` — sales transactions, linked to both dimensions via
    their surrogate keys.

## Data Quality
Two validation scripts support this pipeline:
- `quality_checks_silver.sql` — validates Silver layer cleansing rules
  (deduplication, standardized values, valid date ranges, sales
  consistency).
- `quality_checks_gold.sql` — validates the Gold dimensional model
  (duplicate surrogate keys, referential integrity between facts and
  dimensions).
