/*
================================================================================
Script:      create_silver_tables.sql
Layer:       Silver
Purpose:     Creates (or recreates) the Silver layer tables that hold cleansed
             CRM and ERP source data in the data_warehouse database.
             Part of a Bronze -> Silver -> Gold medallion architecture.

Behavior:    For each table, the script checks if it already exists and drops
             it before recreating it. This makes the script safe to re-run
             during development, but note that existing data will be lost
             every time it executes.

Usage:       Run this script whenever the Silver table structures need to be
             (re)initialized, e.g. as part of a full reload of the warehouse.
================================================================================
*/

USE data_warehouse;
GO

-- ==========================================================
-- CRM SOURCE TABLES
-- ==========================================================

-- Drop and recreate crm_cust_info
-- Holds customer master data sourced from the CRM system
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO
CREATE TABLE silver.crm_cust_info (
    cst_id              INT,                                  -- Customer ID
    cst_key             NVARCHAR(50),                          -- Customer business key
    cst_firstname       NVARCHAR(50),                          -- Customer first name
    cst_lastname        NVARCHAR(50),                          -- Customer last name
    cst_marital_status  NVARCHAR(50),                          -- Marital status
    cst_gndr            NVARCHAR(50),                          -- Gender
    cst_create_date     DATE,                                  -- Date the record was created in CRM
    dwh_create_date     DATETIME2 DEFAULT GETDATE()             -- Warehouse load timestamp
);
GO

-- Drop and recreate crm_prd_info
-- Holds product master data sourced from the CRM system
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO
CREATE TABLE silver.crm_prd_info (
    prd_id          INT,                                       -- Product ID
    cat_id          NVARCHAR(50),                               -- Category ID
    prd_key         NVARCHAR(50),                               -- Product business key
    prd_nm          NVARCHAR(50),                               -- Product name
    prd_cost        INT,                                        -- Product cost
    prd_line        NVARCHAR(50),                               -- Product line/category
    prd_start_dt    DATETIME,                                   -- Date product became active
    prd_end_dt      DATETIME,                                   -- Date product was discontinued
    dwh_create_date DATETIME2 DEFAULT GETDATE()                 -- Warehouse load timestamp
);
GO

-- Drop and recreate crm_sales_details
-- Holds sales transaction line details sourced from the CRM system
-- NOTE: sls_order_dt, sls_ship_dt, sls_due_dt are stored as DATE here, but the
-- source system may provide them as raw YYYYMMDD integers; confirm/convert
-- during the Bronze -> Silver transformation step if needed.
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO
CREATE TABLE silver.crm_sales_details (
    sls_ord_num     NVARCHAR(50),                               -- Sales order number
    sls_prd_key     NVARCHAR(50),                               -- Product key (FK to crm_prd_info)
    sls_cust_id     INT,                                        -- Customer ID (FK to crm_cust_info)
    sls_order_dt    DATE,                                       -- Order date
    sls_ship_dt     DATE,                                       -- Ship date
    sls_due_dt      DATE,                                       -- Due date
    sls_sales       INT,                                        -- Total sales amount
    sls_quantity    INT,                                        -- Quantity sold
    sls_price       INT,                                        -- Unit price
    dwh_create_date DATETIME2 DEFAULT GETDATE()                 -- Warehouse load timestamp
);
GO

-- ==========================================================
-- ERP SOURCE TABLES
-- ==========================================================

-- Drop and recreate erp_CUST_AZ12
-- Holds supplementary customer data sourced from the ERP system
IF OBJECT_ID('silver.erp_CUST_AZ12', 'U') IS NOT NULL
    DROP TABLE silver.erp_CUST_AZ12;
GO
CREATE TABLE silver.erp_CUST_AZ12 (
    CID             NVARCHAR(50),                               -- Customer ID (ERP-side key)
    BDATE           DATE,                                       -- Customer birth date
    GEN             NVARCHAR(50),                               -- Gender
    dwh_create_date DATETIME2 DEFAULT GETDATE()                 -- Warehouse load timestamp
);
GO

-- Drop and recreate erp_LOC_A101
-- Holds customer location data sourced from the ERP system
IF OBJECT_ID('silver.erp_LOC_A101', 'U') IS NOT NULL
    DROP TABLE silver.erp_LOC_A101;
GO
CREATE TABLE silver.erp_LOC_A101 (
    CID             NVARCHAR(50),                               -- Customer ID (ERP-side key)
    CNTRY           NVARCHAR(50),                               -- Country
    dwh_create_date DATETIME2 DEFAULT GETDATE()                 -- Warehouse load timestamp
);
GO

-- Drop and recreate erp_PX_CAT_G1V2
-- Holds product category reference data sourced from the ERP system
IF OBJECT_ID('silver.erp_PX_CAT_G1V2', 'U') IS NOT NULL
    DROP TABLE silver.erp_PX_CAT_G1V2;
GO
CREATE TABLE silver.erp_PX_CAT_G1V2 (
    ID              NVARCHAR(50),                               -- Category/product reference ID
    CAT             NVARCHAR(50),                               -- Category
    SUBCAT          NVARCHAR(50),                               -- Subcategory
    MAINTENANCE     NVARCHAR(50),                               -- Maintenance flag/type
    dwh_create_date DATETIME2 DEFAULT GETDATE()                 -- Warehouse load timestamp
);
GO