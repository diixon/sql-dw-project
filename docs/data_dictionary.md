# 📖 Data Dictionary

This document describes all columns across the three layers of the data warehouse. Use it as a reference when writing queries, building reports, or troubleshooting data issues.

---

## Bronze Layer (Raw Ingestion)

### `bronze.crm_cust_info` – Customer Master (CRM)
| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `cst_id` | INT | CRM | Unique customer identifier |
| `cst_key` | NVARCHAR(50) | CRM | Customer business/surrogate key |
| `cst_firstname` | NVARCHAR(50) | CRM | Customer first name (uncleaned) |
| `cst_lastname` | NVARCHAR(50) | CRM | Customer last name (uncleaned) |
| `cst_marital_status` | NVARCHAR(50) | CRM | Marital status code (M/S) |
| `cst_gndr` | NVARCHAR(50) | CRM | Gender code (M/F) |
| `cst_create_date` | DATE | CRM | Date customer record was created |

### `bronze.crm_prd_info` – Product Master (CRM)
| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `prd_id` | INT | CRM | Unique product identifier |
| `prd_key` | NVARCHAR(50) | CRM | Product business key (format: CATEGORY-PRODID) |
| `prd_nm` | NVARCHAR(50) | CRM | Product name |
| `prd_cost` | INT | CRM | Product cost |
| `prd_line` | NVARCHAR(50) | CRM | Product line code (R/M/S/T) |
| `prd_start_dt` | DATETIME | CRM | Date product became active |
| `prd_end_dt` | DATETIME | CRM | Date product was discontinued |

### `bronze.crm_sales_details` – Sales Transactions (CRM)
| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `sls_ord_num` | NVARCHAR(50) | CRM | Sales order number |
| `sls_prd_key` | NVARCHAR(50) | CRM | Product key (links to crm_prd_info) |
| `sls_cust_id` | INT | CRM | Customer ID (links to crm_cust_info) |
| `sls_order_dt` | INT | CRM | Order date (raw YYYYMMDD integer) |
| `sls_ship_dt` | INT | CRM | Shipping date (raw YYYYMMDD integer) |
| `sls_due_dt` | INT | CRM | Due date (raw YYYYMMDD integer) |
| `sls_sales` | INT | CRM | Sales amount |
| `sls_quantity` | INT | CRM | Quantity sold |
| `sls_price` | INT | CRM | Unit price |

### `bronze.erp_CUST_AZ12` – Customer Demographics (ERP)
| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `CID` | NVARCHAR(50) | ERP | Customer identifier (may have "NA-" prefix) |
| `BDATE` | DATE | ERP | Customer birth date |
| `GEN` | NVARCHAR(50) | ERP | Gender code (M/F/Male/Female) |

### `bronze.erp_LOC_A101` – Customer Location (ERP)
| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `CID` | NVARCHAR(50) | ERP | Customer identifier (may contain hyphens) |
| `CNTRY` | NVARCHAR(50) | ERP | Country (may be code or full name) |

### `bronze.erp_PX_CAT_G1V2` – Product Categories (ERP)
| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `ID` | NVARCHAR(50) | ERP | Category/product reference ID |
| `CAT` | NVARCHAR(50) | ERP | Category name |
| `SUBCAT` | NVARCHAR(50) | ERP | Subcategory name |
| `MAINTENANCE` | NVARCHAR(50) | ERP | Maintenance flag or type |

---

## Silver Layer (Cleansed Data)

All silver tables include the audit column `dwh_create_date DATETIME2 DEFAULT GETDATE()`, which records when each row was loaded into the warehouse.

