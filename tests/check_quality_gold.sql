/*
================================================================================
Script:      check_gold_quality.sql
Layer:       Gold
Procedure:   gold.check_gold_quality
Database:    Microsoft SQL Server (SSMS)
================================================================================
Purpose:
    Performs comprehensive data quality checks on Gold layer views to validate
    the dimensional model integrity. Part of a Bronze -> Silver -> Gold 
    medallion architecture.

Quality Checks Performed:
    dim_customers:
    - Surrogate key uniqueness (customer_key)
    - Primary key uniqueness (customer_id)
    - Gender value validity
    - Country data completeness
    - NULL customer critical fields
    
    dim_products:
    - Surrogate key uniqueness (product_key)
    - Primary key uniqueness (product_id)
    - Category/subcategory completeness
    - Cost validity (non-negative)
    - NULL product critical fields
    
    fact_sales:
    - Foreign key integrity (product_key → dim_products)
    - Foreign key integrity (customer_key → dim_customers)
    - Order/shipping/due date logic
    - Sales calculation consistency
    - NULL measure fields

Features:
    - Progress logging with timestamps for each view and overall run
    - TRY/CATCH error handling with detailed error metadata
    - Duration tracking per view and overall
    - Clear PASS/FAIL/WARN reporting for each check
    - Summary of all issues found
    - Referential integrity validation

Usage:
    EXEC gold.check_gold_quality;
================================================================================
*/

USE data_warehouse;
GO

