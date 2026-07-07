/*
================================================================================
Script:      check_silver_quality.sql
Layer:       Silver
Procedure:   silver.check_silver_quality
Database:    Microsoft SQL Server (SSMS)
================================================================================
Purpose:
    Performs comprehensive data quality checks on Silver layer tables
    to validate transformation logic and identify potential data issues.
    Part of a Bronze -> Silver -> Gold medallion architecture.

Quality Checks Performed:
    CRM Tables:
    - crm_cust_info: Duplicate cst_id, untrimmed strings, invalid marital/gender codes
    - crm_prd_info: Duplicate prd_id, untrimmed strings, negative costs, 
                    invalid product lines, date logic (start > end)
    - crm_sales_details: Invalid dates, order/ship/due date logic, 
                         sales calculation mismatches, negative/null values
    
    ERP Tables:
    - erp_CUST_AZ12: Invalid gender codes, future birth dates
    - erp_LOC_A101: Unstandardized country names
    - erp_PX_CAT_G1V2: Untrimmed strings, invalid maintenance codes

Features:
    - Progress logging with timestamps for each table and overall run
    - TRY/CATCH error handling with detailed error metadata
    - Duration tracking per table, per source system, and overall
    - Clear PASS/FAIL reporting for each check
    - Summary of all issues found

Usage:
    EXEC silver.check_silver_quality;
================================================================================
*/

USE data_warehouse;
GO