### `silver.crm_cust_info` – Customer Master (Cleansed)
| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `cst_id` | INT | bronze.crm_cust_info | Unique customer identifier (NULLs filtered) |
| `cst_key` | NVARCHAR(50) | bronze.crm_cust_info | Customer business key |
| `cst_firstname` | NVARCHAR(50) | bronze.crm_cust_info | First name (trimmed) |
| `cst_lastname` | NVARCHAR(50) | bronze.crm_cust_info | Last name (trimmed) |
| `cst_marital_status` | NVARCHAR(50) | bronze.crm_cust_info | Marital status – mapped: M→Married, S→Single, else→Unknown |
| `cst_gndr` | NVARCHAR(50) | bronze.crm_cust_info | Gender – mapped: M→Male, F→Female, else→Unknown |
| `cst_create_date` | DATE | bronze.crm_cust_info | Date customer record was created |
| `dwh_create_date` | DATETIME2 | System-generated | Warehouse load timestamp |

### `silver.crm_prd_info` – Product Master (Cleansed)
| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `prd_id` | INT | bronze.crm_prd_info | Unique product identifier |
| `cat_id` | NVARCHAR(50) | Derived from `prd_key` | Category ID (extracted from first 5 chars of product key) |
| `prd_key` | NVARCHAR(50) | bronze.crm_prd_info | Product business key (category prefix removed) |
| `prd_nm` | NVARCHAR(50) | bronze.crm_prd_info | Product name |
| `prd_cost` | INT | bronze.crm_prd_info | Product cost (NULLs replaced with 0) |
| `prd_line` | NVARCHAR(50) | bronze.crm_prd_info | Product line – mapped: R→Road, M→Mountain, S→Sport, T→Touring, else→Unknown |
| `prd_start_dt` | DATETIME | bronze.crm_prd_info | Date product became active |
| `prd_end_dt` | DATETIME | Derived via `LEAD()` | Calculated end date (next product start date minus 1 day) |
| `dwh_create_date` | DATETIME2 | System-generated | Warehouse load timestamp |

### `silver.crm_sales_details` – Sales Transactions (Cleansed)
| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `sls_ord_num` | NVARCHAR(50) | bronze.crm_sales_details | Sales order number |
| `sls_prd_key` | NVARCHAR(50) | bronze.crm_sales_details | Product key |
| `sls_cust_id` | INT | bronze.crm_sales_details | Customer ID |
| `sls_order_dt` | DATE | bronze.crm_sales_details | Order date (converted from YYYYMMDD integer; NULL if invalid) |
| `sls_ship_dt` | DATE | bronze.crm_sales_details | Shipping date (converted from YYYYMMDD integer) |
| `sls_due_dt` | DATE | bronze.crm_sales_details | Due date (converted from YYYYMMDD integer) |
| `sls_sales` | INT | bronze.crm_sales_details | Sales amount (recalculated if original was invalid) |
| `sls_quantity` | INT | bronze.crm_sales_details | Quantity sold |
| `sls_price` | INT | bronze.crm_sales_details | Unit price (recalculated if original was invalid) |
| `dwh_create_date` | DATETIME2 | System-generated | Warehouse load timestamp |

### `silver.erp_CUST_AZ12` – Customer Demographics (Cleansed)
| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `CID` | NVARCHAR(50) | bronze.erp_CUST_AZ12 | Customer ID ("NA-" prefix removed) |
| `BDATE` | DATE | bronze.erp_CUST_AZ12 | Birth date (future dates set to NULL) |
| `GEN` | NVARCHAR(50) | bronze.erp_CUST_AZ12 | Gender – mapped: M/Male→Male, F/Female→Female, else→Unknown |
| `dwh_create_date` | DATETIME2 | System-generated | Warehouse load timestamp |

### `silver.erp_LOC_A101` – Customer Location (Cleansed)
| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `CID` | NVARCHAR(50) | bronze.erp_LOC_A101 | Customer ID (hyphens removed) |
| `CNTRY` | NVARCHAR(50) | bronze.erp_LOC_A101 | Country – standardised: DE/Germany→Germany, USA/US/United States→United States, others proper‑cased |
| `dwh_create_date` | DATETIME2 | System-generated | Warehouse load timestamp |

