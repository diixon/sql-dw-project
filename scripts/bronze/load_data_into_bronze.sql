/*
================================================================================
Script:      load_bronze.sql
Layer:       Bronze
Procedure:   bronze.load_bronze
Database:    Microsoft SQL Server (SSMS)
================================================================================
Purpose:
    Loads raw data from source CSV files into the Bronze layer tables using
    BULK INSERT. Part of a Bronze -> Silver -> Gold medallion architecture.

Source Files:
    CRM : cust_info.csv, prd_info.csv, sales_details.csv
    ERP : CUST_AZ12.csv, LOC_A101.csv, PX_CAT_G1V2.csv

Features:
    - TRUNCATE before load, ensuring each run starts from a clean table
    - Progress logging with timestamps for each table, source system, and
      the overall run
    - TRY/CATCH error handling with detailed error metadata on failure
    - Duration tracking per table, per source system, and overall

IMPORTANT - Before running:
    The file paths below (D:\STUDy\...) are local development paths and must
    be updated to match the file locations on the target machine before this
    procedure will run successfully. BULK INSERT requires a path accessible
    to the SQL Server service account, not just the client running SSMS.

Usage:
    EXEC bronze.load_bronze;
================================================================================
*/

USE data_warehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    BEGIN TRY
        DECLARE @startTime    DATETIME, @endTime    DATETIME, @duration    INT;
        DECLARE @crmStart     DATETIME, @crmEnd     DATETIME, @crmDuration INT;
        DECLARE @erpStart     DATETIME, @erpEnd     DATETIME, @erpDuration INT;
        DECLARE @tblStart     DATETIME, @tblEnd     DATETIME, @tblDuration INT;

        SET @startTime = GETDATE();

        PRINT '=============================================';
        PRINT '          STARTING BRONZE LAYER LOAD';
        PRINT '=============================================';
        PRINT 'Overall Start Time: ' + CONVERT(VARCHAR, @startTime, 120);
        PRINT '';

        -- ==========================================================
        -- CRM SOURCE FILES
        -- ==========================================================
        SET @crmStart = GETDATE();
        PRINT '=============================================';
        PRINT 'Starting CRM Data Load';
        PRINT '=============================================';
        PRINT 'CRM Start Time: ' + CONVERT(VARCHAR, @crmStart, 120);
        PRINT '';

        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Loading crm_cust_info...';
        PRINT '>> Truncating table...';
        TRUNCATE TABLE bronze.crm_cust_info;
        PRINT '>> Bulk inserting data...';
        BULK INSERT bronze.crm_cust_info
        FROM 'D:\STUDy\Data-With-baraa-SQLProject\MY-try\datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '>> crm_cust_info loaded successfully! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Loading crm_prd_info...';
        PRINT '>> Truncating table...';
        TRUNCATE TABLE bronze.crm_prd_info;
        PRINT '>> Bulk inserting data...';
        BULK INSERT bronze.crm_prd_info
        FROM 'D:\STUDy\Data-With-baraa-SQLProject\MY-try\datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '>> crm_prd_info loaded successfully! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Loading crm_sales_details...';
        PRINT '>> Truncating table...';
        TRUNCATE TABLE bronze.crm_sales_details;
        PRINT '>> Bulk inserting data...';
        BULK INSERT bronze.crm_sales_details
        FROM 'D:\STUDy\Data-With-baraa-SQLProject\MY-try\datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '>> crm_sales_details loaded successfully! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        SET @crmEnd = GETDATE();
        SET @crmDuration = DATEDIFF(SECOND, @crmStart, @crmEnd);
        PRINT '=============================================';
        PRINT 'CRM Data Load Completed!';
        PRINT 'CRM Total Duration: ' + CAST(@crmDuration AS VARCHAR) + ' seconds';
        PRINT '=============================================';
        PRINT '';

        -- ==========================================================
        -- ERP SOURCE FILES
        -- ==========================================================
        SET @erpStart = GETDATE();
        PRINT '=============================================';
        PRINT 'Starting ERP Data Load';
        PRINT '=============================================';
        PRINT 'ERP Start Time: ' + CONVERT(VARCHAR, @erpStart, 120);
        PRINT '';

        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Loading erp_CUST_AZ12...';
        PRINT '>> Truncating table...';
        TRUNCATE TABLE bronze.erp_CUST_AZ12;
        PRINT '>> Bulk inserting data...';
        BULK INSERT bronze.erp_CUST_AZ12
        FROM 'D:\STUDy\Data-With-baraa-SQLProject\MY-try\datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '>> erp_CUST_AZ12 loaded successfully! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Loading erp_LOC_A101...';
        PRINT '>> Truncating table...';
        TRUNCATE TABLE bronze.erp_LOC_A101;
        PRINT '>> Bulk inserting data...';
        BULK INSERT bronze.erp_LOC_A101
        FROM 'D:\STUDy\Data-With-baraa-SQLProject\MY-try\datasets\source_erp\LOC_A101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '>> erp_LOC_A101 loaded successfully! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        SET @tblStart = GETDATE();
        PRINT '---------------------------------------------';
        PRINT '>> Loading erp_PX_CAT_G1V2...';
        PRINT '>> Truncating table...';
        TRUNCATE TABLE bronze.erp_PX_CAT_G1V2;
        PRINT '>> Bulk inserting data...';
        BULK INSERT bronze.erp_PX_CAT_G1V2
        FROM 'D:\STUDy\Data-With-baraa-SQLProject\MY-try\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @tblEnd = GETDATE();
        SET @tblDuration = DATEDIFF(SECOND, @tblStart, @tblEnd);
        PRINT '>> erp_PX_CAT_G1V2 loaded successfully! (Duration: ' + CAST(@tblDuration AS VARCHAR) + ' seconds)';
        PRINT '';

        SET @erpEnd = GETDATE();
        SET @erpDuration = DATEDIFF(SECOND, @erpStart, @erpEnd);
        PRINT '=============================================';
        PRINT 'ERP Data Load Completed!';
        PRINT 'ERP Total Duration: ' + CAST(@erpDuration AS VARCHAR) + ' seconds';
        PRINT '=============================================';
        PRINT '';

        -- ==========================================================
        -- OVERALL SUMMARY
        -- ==========================================================
        SET @endTime = GETDATE();
        SET @duration = DATEDIFF(SECOND, @startTime, @endTime);

        PRINT '=============================================';
        PRINT '     ALL BRONZE TABLES LOADED SUCCESSFULLY!';
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
        PRINT '    BRONZE LAYER LOAD FAILED!';
        PRINT '=============================================';

        THROW;
    END CATCH
