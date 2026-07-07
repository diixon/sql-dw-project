/*
================================================================================
Script:      load_silver.sql
Layer:       Silver
Procedure:   silver.load_silver
Database:    Microsoft SQL Server (SSMS)
================================================================================
Purpose:
    Transforms and loads data from Bronze layer tables into Silver layer tables.
    Part of a Bronze -> Silver -> Gold medallion architecture.
    Applies data cleansing, standardization, and deduplication.

Source Tables (Bronze):
    CRM: crm_cust_info, crm_prd_info, crm_sales_details
    ERP: erp_CUST_AZ12, erp_LOC_A101, erp_PX_CAT_G1V2

Transformations Applied:
    - String trimming and case standardization
    - Code-to-description mapping (e.g., 'M' -> 'Married', 'R' -> 'Road')
    - Data type casting and date validation
    - Deduplication using ROW_NUMBER()
    - Derived column calculations (prd_end_dt from LEAD function)
    - Business rule validations (sales = quantity * price)
    - NULL handling and default value assignment
    - ID cleansing (removing prefixes/suffixes)

Features:
    - TRUNCATE before load, ensuring each run starts from a clean table
    - Progress logging with timestamps for each table, source system, and
      the overall run
    - TRY/CATCH error handling with detailed error metadata on failure
    - Duration tracking per table, per source system, and overall

Dependencies:
    - bronze.load_bronze must be executed first
    - Bronze tables must contain data
    - Function dbo.fn_ProperCase must exist (for erp_LOC_A101 country formatting)

Usage:
    EXEC silver.load_silver;
================================================================================
*/

