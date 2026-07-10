# 📋 Business Rules

This document describes every transformation rule applied during the Silver layer ETL process (`silver.load_silver`). Each rule explains what changes, why it's needed, and how it affects downstream reporting.

---

## CRM: Customer Master (`silver.crm_cust_info`)

### BR-001: Trim Customer Names
- **Rule:** Leading and trailing spaces are removed from `cst_firstname` and `cst_lastname`.
- **Applies to:** `bronze.crm_cust_info` → `silver.crm_cust_info`
- **Why:** Source CRM data may contain accidental whitespace. Clean names are essential for accurate reporting, sorting, and customer communications.
- **Example:** `'  John '` → `'John'`

### BR-002: Map Marital Status Codes
- **Rule:** Single‑letter codes are converted to descriptive labels.
  - `'M'` → `'Married'`
  - `'S'` → `'Single'`
  - Anything else → `'Unknown'`
- **Applies to:** `bronze.crm_cust_info` → `silver.crm_cust_info`
- **Why:** Business users and reports need readable values, not cryptic codes. `'Unknown'` handles unexpected or missing data gracefully.
- **Example:** `'M'` → `'Married'`, `'X'` → `'Unknown'`

### BR-003: Map Gender Codes
- **Rule:** Gender codes are standardised to full descriptive terms.
  - `'M'` → `'Male'`
  - `'F'` → `'Female'`
  - Anything else → `'Unknown'`
- **Applies to:** `bronze.crm_cust_info` → `silver.crm_cust_info`
- **Why:** Consistent gender labels are important for demographic analysis and personalisation. `'Unknown'` prevents blank values from breaking reports.
- **Example:** `'F'` → `'Female'`, `'N/A'` → `'Unknown'`

### BR-004: Deduplicate Customers
- **Rule:** For customers with the same `cst_id`, only the most recent record (by `cst_create_date`) is kept. Records with NULL `cst_id` are excluded entirely.
- **Applies to:** `bronze.crm_cust_info` → `silver.crm_cust_info`
- **Why:** Source systems may contain multiple versions of a customer record (e.g., after address changes). The warehouse should contain one version of truth per customer.
- **Method:** `ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) WHERE RowNum = 1`

---

## CRM: Product Master (`silver.crm_prd_info`)

### BR-005: Extract Category ID
- **Rule:** The first 5 characters of `prd_key` are extracted to form `cat_id`. Hyphens are replaced with underscores.
- **Applies to:** `bronze.crm_prd_info` → `silver.crm_prd_info`
- **Why:** The product key encodes the category as a prefix. Extracting it allows joining with the ERP category reference table for enriched product attributes.
- **Example:** `'MOUNT-PR001'` → `cat_id = 'MOUNT'`, `prd_key = 'PR001'`

### BR-006: Handle Missing Product Costs
- **Rule:** If `prd_cost` is NULL, it is replaced with `0`.
- **Applies to:** `bronze.crm_prd_info` → `silver.crm_prd_info`
- **Why:** NULL costs can cause calculation errors (e.g., aggregations returning NULL). A default of 0 flags the missing data without breaking queries.
- **Example:** `NULL` → `0`

### BR-007: Map Product Line Codes
- **Rule:** Single‑letter product line codes are mapped to readable names.
  - `'R'` → `'Road'`
  - `'M'` → `'Mountain'`
  - `'S'` → `'Sport'`
  - `'T'` → `'Touring'`
  - Anything else → `'Unknown'`
- **Applies to:** `bronze.crm_prd_info` → `silver.crm_prd_info`
- **Why:** Business users need meaningful category names for filtering, grouping, and reporting.
- **Example:** `'M'` → `'Mountain'`

### BR-008: Derive Product End Date
- **Rule:** The product end date (`prd_end_dt`) is calculated as the day before the next product start date for the same product key. Uses the `LEAD()` window function.
- **Applies to:** `bronze.crm_prd_info` → `silver.crm_prd_info`
- **Why:** Source data provides start dates but not always accurate end dates for slowly changing dimensions. Deriving the end date ensures products don't appear active indefinitely and enables point‑in‑time analysis.
- **Example:** If a product has versions starting on `2024-01-01` and `2024-06-01`, the first version's end date becomes `2024-05-31`.

