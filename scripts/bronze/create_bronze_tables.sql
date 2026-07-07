/*
================================================================================
Script:      create_bronze_tables.sql
Layer:       Bronze
Purpose:     Creates (or recreates) the Bronze layer tables that store raw
             source data in the data_warehouse database.
             Part of a Bronze -> Silver -> Gold medallion architecture.

Behavior:    For each table, the script checks if it already exists and drops
             it before recreating it. This makes the script safe to re-run
             during development, but note that existing data will be lost
             every time it executes.

Usage:       Run this script whenever the Bronze table structures need to be
             (re)initialized before loading raw data from the source systems.
================================================================================
*/

USE data_warehouse;
GO

-- ==========================================================
-- CRM SOURCE TABLES
-- ==========================================================

-- Drop and recreate crm_cust_info
-- Stores raw customer master data extracted from the CRM system
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO

CREATE TABLE bronze.crm_cust_info (
    cst_id              INT,            -- Customer ID
    cst_key             NVARCHAR(50),   -- Customer business key
    cst_firstname       NVARCHAR(50),   -- Customer first name
    cst_lastname        NVARCHAR(50),   -- Customer last name
    cst_marital_status  NVARCHAR(50),   -- Marital status
    cst_gndr            NVARCHAR(50),   -- Gender
    cst_create_date     DATE            -- Date the customer record was created
);
GO

-- Drop and recreate crm_prd_info
-- Stores raw product master data extracted from the CRM system
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info (
    prd_id          INT,            -- Product ID
    prd_key         NVARCHAR(50),   -- Product business key
    prd_nm          NVARCHAR(50),   -- Product name
    prd_cost        INT,            -- Product cost
    prd_line        NVARCHAR(50),   -- Product line/category
    prd_start_dt    DATETIME,       -- Product start date
    prd_end_dt      DATETIME        -- Product end/discontinuation date
);
GO

-- Drop and recreate crm_sales_details
-- Stores raw sales transaction details extracted from the CRM system
-- NOTE: Sales dates are stored as raw integer values (YYYYMMDD) and will
-- be converted into DATE format during the Silver layer transformations.
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num     NVARCHAR(50),   -- Sales order number
    sls_prd_key     NVARCHAR(50),   -- Product business key
    sls_cust_id     INT,            -- Customer ID
    sls_order_dt    INT,            -- Order date (raw integer format)
    sls_ship_dt     INT,            -- Ship date (raw integer format)
    sls_due_dt      INT,            -- Due date (raw integer format)
    sls_sales       INT,            -- Sales amount
    sls_quantity    INT,            -- Quantity sold
    sls_price       INT             -- Unit price
);
GO

-- ==========================================================
-- ERP SOURCE TABLES
-- ==========================================================

-- Drop and recreate erp_CUST_AZ12
-- Stores raw customer demographic data extracted from the ERP system
IF OBJECT_ID('bronze.erp_CUST_AZ12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_CUST_AZ12;
GO

CREATE TABLE bronze.erp_CUST_AZ12 (
    CID     NVARCHAR(50),   -- Customer ID
    BDATE   DATE,           -- Birth date
    GEN     NVARCHAR(50)    -- Gender
);
GO

-- Drop and recreate erp_LOC_A101
-- Stores raw customer location data extracted from the ERP system
IF OBJECT_ID('bronze.erp_LOC_A101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_LOC_A101;
GO

CREATE TABLE bronze.erp_LOC_A101 (
    CID     NVARCHAR(50),   -- Customer ID
    CNTRY   NVARCHAR(50)    -- Country
);
GO

-- Drop and recreate erp_PX_CAT_G1V2
-- Stores raw product category reference data extracted from the ERP system
IF OBJECT_ID('bronze.erp_PX_CAT_G1V2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_PX_CAT_G1V2;
GO

CREATE TABLE bronze.erp_PX_CAT_G1V2 (
    ID              NVARCHAR(50),   -- Category/product reference ID
    CAT             NVARCHAR(50),   -- Category
    SUBCAT          NVARCHAR(50),   -- Subcategory
    MAINTENANCE     NVARCHAR(50)    -- Maintenance flag/type
);
GO