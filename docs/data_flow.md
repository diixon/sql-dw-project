# Data Flow

Source-to-target lineage for every column, from the original CSV files
through to the Gold layer.

## CRM Source

### cust_info.csv → bronze.crm_cust_info → silver.crm_cust_info → gold.dim_customers

| Bronze / Silver column | Silver transformation                                              | Gold column          |
|-------------------------|----------------------------------------------------------------------|-----------------------|
| cst_id                  | Deduplicated: latest record per `cst_id` kept, nulls dropped.        | customer_id           |
| cst_key                 | —                                                                     | customer_number       |
| cst_firstname           | Trimmed.                                                              | first_name            |
| cst_lastname            | Trimmed.                                                              | last_name             |
| cst_marital_status      | Mapped: M → Married, S → Single, else → Unknown.                     | marital_status        |
| cst_gndr                | Mapped: M → Male, F → Female, else → Unknown.                         | gender (with ERP fallback) |
| cst_create_date         | —                                                                     | create_date           |

### prd_info.csv → bronze.crm_prd_info → silver.crm_prd_info → gold.dim_products

| Bronze / Silver column | Silver transformation                                              | Gold column      |
|-------------------------|----------------------------------------------------------------------|-------------------|
| prd_id                  | —                                                                     | product_id        |
| prd_key                 | Split into `cat_id` (first 5 chars, `-` → `_`) and `prd_key` (remainder). | product_number |
| prd_nm                  | —                                                                     | product_name      |
| prd_cost                | Defaulted to 0 if NULL.                                               | cost              |
| prd_line                | Mapped: R → Road, M → Mountain, S → Sport, T → Touring, else → Unknown. | product_line    |
| prd_start_dt             | Cast to DATE.                                                         | start_date        |
| prd_end_dt (derived)     | Set to the day before the next `prd_start_dt` for the same `prd_key`. | filtered out (only current row kept) |

### sales_details.csv → bronze.crm_sales_details → silver.crm_sales_details → gold.fact_sales

| Bronze / Silver column | Silver transformation                                                                 | Gold column     |
|-------------------------|------------------------------------------------------------------------------------------|------------------|
| sls_ord_num             | —                                                                                          | order_number     |
| sls_prd_key             | —                                                                                          | joined to `dim_products.product_number` to resolve `product_key` |
| sls_cust_id             | —                                                                                          | joined to `dim_customers.customer_id` to resolve `customer_key` |
| sls_order_dt            | Validated (must be an 8-digit, non-zero integer) and cast to DATE; else NULL.              | order_date       |
| sls_ship_dt              | Validated and cast to DATE the same way as `sls_order_dt`.                                | shipping_date    |
| sls_due_dt               | Validated and cast to DATE the same way as `sls_order_dt`.                                | due_date         |
| sls_sales                | Recalculated as `ABS(quantity) * ABS(price)` if NULL, non-positive, or inconsistent with quantity × price. | sales_amount |
| sls_quantity             | —                                                                                          | quantity         |
| sls_price                | Recalculated as `sales / quantity` if NULL or less than 1.                                | price            |

## ERP Source

### CUST_AZ12.csv → bronze.erp_CUST_AZ12 → silver.erp_CUST_AZ12 → gold.dim_customers

| Bronze / Silver column | Silver transformation                          | Gold column |
|-------------------------|---------------------------------------------------|--------------|
| CID                      | Leading `NA` prefix stripped.                      | joined to `crm_cust_info.cst_key` |
| BDATE                    | Nulled out if in the future.                       | birthdate    |
| GEN                      | Mapped: F/Female → Female, M/Male → Male, else → Unknown. | fallback source for `gender` |

### LOC_A101.csv → bronze.erp_LOC_A101 → silver.erp_LOC_A101 → gold.dim_customers

| Bronze / Silver column | Silver transformation                                                          | Gold column |
|-------------------------|------------------------------------------------------------------------------------|--------------|
| CID                      | Hyphens stripped.                                                                   | joined to `crm_cust_info.cst_key` |
| CNTRY                    | Mapped: DE/Germany → Germany, US/USA/United States → United States, blank/NULL → Unknown, else → `dbo.fn_ProperCase(CNTRY)`. | country |

### PX_CAT_G1V2.csv → bronze.erp_PX_CAT_G1V2 → silver.erp_PX_CAT_G1V2 → gold.dim_products

| Bronze / Silver column | Silver transformation | Gold column  |
|-------------------------|--------------------------|---------------|
| ID                       | Passthrough, no transformation. | joined to `crm_prd_info.cat_id` |
| CAT                      | Passthrough.              | category      |
| SUBCAT                   | Passthrough.              | subcategory   |
| MAINTENANCE              | Passthrough.              | maintenance   |
