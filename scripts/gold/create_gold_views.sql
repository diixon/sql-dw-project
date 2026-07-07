/*
================================================================================
Script:      create_gold_views.sql
Layer:       Gold
Purpose:     Creates the Gold layer views that expose business-ready,
             dimensionally-modeled data for reporting and analytics.
             Part of a Bronze -> Silver -> Gold medallion architecture.

Objects created:
    gold.dim_customers   - Customer dimension (CRM + ERP customer attributes)
    gold.dim_products    - Product dimension (current products only)
    gold.fact_sales      - Sales fact table, linked to dimensions via
                            surrogate keys

Behavior:    Each view is dropped and recreated if it already exists, so the
             script is safe to re-run whenever the Gold layer needs to be
             refreshed after a Silver layer reload.

Usage:       Run this script after silver.load_silver has completed.
================================================================================
*/

USE data_warehouse;
GO

-- ==========================================================
-- gold.dim_customers
-- ==========================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO
CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
    ci.cst_id                              AS customer_id,
    ci.cst_key                              AS customer_number,
    ci.cst_firstname                        AS first_name,
    ci.cst_lastname                         AS last_name,
    la.CNTRY                                AS country,
    ci.cst_marital_status                   AS marital_status,
    CASE
        WHEN ci.cst_gndr != 'Unknown' THEN ci.cst_gndr   -- CRM is the primary source for gender
        ELSE COALESCE(ca.GEN, 'Unknown')                 -- fall back to the ERP source when CRM has no value
    END                                      AS gender,
    ca.BDATE                                AS birthdate,
    ci.cst_create_date                      AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_CUST_AZ12 ca
    ON ci.cst_key = ca.CID
LEFT JOIN silver.erp_LOC_A101 la
    ON ci.cst_key = la.CID;
GO

-- ==========================================================
-- gold.dim_products
-- ==========================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO
CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pri.prd_start_dt, pri.prd_key) AS product_key,
    pri.prd_id                                                  AS product_id,
    pri.prd_key                                                 AS product_number,
    pri.prd_nm                                                  AS product_name,
    pri.cat_id                                                  AS category_id,
    prc.CAT                                                     AS category,
    prc.SUBCAT                                                  AS subcategory,
    prc.MAINTENANCE                                             AS maintenance,
    pri.prd_cost                                                AS cost,
    pri.prd_line                                                AS product_line,
    pri.prd_start_dt                                            AS start_date
FROM silver.crm_prd_info pri
LEFT JOIN silver.erp_PX_CAT_G1V2 prc
    ON pri.cat_id = prc.ID
WHERE pri.prd_end_dt IS NULL;   -- keep only the current version of each product
GO

-- ==========================================================
-- gold.fact_sales
-- ==========================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO
CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,
    dp.product_key  AS product_key,
    dc.customer_key AS customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products dp
    ON sd.sls_prd_key = dp.product_number
LEFT JOIN gold.dim_customers dc
    ON sd.sls_cust_id = dc.customer_id;
GO