END
GO

-- ==========================================================
-- SUCCESS MESSAGE
-- ==========================================================
PRINT 'Stored procedure bronze.load_bronze created successfully!';
PRINT 'To execute: EXEC bronze.load_bronze;';
PRINT 'This will load all CSV data into Bronze tables.';
GO

-- ==========================================================
-- Execute the stored procedure
-- ==========================================================
/*
EXEC bronze.load_bronze;
GO
*/

-- ==========================================================
-- Check row counts after loading
-- ==========================================================
/*
SELECT 'bronze.crm_cust_info'     AS TableName, COUNT(*) AS RowCount FROM bronze.crm_cust_info     UNION ALL
SELECT 'bronze.crm_prd_info',                   COUNT(*)             FROM bronze.crm_prd_info      UNION ALL
SELECT 'bronze.crm_sales_details',              COUNT(*)             FROM bronze.crm_sales_details UNION ALL
SELECT 'bronze.erp_CUST_AZ12',                  COUNT(*)             FROM bronze.erp_CUST_AZ12      UNION ALL
SELECT 'bronze.erp_LOC_A101',                   COUNT(*)             FROM bronze.erp_LOC_A101       UNION ALL
SELECT 'bronze.erp_PX_CAT_G1V2',                COUNT(*)             FROM bronze.erp_PX_CAT_G1V2;
*/