USE data_warehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    BEGIN TRY
        DECLARE @startTime    DATETIME, @endTime    DATETIME, @duration    INT;
        DECLARE @crmStart     DATETIME, @crmEnd     DATETIME, @crmDuration INT;
        DECLARE @erpStart     DATETIME, @erpEnd     DATETIME, @erpDuration INT;
        DECLARE @tblStart     DATETIME, @tblEnd     DATETIME, @tblDuration INT;

        SET @startTime = GETDATE();

        PRINT '=============================================';
        PRINT '          STARTING SILVER LAYER LOAD';
        PRINT '=============================================';
        PRINT 'Overall Start Time: ' + CONVERT(VARCHAR, @startTime, 120);
        PRINT '';

        -- ==========================================================
        -- CRM SOURCE TABLES
        -- ==========================================================
        SET @crmStart = GETDATE();
        PRINT '=============================================';
        PRINT 'Starting CRM Data Transformation & Load';
        PRINT '=============================================';
        PRINT 'CRM Start Time: ' + CONVERT(VARCHAR, @crmStart, 120);
        PRINT '';

        -- ----------------------------------------------
        -- silver.crm_cust_info
        -- ----------------------------------------------
        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Loading silver.crm_cust_info...';
        PRINT '>> Truncating table...';
        TRUNCATE TABLE silver.crm_cust_info;
        PRINT '>> Transforming and inserting data...';
        
        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT 
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,
            CASE 
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                ELSE 'Unknown'
            END AS cst_marital_status,
            CASE 
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                ELSE 'Unknown'
            END AS cst_gndr,
            cst_create_date
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id 
                    ORDER BY cst_create_date DESC
                ) AS RowNum
            FROM bronze.crm_cust_info
        ) AS t
        WHERE RowNum = 1 
          AND cst_id IS NOT NULL;

        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '>> silver.crm_cust_info loaded successfully! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        -- ----------------------------------------------
        -- silver.crm_prd_info
        -- ----------------------------------------------
        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Loading silver.crm_prd_info...';
        PRINT '>> Truncating table...';
        TRUNCATE TABLE silver.crm_prd_info;
        PRINT '>> Transforming and inserting data...';

        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT 
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE 
                WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
                WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
                WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Sport'
                WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
                ELSE 'Unknown'
            END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(
                LEAD(prd_start_dt) OVER (
                    PARTITION BY prd_key 
                    ORDER BY prd_start_dt
                ) - 1 AS DATE
            ) AS prd_end_dt
        FROM bronze.crm_prd_info;

        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '>> silver.crm_prd_info loaded successfully! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        -- ----------------------------------------------
        -- silver.crm_sales_details
        -- ----------------------------------------------
        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Loading silver.crm_sales_details...';
        PRINT '>> Truncating table...';
        TRUNCATE TABLE silver.crm_sales_details;
        PRINT '>> Transforming and inserting data...';

        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT 
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE 
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,
            CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) AS sls_ship_dt,
            CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) AS sls_due_dt,
            CASE 
                WHEN sls_sales IS NULL 
                  OR sls_sales <= 0
                  OR sls_sales != sls_quantity * sls_price
                THEN ABS(sls_quantity) * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,
            sls_quantity,
            CASE 
                WHEN sls_price < 1 OR sls_price IS NULL
                THEN sls_sales / NULLIF(ABS(sls_quantity), 0)
                ELSE sls_price
            END AS sls_price
        FROM bronze.crm_sales_details;

        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '>> silver.crm_sales_details loaded successfully! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        SET @crmEnd = GETDATE();
        SET @crmDuration = DATEDIFF(SECOND, @crmStart, @crmEnd);
        PRINT '=============================================';
        PRINT 'CRM Data Transformation & Load Completed!';
        PRINT 'CRM Total Duration: ' + CAST(@crmDuration AS VARCHAR) + ' seconds';
        PRINT '=============================================';
        PRINT '';

        -- ==========================================================
        -- ERP SOURCE TABLES
        -- ==========================================================
        SET @erpStart = GETDATE();
        PRINT '=============================================';
        PRINT 'Starting ERP Data Transformation & Load';
        PRINT '=============================================';
        PRINT 'ERP Start Time: ' + CONVERT(VARCHAR, @erpStart, 120);
        PRINT '';

        -- ----------------------------------------------
        -- silver.erp_CUST_AZ12
        -- ----------------------------------------------
        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Loading silver.erp_CUST_AZ12...';
        PRINT '>> Truncating table...';
        TRUNCATE TABLE silver.erp_CUST_AZ12;
        PRINT '>> Transforming and inserting data...';

        INSERT INTO silver.erp_CUST_AZ12 (
            CID,
            BDATE,
            GEN
        )
        SELECT 
            CASE 
                WHEN UPPER(TRIM(CID)) LIKE 'NA%' THEN SUBSTRING(CID, 4, LEN(CID))
                ELSE CID
            END AS CID,
            CASE 
                WHEN BDATE > GETDATE() THEN NULL
                ELSE BDATE
            END AS BDATE,
            CASE 
                WHEN UPPER(TRIM(GEN)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(GEN)) IN ('M', 'MALE') THEN 'Male'
                ELSE 'Unknown'
            END AS GEN
        FROM bronze.erp_CUST_AZ12;

        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '>> silver.erp_CUST_AZ12 loaded successfully! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        -- ----------------------------------------------
        -- silver.erp_LOC_A101
        -- ----------------------------------------------
        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Loading silver.erp_LOC_A101...';
        PRINT '>> Truncating table...';
        TRUNCATE TABLE silver.erp_LOC_A101;
        PRINT '>> Transforming and inserting data...';

        INSERT INTO silver.erp_LOC_A101 (
            CID,
            CNTRY
        )
        SELECT 
            REPLACE(CID, '-', '') AS CID,
            CASE 
                WHEN UPPER(TRIM(CNTRY)) IN ('DE', 'GERMANY') THEN 'Germany'
                WHEN UPPER(TRIM(CNTRY)) IN ('USA', 'US', 'UNITED STATES') THEN 'United States'
                WHEN CNTRY = '' OR CNTRY IS NULL THEN 'Unknown'
                ELSE dbo.fn_ProperCase(TRIM(CNTRY))
            END AS CNTRY
        FROM bronze.erp_LOC_A101;

        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '>> silver.erp_LOC_A101 loaded successfully! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        -- ----------------------------------------------
        -- silver.erp_PX_CAT_G1V2
        -- ----------------------------------------------
        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Loading silver.erp_PX_CAT_G1V2...';
        PRINT '>> Truncating table...';
        TRUNCATE TABLE silver.erp_PX_CAT_G1V2;
        PRINT '>> Inserting data (direct load, no transformations)...';

        INSERT INTO silver.erp_PX_CAT_G1V2 (
            ID,
            CAT,
            SUBCAT,
            MAINTENANCE
        )
        SELECT 
            ID,
            CAT,
            SUBCAT,
            MAINTENANCE
        FROM bronze.erp_PX_CAT_G1V2;

        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '>> silver.erp_PX_CAT_G1V2 loaded successfully! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        SET @erpEnd = GETDATE();
        SET @erpDuration = DATEDIFF(SECOND, @erpStart, @erpEnd);
        PRINT '=============================================';
        PRINT 'ERP Data Transformation & Load Completed!';
        PRINT 'ERP Total Duration: ' + CAST(@erpDuration AS VARCHAR) + ' seconds';
        PRINT '=============================================';
        PRINT '';

        -- ==========================================================
        -- OVERALL SUMMARY
        -- ==========================================================
        SET @endTime = GETDATE();
        SET @duration = DATEDIFF(SECOND, @startTime, @endTime);

        PRINT '=============================================';
        PRINT '     ALL SILVER TABLES LOADED SUCCESSFULLY!';
        PRINT '=============================================';
        PRINT 'Overall Start Time: ' + CONVERT(VARCHAR, @startTime, 120);
        PRINT 'Overall End Time: ' + CONVERT(VARCHAR, @endTime, 120);
        PRINT 'CRM Total Duration: ' + CAST(@crmDuration AS VARCHAR) + ' seconds';
        PRINT 'ERP Total Duration: ' + CAST(@erpDuration AS VARCHAR) + ' seconds';
        PRINT 'Overall Total Duration: ' + CAST(@duration AS VARCHAR) + ' seconds';
        PRINT '=============================================';
    END TRY
    BEGIN CATCH
        SET @endTime = GETDATE();
        SET @duration = DATEDIFF(SECOND, @startTime, @endTime);

        PRINT '=============================================';
        PRINT '           ERROR OCCURRED!';
        PRINT '=============================================';
        PRINT '';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR);
        PRINT 'Error Procedure: ' + ERROR_PROCEDURE();
        PRINT '';
        PRINT 'Overall Start Time: ' + CONVERT(VARCHAR, @startTime, 120);
        PRINT 'Time Until Error: ' + CAST(@duration AS VARCHAR) + ' seconds';
        PRINT '';
        PRINT '=============================================';
        PRINT '    SILVER LAYER LOAD FAILED!';
        PRINT '=============================================';

        THROW;
    END CATCH
