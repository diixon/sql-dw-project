/*
===============================================================================
Create Database and Schemas
===============================================================================
Script Purpose:
    This script creates a new database named 'data_warehouse' after checking
    if it already exists. If the database exists, it is dropped and recreated.
    The script also sets up three schemas within the database:
        - bronze : Raw data ingestion layer (as-is from source systems)
        - silver : Cleaned, transformed, and integrated data
        - gold   : Aggregated, business-ready data for reporting

    This follows the Medallion Architecture pattern for data warehousing.

WARNING:
    Running this script will drop the entire 'data_warehouse' database if it
    already exists. All data in the database will be permanently deleted.
    Proceed with caution and ensure you have proper backups before running
    this script in a production environment.
===============================================================================
*/

USE master;
GO

-- ======================================================
-- Drop existing database if it exists
-- ======================================================
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'data_warehouse')
BEGIN
    ALTER DATABASE data_warehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE data_warehouse;
END;
GO

-- ======================================================
-- Create the 'data_warehouse' database
-- ======================================================
CREATE DATABASE data_warehouse;
GO

PRINT 'Data Warehouse database initialized successfully!';
GO

USE data_warehouse;
GO

-- ======================================================
-- Create schemas for data layering (Medallion Architecture)
-- ======================================================

-- Bronze Layer: Raw data ingestion (source systems)
CREATE SCHEMA bronze;
GO

-- Silver Layer: Cleaned, transformed, and integrated data
CREATE SCHEMA silver;
GO

-- Gold Layer: Aggregated business-ready data for reporting
CREATE SCHEMA gold;
GO

PRINT 'Schemas created: bronze, silver, gold';
PRINT 'Ready for ETL processes.';
GO

-- ======================================================
-- Database setup complete
-- ======================================================