### `silver.erp_PX_CAT_G1V2` – Product Categories (Cleansed)
| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `ID` | NVARCHAR(50) | bronze.erp_PX_CAT_G1V2 | Category/product reference ID |
| `CAT` | NVARCHAR(50) | bronze.erp_PX_CAT_G1V2 | Category name |
| `SUBCAT` | NVARCHAR(50) | bronze.erp_PX_CAT_G1V2 | Subcategory name |
| `MAINTENANCE` | NVARCHAR(50) | bronze.erp_PX_CAT_G1V2 | Maintenance flag/type |
| `dwh_create_date` | DATETIME2 | System-generated | Warehouse load timestamp |

---

## Gold Layer (Dimensional Views)

### `gold.dim_customers` – Customer Dimension
| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `customer_key` | BIGINT | Generated (ROW_NUMBER) | Surrogate key for the customer dimension |
| `customer_id` | INT | silver.crm_cust_info | Original customer ID |
| `customer_number` | NVARCHAR(50) | silver.crm_cust_info | Customer business key |
| `first_name` | NVARCHAR(50) | silver.crm_cust_info | Customer first name |
| `last_name` | NVARCHAR(50) | silver.crm_cust_info | Customer last name |
| `country` | NVARCHAR(50) | silver.erp_LOC_A101 | Customer's country |
| `marital_status` | NVARCHAR(50) | silver.crm_cust_info | Marital status (Married/Single/Unknown) |
| `gender` | NVARCHAR(50) | CRM (primary) / ERP (fallback) | Gender – CRM takes precedence, ERP used if CRM is Unknown |
| `birthdate` | DATE | silver.erp_CUST_AZ12 | Customer birth date |
| `create_date` | DATE | silver.crm_cust_info | Date customer record was created in CRM |

### `gold.dim_products` – Product Dimension
| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `product_key` | BIGINT | Generated (ROW_NUMBER) | Surrogate key for the product dimension |
| `product_id` | INT | silver.crm_prd_info | Original product ID |
| `product_number` | NVARCHAR(50) | silver.crm_prd_info | Product business key |
| `product_name` | NVARCHAR(50) | silver.crm_prd_info | Product name |
| `category_id` | NVARCHAR(50) | silver.crm_prd_info | Category ID |
| `category` | NVARCHAR(50) | silver.erp_PX_CAT_G1V2 | Product category name |
| `subcategory` | NVARCHAR(50) | silver.erp_PX_CAT_G1V2 | Product subcategory name |
| `maintenance` | NVARCHAR(50) | silver.erp_PX_CAT_G1V2 | Maintenance flag |
| `cost` | INT | silver.crm_prd_info | Product cost |
| `product_line` | NVARCHAR(50) | silver.crm_prd_info | Product line (Road/Mountain/Sport/Touring) |
| `start_date` | DATETIME | silver.crm_prd_info | Date product became active |

> **Note:** `dim_products` only shows current products (those without an end date).

### `gold.fact_sales` – Sales Fact
| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `order_number` | NVARCHAR(50) | silver.crm_sales_details | Sales order number |
| `product_key` | BIGINT | gold.dim_products | Foreign key to product dimension |
| `customer_key` | BIGINT | gold.dim_customers | Foreign key to customer dimension |
| `order_date` | DATE | silver.crm_sales_details | Date the order was placed |
| `shipping_date` | DATE | silver.crm_sales_details | Date the order was shipped |
| `due_date` | DATE | silver.crm_sales_details | Date the order is due |
| `sales_amount` | INT | silver.crm_sales_details | Total sales amount for the line item |
| `quantity` | INT | silver.crm_sales_details | Quantity sold |
| `price` | INT | silver.crm_sales_details | Unit price |

---

## Transformation Summary

| Bronze | Silver | Key Changes |
|--------|--------|-------------|
| Raw CSV columns | Cleansed columns | Trimmed strings, mapped codes to descriptions, fixed data types, derived columns |
| Date fields as INT | Date fields as DATE | Converted YYYYMMDD integers to proper dates |
| No audit column | `dwh_create_date` added | Tracks when each row was loaded |
| Duplicates possible | Deduplicated | ROW_NUMBER() keeps only the latest record |
| Unvalidated values | Standardised values | Sales recalculated, IDs cleaned, future dates handled |

---

*Last updated: June 2026*