END
GO

-- ==========================================================
-- SUCCESS MESSAGE
-- ==========================================================
PRINT 'Stored procedure silver.load_silver created successfully!';
PRINT 'To execute: EXEC silver.load_silver;';
PRINT 'This will transform and load all Bronze data into Silver tables.';
PRINT 'NOTE: Ensure bronze.load_bronze has been run first.';
GO

-- ==========================================================
-- Execute the stored procedure
-- ==========================================================
/*
EXEC silver.load_silver;
GO
*/

-- ==========================================================
-- Check row counts after loading
-- ==========================================================
/*
SELECT 'silver.crm_cust_info'      AS TableName, COUNT(*) AS RowCount FROM silver.crm_cust_info      UNION ALL
SELECT 'silver.crm_prd_info',                    COUNT(*)             FROM silver.crm_prd_info       UNION ALL
SELECT 'silver.crm_sales_details',               COUNT(*)             FROM silver.crm_sales_details  UNION ALL
SELECT 'silver.erp_CUST_AZ12',                   COUNT(*)             FROM silver.erp_CUST_AZ12      UNION ALL
SELECT 'silver.erp_LOC_A101',                    COUNT(*)             FROM silver.erp_LOC_A101       UNION ALL
SELECT 'silver.erp_PX_CAT_G1V2',                 COUNT(*)             FROM silver.erp_PX_CAT_G1V2;
*/