---

## CRM: Sales Details (`silver.crm_sales_details`)

### BR-009: Convert Integer Dates to Proper Dates
- **Rule:** Date fields stored as integers in YYYYMMDD format are cast to `DATE`. Invalid dates (0 or wrong length) are set to NULL.
  - `sls_order_dt`: NULL if length ≠ 8 or value = 0.
  - `sls_ship_dt` and `sls_due_dt`: Cast directly (assumed valid).
- **Applies to:** `bronze.crm_sales_details` → `silver.crm_sales_details`
- **Why:** Dates stored as integers are not queryable with date functions. Converting to proper `DATE` types enables time‑based filtering, grouping, and calculations.
- **Example:** `20240131` → `'2024-01-31'`, `0` → `NULL`

### BR-010: Fix Inconsistent Sales Amounts
- **Rule:** If `sls_sales` is NULL, negative, or doesn't equal `sls_quantity × sls_price`, it is recalculated as `ABS(sls_quantity) × ABS(sls_price)`.
- **Applies to:** `bronze.crm_sales_details` → `silver.crm_sales_details`
- **Why:** Source data may contain calculation errors, negative values from returns, or corrupted records. Ensuring `sales = quantity × price` guarantees reliable financial reporting.
- **Example:** `sls_quantity=5, sls_price=10, sls_sales=60` → `sls_sales` corrected to `50`

### BR-011: Fix Missing or Invalid Prices
- **Rule:** If `sls_price` is NULL or less than 1, it is recalculated as `sls_sales / ABS(sls_quantity)` (with NULLIF to avoid division by zero).
- **Applies to:** `bronze.crm_sales_details` → `silver.crm_sales_details`
- **Why:** A missing or nonsensical price corrupts margin and revenue analysis. Deriving it from the (already validated) sales and quantity provides the best available estimate.
- **Example:** `sls_sales=100, sls_quantity=5, sls_price=NULL` → `sls_price = 20`

---

## ERP: Customer Demographics (`silver.erp_CUST_AZ12`)

### BR-012: Clean Customer ID Prefix
- **Rule:** If `CID` starts with `'NA'` (case‑insensitive), the first three characters are removed (e.g., `'NA123'` → `'123'`).
- **Applies to:** `bronze.erp_CUST_AZ12` → `silver.erp_CUST_AZ12`
- **Why:** ERP customer IDs may include a system prefix that prevents matching with CRM records. Stripping the prefix allows proper joining.
- **Example:** `'NA-456'` → `'456'` (note: the hyphen is part of the prefix length check)

### BR-013: Handle Future Birthdates
- **Rule:** If `BDATE` is greater than today's date, it is set to NULL.
- **Applies to:** `bronze.erp_CUST_AZ12` → `silver.erp_CUST_AZ12`
- **Why:** Birthdates in the future are data entry errors. Setting them to NULL prevents incorrect age calculations and identifies the record as needing correction.
- **Example:** `'2050-01-01'` → `NULL`

### BR-014: Map Gender Codes
- **Rule:** ERP gender values are standardised.
  - `'F'`, `'FEMALE'` (case‑insensitive) → `'Female'`
  - `'M'`, `'MALE'` (case‑insensitive) → `'Male'`
  - Anything else → `'Unknown'`
- **Applies to:** `bronze.erp_CUST_AZ12` → `silver.erp_CUST_AZ12`
- **Why:** ERP systems may use different gender formats than CRM. Standardising ensures consistent values when both sources are merged in the Gold customer dimension.
- **Example:** `'Female'` → `'Female'`, `'M'` → `'Male'`

---

## ERP: Customer Location (`silver.erp_LOC_A101`)

### BR-015: Clean Customer ID Format
- **Rule:** Hyphens are removed from `CID`.
- **Applies to:** `bronze.erp_LOC_A101` → `silver.erp_LOC_A101`
- **Why:** Inconsistent ID formatting across ERP modules prevents reliable joins. Removing hyphens standardises the key for matching.
- **Example:** `'CUST-123'` → `'CUST123'`