CREATE OR ALTER PROCEDURE silver.check_silver_quality AS
BEGIN
    BEGIN TRY
        DECLARE @startTime    DATETIME, @endTime    DATETIME, @duration    INT;
        DECLARE @crmStart     DATETIME, @crmEnd     DATETIME, @crmDuration INT;
        DECLARE @erpStart     DATETIME, @erpEnd     DATETIME, @erpDuration INT;
        DECLARE @tblStart     DATETIME, @tblEnd     DATETIME, @tblDuration INT;
        DECLARE @issueCount   INT;
        DECLARE @totalIssues  INT = 0;

        SET @startTime = GETDATE();

        PRINT '=============================================';
        PRINT '     STARTING SILVER LAYER QUALITY CHECKS';
        PRINT '=============================================';
        PRINT 'Overall Start Time: ' + CONVERT(VARCHAR, @startTime, 120);
        PRINT '';

        -- ==========================================================
        -- CRM TABLE QUALITY CHECKS
        -- ==========================================================
        SET @crmStart = GETDATE();
        PRINT '=============================================';
        PRINT 'Starting CRM Data Quality Checks';
        PRINT '=============================================';
        PRINT 'CRM Start Time: ' + CONVERT(VARCHAR, @crmStart, 120);
        PRINT '';

        -- ----------------------------------------------
        -- silver.crm_cust_info
        -- ----------------------------------------------
        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Checking silver.crm_cust_info...';
        PRINT '';

        -- Check 1: Duplicate cst_id
        SELECT @issueCount = COUNT(*)
        FROM (
            SELECT cst_id, COUNT(*) AS dup_count
            FROM silver.crm_cust_info
            GROUP BY cst_id
            HAVING COUNT(*) > 1
        ) AS duplicates;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Duplicate cst_id found: ' + CAST(@issueCount AS VARCHAR) + ' duplicate(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] No duplicate cst_id found';

        -- Check 2: cst_id is NOT NULL (should have been filtered)
        SELECT @issueCount = COUNT(*)
        FROM silver.crm_cust_info
        WHERE cst_id IS NULL;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] NULL cst_id found: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] No NULL cst_id found';

        -- Check 3: Untrimmed cst_firstname or cst_lastname
        SELECT @issueCount = COUNT(*)
        FROM silver.crm_cust_info
        WHERE cst_firstname != TRIM(cst_firstname) 
           OR cst_lastname != TRIM(cst_lastname);

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Untrimmed name fields found: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] All name fields properly trimmed';

        -- Check 4: Invalid cst_marital_status
        SELECT @issueCount = COUNT(*)
        FROM silver.crm_cust_info
        WHERE cst_marital_status NOT IN ('Married', 'Single', 'Unknown');

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Invalid marital status values found: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] All marital status values valid';

        -- Check 5: Invalid cst_gndr
        SELECT @issueCount = COUNT(*)
        FROM silver.crm_cust_info
        WHERE cst_gndr NOT IN ('Male', 'Female', 'Unknown');

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Invalid gender values found: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] All gender values valid';

        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '';
        PRINT '>> silver.crm_cust_info checks completed! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        -- ----------------------------------------------
        -- silver.crm_prd_info
        -- ----------------------------------------------
        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Checking silver.crm_prd_info...';
        PRINT '';

        -- Check 1: Duplicate prd_id
        SELECT @issueCount = COUNT(*)
        FROM (
            SELECT prd_id, COUNT(*) AS dup_count
            FROM silver.crm_prd_info
            GROUP BY prd_id
            HAVING COUNT(*) > 1
        ) AS duplicates;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Duplicate prd_id found: ' + CAST(@issueCount AS VARCHAR) + ' duplicate(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] No duplicate prd_id found';

        -- Check 2: Untrimmed prd_nm
        SELECT @issueCount = COUNT(*)
        FROM silver.crm_prd_info
        WHERE prd_nm != TRIM(prd_nm);

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Untrimmed prd_nm found: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] All prd_nm properly trimmed';

        -- Check 3: Negative or NULL prd_cost
        SELECT @issueCount = COUNT(*)
        FROM silver.crm_prd_info
        WHERE prd_cost < 0 OR prd_cost IS NULL;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Negative or NULL prd_cost found: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] No negative or NULL prd_cost found';

        -- Check 4: Invalid prd_line
        SELECT @issueCount = COUNT(*)
        FROM silver.crm_prd_info
        WHERE prd_line NOT IN ('Road', 'Mountain', 'Sport', 'Touring', 'Unknown');

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Invalid prd_line values found: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] All prd_line values valid';

        -- Check 5: prd_start_dt > prd_end_dt
        SELECT @issueCount = COUNT(*)
        FROM silver.crm_prd_info
        WHERE prd_start_dt > prd_end_dt;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Invalid date ranges (start > end) found: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] All date ranges valid';

        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '';
        PRINT '>> silver.crm_prd_info checks completed! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        -- ----------------------------------------------
        -- silver.crm_sales_details
        -- ----------------------------------------------
        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Checking silver.crm_sales_details...';
        PRINT '';

        -- Check 1: Invalid date order (order > ship OR order > due)
        SELECT @issueCount = COUNT(*)
        FROM silver.crm_sales_details
        WHERE sls_order_dt > sls_ship_dt 
           OR sls_order_dt > sls_due_dt;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Invalid date sequences found: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] All date sequences valid';

        -- Check 2: Sales calculation mismatch
        SELECT @issueCount = COUNT(*)
        FROM silver.crm_sales_details
        WHERE sls_sales != sls_quantity * sls_price
           OR sls_sales IS NULL 
           OR sls_quantity IS NULL 
           OR sls_price IS NULL
           OR sls_sales <= 0 
           OR sls_quantity <= 0 
           OR sls_price <= 0;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Sales calculation issues found: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] All sales calculations valid';

        -- Check 3: Invalid order dates
        SELECT @issueCount = COUNT(*)
        FROM silver.crm_sales_details
        WHERE sls_order_dt IS NULL 
           OR sls_order_dt < '1900-01-01' 
           OR sls_order_dt > '2050-01-01';

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Invalid order dates found: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] All order dates valid';

        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '';
        PRINT '>> silver.crm_sales_details checks completed! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        SET @crmEnd = GETDATE();
        SET @crmDuration = DATEDIFF(SECOND, @crmStart, @crmEnd);
        PRINT '=============================================';
        PRINT 'CRM Data Quality Checks Completed!';
        PRINT 'CRM Total Duration: ' + CAST(@crmDuration AS VARCHAR) + ' seconds';
        PRINT '=============================================';
        PRINT '';

        -- ==========================================================
        -- ERP TABLE QUALITY CHECKS
        -- ==========================================================
        SET @erpStart = GETDATE();
        PRINT '=============================================';
        PRINT 'Starting ERP Data Quality Checks';
        PRINT '=============================================';
        PRINT 'ERP Start Time: ' + CONVERT(VARCHAR, @erpStart, 120);
        PRINT '';

        -- ----------------------------------------------
        -- silver.erp_CUST_AZ12
        -- ----------------------------------------------
        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Checking silver.erp_CUST_AZ12...';
        PRINT '';

        -- Check 1: Invalid GEN values
        SELECT @issueCount = COUNT(*)
        FROM silver.erp_CUST_AZ12
        WHERE GEN NOT IN ('Male', 'Female', 'Unknown');

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Invalid gender values found: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] All gender values valid';

        -- Check 2: Future birth dates
        SELECT @issueCount = COUNT(*)
        FROM silver.erp_CUST_AZ12
        WHERE BDATE > GETDATE();

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Future birth dates found: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] No future birth dates found';

        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '';
        PRINT '>> silver.erp_CUST_AZ12 checks completed! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        -- ----------------------------------------------
        -- silver.erp_LOC_A101
        -- ----------------------------------------------
        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Checking silver.erp_LOC_A101...';
        PRINT '';

        -- Check 1: Unstandardized country names (check for patterns like 'US', 'DE', etc.)
        SELECT @issueCount = COUNT(*)
        FROM silver.erp_LOC_A101
        WHERE UPPER(TRIM(CNTRY)) IN ('DE', 'GERMANY', 'USA', 'US', 'UNITED STATES')
           OR CNTRY = '' 
           OR CNTRY IS NULL;

        IF @issueCount > 0
        BEGIN
            PRINT '   [WARN] Potentially unstandardized country names found: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            PRINT '          Note: This check looks for known unstandardized patterns.';
        END
        ELSE
            PRINT '   [PASS] No known unstandardized country patterns found';

        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '';
        PRINT '>> silver.erp_LOC_A101 checks completed! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        -- ----------------------------------------------
        -- silver.erp_PX_CAT_G1V2
        -- ----------------------------------------------
        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Checking silver.erp_PX_CAT_G1V2...';
        PRINT '';

        -- Check 1: Untrimmed string fields
        SELECT @issueCount = COUNT(*)
        FROM silver.erp_PX_CAT_G1V2
        WHERE CAT != TRIM(CAT) 
           OR SUBCAT != TRIM(SUBCAT) 
           OR MAINTENANCE != TRIM(MAINTENANCE);

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Untrimmed text fields found: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] All text fields properly trimmed';

        -- Check 2: Check distinct maintenance values for anomalies
        SELECT @issueCount = COUNT(DISTINCT MAINTENANCE)
        FROM silver.erp_PX_CAT_G1V2;
        
        PRINT '   [INFO] Distinct maintenance values: ' + CAST(@issueCount AS VARCHAR);

        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '';
        PRINT '>> silver.erp_PX_CAT_G1V2 checks completed! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        SET @erpEnd = GETDATE();
        SET @erpDuration = DATEDIFF(SECOND, @erpStart, @erpEnd);
        PRINT '=============================================';
        PRINT 'ERP Data Quality Checks Completed!';
        PRINT 'ERP Total Duration: ' + CAST(@erpDuration AS VARCHAR) + ' seconds';
        PRINT '=============================================';
        PRINT '';

        -- ==========================================================
        -- OVERALL SUMMARY
        -- ==========================================================
        SET @endTime = GETDATE();
        SET @duration = DATEDIFF(SECOND, @startTime, @endTime);

        PRINT '=============================================';
        PRINT '     SILVER QUALITY CHECKS COMPLETED!';
        PRINT '=============================================';
        PRINT 'Overall Start Time: ' + CONVERT(VARCHAR, @startTime, 120);
        PRINT 'Overall End Time: ' + CONVERT(VARCHAR, @endTime, 120);
        PRINT 'CRM Total Duration: ' + CAST(@crmDuration AS VARCHAR) + ' seconds';
        PRINT 'ERP Total Duration: ' + CAST(@erpDuration AS VARCHAR) + ' seconds';
        PRINT 'Overall Total Duration: ' + CAST(@duration AS VARCHAR) + ' seconds';
        PRINT '';
        PRINT 'Total Issues Found: ' + CAST(@totalIssues AS VARCHAR);
        IF @totalIssues = 0
            PRINT 'Status: ALL CHECKS PASSED!'
        ELSE
            PRINT 'Status: ISSUES FOUND - Review the [FAIL] messages above.';
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
        PRINT '    QUALITY CHECKS FAILED!';
        PRINT '=============================================';

        THROW;
    END CATCH