CREATE OR ALTER PROCEDURE gold.check_gold_quality AS
BEGIN
    BEGIN TRY
        DECLARE @startTime    DATETIME, @endTime    DATETIME, @duration    INT;
        DECLARE @viewStart    DATETIME, @viewEnd    DATETIME, @viewDuration INT;
        DECLARE @issueCount   INT;
        DECLARE @totalIssues  INT = 0;

        SET @startTime = GETDATE();

        PRINT '=============================================';
        PRINT '     STARTING GOLD LAYER QUALITY CHECKS';
        PRINT '=============================================';
        PRINT 'Overall Start Time: ' + CONVERT(VARCHAR, @startTime, 120);
        PRINT '';

        -- ==========================================================
        -- gold.dim_customers
        -- ==========================================================
        SET @viewStart = GETDATE();
        PRINT '=============================================';
        PRINT 'Checking gold.dim_customers';
        PRINT '=============================================';
        PRINT 'Start Time: ' + CONVERT(VARCHAR, @viewStart, 120);
        PRINT '';

        -- Check 1: Surrogate key uniqueness (customer_key)
        SELECT @issueCount = COUNT(*)
        FROM (
            SELECT customer_key, COUNT(*) AS dup_count
            FROM gold.dim_customers
            GROUP BY customer_key
            HAVING COUNT(*) > 1
        ) AS duplicates;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Duplicate customer_key found: ' + CAST(@issueCount AS VARCHAR) + ' duplicate(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] Customer surrogate keys are unique';

        -- Check 2: Business key uniqueness (customer_id)
        SELECT @issueCount = COUNT(*)
        FROM (
            SELECT customer_id, COUNT(*) AS dup_count
            FROM gold.dim_customers
            GROUP BY customer_id
            HAVING COUNT(*) > 1
        ) AS duplicates;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Duplicate customer_id found: ' + CAST(@issueCount AS VARCHAR) + ' duplicate(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] Customer business keys are unique';

        -- Check 3: Gender value validity
        SELECT @issueCount = COUNT(*)
        FROM gold.dim_customers
        WHERE gender NOT IN ('Male', 'Female', 'Unknown');

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Invalid gender values found: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] All gender values are valid';

        -- Check 4: Country data completeness
        SELECT @issueCount = COUNT(*)
        FROM gold.dim_customers
        WHERE country IS NULL OR country = 'Unknown';

        IF @issueCount > 0
        BEGIN
            PRINT '   [WARN] Missing or Unknown country: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
        END
        ELSE
            PRINT '   [PASS] All customers have valid country data';

        -- Check 5: Critical NULL fields
        SELECT @issueCount = COUNT(*)
        FROM gold.dim_customers
        WHERE customer_id IS NULL 
           OR first_name IS NULL 
           OR last_name IS NULL;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] NULL critical fields (id/name): ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] No NULL critical fields';

        -- Check 6: Row count
        SELECT @issueCount = COUNT(*)
        FROM gold.dim_customers;
        PRINT '   [INFO] Total customers: ' + CAST(@issueCount AS VARCHAR);

        SET @viewEnd = GETDATE();
        SET @viewDuration = DATEDIFF(SECOND, @viewStart, @viewEnd);
        PRINT '';
        PRINT '>> gold.dim_customers checks completed! (Duration: ' + CAST(@viewDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        -- ==========================================================
        -- gold.dim_products
        -- ==========================================================
        SET @viewStart = GETDATE();
        PRINT '=============================================';
        PRINT 'Checking gold.dim_products';
        PRINT '=============================================';
        PRINT 'Start Time: ' + CONVERT(VARCHAR, @viewStart, 120);
        PRINT '';

        -- Check 1: Surrogate key uniqueness (product_key)
        SELECT @issueCount = COUNT(*)
        FROM (
            SELECT product_key, COUNT(*) AS dup_count
            FROM gold.dim_products
            GROUP BY product_key
            HAVING COUNT(*) > 1
        ) AS duplicates;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Duplicate product_key found: ' + CAST(@issueCount AS VARCHAR) + ' duplicate(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] Product surrogate keys are unique';

        -- Check 2: Business key uniqueness (product_id)
        SELECT @issueCount = COUNT(*)
        FROM (
            SELECT product_id, COUNT(*) AS dup_count
            FROM gold.dim_products
            GROUP BY product_id
            HAVING COUNT(*) > 1
        ) AS duplicates;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Duplicate product_id found: ' + CAST(@issueCount AS VARCHAR) + ' duplicate(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] Product business keys are unique';

        -- Check 3: Category/subcategory completeness
        SELECT @issueCount = COUNT(*)
        FROM gold.dim_products
        WHERE category IS NULL OR subcategory IS NULL;

        IF @issueCount > 0
        BEGIN
            PRINT '   [WARN] Missing category/subcategory: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
        END
        ELSE
            PRINT '   [PASS] All products have category/subcategory data';

        -- Check 4: Cost validity
        SELECT @issueCount = COUNT(*)
        FROM gold.dim_products
        WHERE cost < 0 OR cost IS NULL;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Negative or NULL cost: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] All product costs are valid';

        -- Check 5: Critical NULL fields
        SELECT @issueCount = COUNT(*)
        FROM gold.dim_products
        WHERE product_id IS NULL 
           OR product_name IS NULL 
           OR product_number IS NULL;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] NULL critical fields (id/name/number): ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] No NULL critical fields';

        -- Check 6: Row count
        SELECT @issueCount = COUNT(*)
        FROM gold.dim_products;
        PRINT '   [INFO] Total products: ' + CAST(@issueCount AS VARCHAR);

        SET @viewEnd = GETDATE();
        SET @viewDuration = DATEDIFF(SECOND, @viewStart, @viewEnd);
        PRINT '';
        PRINT '>> gold.dim_products checks completed! (Duration: ' + CAST(@viewDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        -- ==========================================================
        -- gold.fact_sales
        -- ==========================================================
        SET @viewStart = GETDATE();
        PRINT '=============================================';
        PRINT 'Checking gold.fact_sales';
        PRINT '=============================================';
        PRINT 'Start Time: ' + CONVERT(VARCHAR, @viewStart, 120);
        PRINT '';

        -- Check 1: Foreign key integrity - product_key
        SELECT @issueCount = COUNT(*)
        FROM gold.fact_sales f
        LEFT JOIN gold.dim_products p
            ON f.product_key = p.product_key
        WHERE p.product_key IS NULL;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Orphan product_key references: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] All product foreign keys reference existing products';

        -- Check 2: Foreign key integrity - customer_key
        SELECT @issueCount = COUNT(*)
        FROM gold.fact_sales f
        LEFT JOIN gold.dim_customers c
            ON f.customer_key = c.customer_key
        WHERE c.customer_key IS NULL;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Orphan customer_key references: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] All customer foreign keys reference existing customers';

        -- Check 3: Date logic - order vs shipping
        SELECT @issueCount = COUNT(*)
        FROM gold.fact_sales
        WHERE order_date > shipping_date;

        IF @issueCount > 0
        BEGIN
            PRINT '   [WARN] Order date after shipping date: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
        END
        ELSE
            PRINT '   [PASS] All order dates are before or equal to shipping dates';

        -- Check 4: Date logic - order vs due
        SELECT @issueCount = COUNT(*)
        FROM gold.fact_sales
        WHERE order_date > due_date;

        IF @issueCount > 0
        BEGIN
            PRINT '   [WARN] Order date after due date: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
        END
        ELSE
            PRINT '   [PASS] All order dates are before or equal to due dates';

        -- Check 5: Sales calculation consistency
        SELECT @issueCount = COUNT(*)
        FROM gold.fact_sales
        WHERE sales_amount != quantity * price
           OR sales_amount IS NULL 
           OR quantity IS NULL 
           OR price IS NULL
           OR sales_amount <= 0 
           OR quantity <= 0 
           OR price <= 0;

        IF @issueCount > 0
        BEGIN
            PRINT '   [FAIL] Sales calculation issues: ' + CAST(@issueCount AS VARCHAR) + ' row(s)';
            SET @totalIssues = @totalIssues + @issueCount;
        END
        ELSE
            PRINT '   [PASS] All sales calculations are consistent';

        -- Check 6: Row count
        SELECT @issueCount = COUNT(*)
        FROM gold.fact_sales;
        PRINT '   [INFO] Total sales transactions: ' + CAST(@issueCount AS VARCHAR);

        SET @viewEnd = GETDATE();
        SET @viewDuration = DATEDIFF(SECOND, @viewStart, @viewEnd);
        PRINT '';
        PRINT '>> gold.fact_sales checks completed! (Duration: ' + CAST(@viewDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        -- ==========================================================
        -- OVERALL SUMMARY
        -- ==========================================================
        SET @endTime = GETDATE();
        SET @duration = DATEDIFF(SECOND, @startTime, @endTime);

        PRINT '=============================================';
        PRINT '     GOLD QUALITY CHECKS COMPLETED!';
        PRINT '=============================================';
        PRINT 'Overall Start Time: ' + CONVERT(VARCHAR, @startTime, 120);
        PRINT 'Overall End Time: ' + CONVERT(VARCHAR, @endTime, 120);
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
        PRINT '    GOLD QUALITY CHECKS FAILED!';
        PRINT '=============================================';

        THROW;
    END CATCH
END
GO

-- ==========================================================
-- SUCCESS MESSAGE
-- ==========================================================
PRINT 'Stored procedure gold.check_gold_quality created successfully!';
PRINT 'To execute: EXEC gold.check_gold_quality;';
PRINT 'This will run all data quality checks on Gold layer views.';
GO

-- ==========================================================
-- Execute the stored procedure
-- ==========================================================
/*
EXEC gold.check_gold_quality;
GO
*/

-- ==========================================================
-- Individual detail queries (for deeper investigation)
-- ==========================================================
/*
-- Duplicate surrogate keys in dimensions
SELECT customer_key, COUNT(*) AS cnt
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

SELECT product_key, COUNT(*) AS cnt
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- Gender distribution
SELECT gender, COUNT(*) AS cnt
FROM gold.dim_customers
GROUP BY gender
ORDER BY cnt DESC;

-- Category hierarchy
SELECT category, subcategory, COUNT(*) AS product_count
FROM gold.dim_products
GROUP BY category, subcategory
ORDER BY category, subcategory;

-- Sales by product (top 10)
SELECT TOP 10
    p.product_name,
    COUNT(*) AS transaction_count,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.quantity) AS total_quantity
FROM gold.fact_sales f
JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_sales DESC;

-- Sales by country
SELECT 
    c.country,
    COUNT(*) AS transaction_count,
    SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales f
JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_sales DESC;
*/