### BR-016: Standardise Country Names
- **Rule:** Country values are mapped to full, proper‑cased names:
  - `'DE'`, `'GERMANY'` → `'Germany'`
  - `'USA'`, `'US'`, `'UNITED STATES'` → `'United States'`
  - Empty string or NULL → `'Unknown'`
  - All other values are passed through `dbo.fn_ProperCase` for consistent capitalisation.
- **Applies to:** `bronze.erp_LOC_A101` → `silver.erp_LOC_A101`
- **Why:** Country data arrives in various formats (codes, abbreviations, mixed case). Standardised names ensure accurate geographic reporting, mapping, and customer segmentation.
- **Example:** `'de'` → `'Germany'`, `'italy'` → `'Italy'`

---

## ERP: Product Categories (`silver.erp_PX_CAT_G1V2`)

### BR-017: Direct Load (No Transformations)
- **Rule:** Data is loaded as‑is from bronze to silver.
- **Applies to:** `bronze.erp_PX_CAT_G1V2` → `silver.erp_PX_CAT_G1V2`
- **Why:** Category reference data is manually maintained and expected to be already clean. No automated rules are needed, but the table is included in the truncate‑and‑reload cycle for consistency.

---

## Gold Layer: Dimensional Logic

### BR-018: Customer Gender – CRM Takes Priority
- **Rule:** In `gold.dim_customers`, gender is taken from CRM first. If CRM gender is `'Unknown'`, the ERP gender is used as a fallback. If both are unknown, the result is `'Unknown'`.
- **Applies to:** `silver.crm_cust_info` + `silver.erp_CUST_AZ12` → `gold.dim_customers`
- **Why:** CRM is considered the more reliable source for demographic data, but ERP provides a safety net when CRM data is missing.

### BR-019: Products – Current Versions Only
- **Rule:** `gold.dim_products` filters to only include products where `prd_end_dt IS NULL` – i.e., products that have not been discontinued.
- **Applies to:** `silver.crm_prd_info` → `gold.dim_products`
- **Why:** The dimension should reflect the active product catalogue for current reporting. Historical product versions can be queried directly from the Silver table if needed.

### BR-020: Fact‑Dimension Linking via Surrogate Keys
- **Rule:** `gold.fact_sales` joins to dimensions using surrogate keys (`customer_key`, `product_key`) rather than natural/business keys.
- **Applies to:** `silver.crm_sales_details` → `gold.fact_sales`
- **Why:** Surrogate keys provide stable, sequential identifiers that are independent of source system changes. This is standard dimensional modelling practice and improves query performance.

---

## Business Rule Index

| Rule ID | Description | Table |
|---------|-------------|-------|
| BR-001 | Trim customer names | crm_cust_info |
| BR-002 | Map marital status codes | crm_cust_info |
| BR-003 | Map gender codes (CRM) | crm_cust_info |
| BR-004 | Deduplicate customers | crm_cust_info |
| BR-005 | Extract category ID from product key | crm_prd_info |
| BR-006 | Handle missing product costs | crm_prd_info |
| BR-007 | Map product line codes | crm_prd_info |
| BR-008 | Derive product end date | crm_prd_info |
| BR-009 | Convert integer dates to proper dates | crm_sales_details |
| BR-010 | Fix inconsistent sales amounts | crm_sales_details |
| BR-011 | Fix missing or invalid prices | crm_sales_details |
| BR-012 | Clean customer ID prefix (ERP) | erp_CUST_AZ12 |
| BR-013 | Handle future birthdates | erp_CUST_AZ12 |
| BR-014 | Map gender codes (ERP) | erp_CUST_AZ12 |
| BR-015 | Clean customer ID format (location) | erp_LOC_A101 |
| BR-016 | Standardise country names | erp_LOC_A101 |
| BR-017 | Direct load (no transformations) | erp_PX_CAT_G1V2 |
| BR-018 | CRM gender takes priority (Gold) | dim_customers |
| BR-019 | Current products only (Gold) | dim_products |
| BR-020 | Fact‑dimension linking via surrogate keys (Gold) | fact_sales |

---

*Last updated: June 2026*