END
GO

-- ==========================================================
-- SUCCESS MESSAGE
-- ==========================================================
PRINT 'Stored procedure silver.check_silver_quality created successfully!';
PRINT 'To execute: EXEC silver.check_silver_quality;';
PRINT 'This will run all data quality checks on Silver tables.';
GO

-- ==========================================================
-- Execute the stored procedure
-- ==========================================================
/*
EXEC silver.check_silver_quality;
GO
*/

-- ==========================================================
-- Individual detail queries (for deeper investigation)
-- ==========================================================
/*
-- Duplicate cst_id in crm_cust_info
SELECT cst_id, COUNT(*) AS cnt
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;

-- Untrimmed names
SELECT cst_firstname, cst_lastname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname) 
   OR cst_lastname != TRIM(cst_lastname);

-- Invalid marital status
SELECT DISTINCT cst_marital_status 
FROM silver.crm_cust_info;

-- Products with date issues
SELECT * 
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

-- Sales with calculation issues
SELECT sls_ord_num, sls_sales, sls_quantity, sls_price,
       sls_quantity * sls_price AS calculated_sales
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price;

-- Invalid gender codes in ERP
SELECT DISTINCT GEN 
FROM silver.erp_CUST_AZ12;

-- Future birth dates
SELECT BDATE 
FROM silver.erp_CUST_AZ12
WHERE BDATE > GETDATE();

-- Country values distribution
SELECT CNTRY, COUNT(*) AS cnt
FROM silver.erp_LOC_A101
GROUP BY CNTRY
ORDER BY cnt DESC;
*/